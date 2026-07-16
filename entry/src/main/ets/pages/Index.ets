import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { bookParser, readerCore } from '@kit.ReaderKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { ReaderConstants } from '../common/ReaderConstants';
import { SampleBookProvider } from '../utils/SampleBookProvider';
import { BackgroundOption, BACKGROUND_OPTIONS, FontOption, FONT_OPTIONS } from '../model/ReaderOptions';
import { TopBar } from '../components/TopBar';
import { SidebarPanel } from '../components/SidebarPanel';
import { NavigationBar } from '../components/NavigationBar';
import { ReaderStage } from '../components/ReaderStage';

const DOMAIN = 0x0000;
const TAG = 'ReaderShowcase';

@Entry
@Component
struct Index {
  private readerComponentController: readerCore.ReaderComponentController = new readerCore.ReaderComponentController();
  private bookParserHandler: bookParser.BookParserHandler | null = null;
  private readerSetting: readerCore.ReaderSetting = ReaderConstants.getDefaultReaderSetting();

  private isControllerReady: boolean = false;
  private isBookOpened: boolean = false;
  private isOpeningBook: boolean = false;
  private hasViewport: boolean = false;
  private currentResourceIndex: number = 0;
  private currentDomPos: string = '';

  @State isLoading: boolean = true;
  @State isSidebarCollapsed: boolean = false;
  @State statusMessage: string = '';
  @State bookTitle: string = '';
  @State bookAuthor: string = '';
  @State bookCover: image.PixelMap | null = null;
  @State catalogItemList: bookParser.CatalogItem[] = [];
  @State selectedFontIndex: number = 0;
  @State selectedBackgroundIndex: number = 0;
  @State fontSize: number = 18;
  @State lineHeight: number = 1.9;
  @State flipMode: string = '0';
  @State nightMode: boolean = false;
  @State scaledDensity: number = 1;

  @StorageLink('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

  private screenDensityCallback: Callback<number> = (): void => {
    const latest = display.getDefaultDisplaySync().scaledDensity;
    if (latest > 0 && latest !== this.readerSetting.scaledDensity) {
      this.readerSetting.scaledDensity = latest;
      this.scaledDensity = latest;
      if (this.isBookOpened) {
        this.readerComponentController.setPageConfig(this.readerSetting);
        this.readerComponentController.startPlay(this.currentResourceIndex, this.currentDomPos)
          .catch((error: BusinessError) => {
            hilog.error(DOMAIN, TAG, `re-layout after density change failed, code: ${error.code}`);
          });
      }
    }
  };

  private resourceRequest: bookParser.CallbackRes<string, ArrayBuffer> = (filePath: string): ArrayBuffer => {
    if (filePath.length === 0) {
      return new ArrayBuffer(0);
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const value: Uint8Array = context.resourceManager.getRawFileContentSync(filePath);
      return value.buffer as ArrayBuffer;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, `resourceRequest rawfile lookup failed for ${filePath}, code: ${err.code}`);
    }
    return this.loadFileFromSandbox(filePath);
  };

  aboutToAppear(): void {
    this.scaledDensity = this.readerSetting.scaledDensity;
    display.on('change', this.screenDensityCallback);
  }

  aboutToDisappear(): void {
    display.off('change', this.screenDensityCallback);
    if (this.isControllerReady) {
      this.readerComponentController.off('pageShow');
      this.readerComponentController.off('resourceRequest');
    }
    if (this.isBookOpened) {
      this.readerComponentController.releaseBook();
    }
  }

  private onColorModeChange(): void {
    if (!this.isBookOpened) {
      return;
    }
    if (this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      this.applyBackgroundOption(2);
    } else if (this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      this.applyBackgroundOption(0);
    }
  }

  private registerListeners(): void {
    this.readerComponentController.on('pageShow', (data: readerCore.PageDataInfo): void => {
      if (data.state === readerCore.PageState.PAGE_ON_SHOW) {
        this.isLoading = false;
      }
      this.currentResourceIndex = data.resourceIndex;
      this.currentDomPos = data.startDomPos;
    });
    this.readerComponentController.on('resourceRequest', this.resourceRequest);
  }

  private handleAreaChange(newValue: Area): void {
    const vpWidth = Number(newValue.width);
    const vpHeight = Number(newValue.height);
    if (vpWidth <= 0 || vpHeight <= 0) {
      return;
    }
    const pxWidth = Math.round(vp2px(vpWidth));
    const pxHeight = Math.round(vp2px(vpHeight));
    const changed = pxWidth !== this.readerSetting.viewPortWidth || pxHeight !== this.readerSetting.viewPortHeight;
    this.readerSetting.viewPortWidth = pxWidth;
    this.readerSetting.viewPortHeight = pxHeight;
    this.hasViewport = true;
    if (this.isBookOpened && changed) {
      this.readerComponentController.setPageConfig(this.readerSetting);
    } else {
      this.maybeOpenBook();
    }
  }

  private maybeOpenBook(): void {
    if (this.isControllerReady && this.hasViewport && !this.isBookOpened && !this.isOpeningBook) {
      this.isOpeningBook = true;
      this.openBook();
    }
  }

  private async openBook(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const filePath = await SampleBookProvider.ensureSampleBook(context);
      const initPromise: Promise<void> = this.readerComponentController.init(context);
      const handlerPromise: Promise<bookParser.BookParserHandler> = bookParser.getDefaultHandler(filePath);
      const result: [bookParser.BookParserHandler, void] = await Promise.all([handlerPromise, initPromise]);
      const handler = result[0];
      this.bookParserHandler = handler;
      this.applyBookInfo(handler);
      this.readerComponentController.setPageConfig(this.readerSetting);
      this.readerComponentController.registerBookParser(handler);
      await this.readerComponentController.startPlay(this.currentResourceIndex, this.currentDomPos);
      this.isBookOpened = true;
      this.statusMessage = '';
    } catch (error) {
      const err = error as BusinessError;
      this.statusMessage = `Failed to open the sample book (code ${err.code}).`;
      hilog.error(DOMAIN, TAG, `openBook failed, code: ${err.code}, message: ${err.message}`);
    } finally {
      this.isOpeningBook = false;
    }
  }

  private applyBookInfo(handler: bookParser.BookParserHandler): void {
    try {
      const bookInfo = handler.getBookInfo();
      if (bookInfo) {
        this.bookTitle = bookInfo.bookTitle || 'Sample Book';
        this.bookAuthor = bookInfo.bookCreator || 'Reader Kit';
        if (bookInfo.bookCoverImage) {
          this.loadCover(handler, bookInfo.bookCoverImage);
        }
      }
      this.catalogItemList = handler.getCatalogList() || [];
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `applyBookInfo failed, code: ${err.code}, message: ${err.message}`);
    }
  }

  private async loadCover(handler: bookParser.BookParserHandler, coverPath: string): Promise<void> {
    try {
      const buffer = handler.getResourceContent(-1, coverPath);
      const imageSource: image.ImageSource = image.createImageSource(buffer);
      this.bookCover = await imageSource.createPixelMap();
      imageSource.release();
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, `loadCover failed, code: ${err.code}, message: ${err.message}`);
    }
  }

  private loadFileFromSandbox(filePath: string): ArrayBuffer {
    try {
      const stats = fs.statSync(filePath);
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(stats.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      return buffer;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `loadFileFromSandbox failed for ${filePath}, code: ${err.code}, message: ${err.message}`);
      return new ArrayBuffer(0);
    }
  }

  private jumpToCatalogItem(item: bookParser.CatalogItem): void {
    if (!this.bookParserHandler || !this.isBookOpened) {
      return;
    }
    try {
      const domPos = this.bookParserHandler.getDomPosByCatalogHref(item.href || '') || '';
      const spineList = this.bookParserHandler.getSpineList() || [];
      const match = spineList.find(spine => spine.href === item.resourceFile);
      const spineIndex = match ? match.index : 0;
      this.readerComponentController.startPlay(spineIndex, domPos).catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, `jumpToCatalogItem startPlay failed, code: ${error.code}`);
      });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `jumpToCatalogItem failed, code: ${err.code}, message: ${err.message}`);
    }
  }

  private applySettings(): void {
    if (this.isBookOpened) {
      this.readerComponentController.setPageConfig(this.readerSetting);
    }
  }

  private applyFontOption(index: number): void {
    const option: FontOption = FONT_OPTIONS[index];
    this.selectedFontIndex = index;
    this.readerSetting.fontName = option.fontName;
    this.readerSetting.fontPath = option.fontPath;
    this.applySettings();
  }

  private applyBackgroundOption(index: number): void {
    const option: BackgroundOption = BACKGROUND_OPTIONS[index];
    this.selectedBackgroundIndex = index;
    this.readerSetting.themeColor = option.themeColor;
    this.readerSetting.fontColor = option.fontColor;
    this.readerSetting.themeBgImg = option.themeBgImg;
    this.readerSetting.nightMode = option.nightMode;
    this.nightMode = option.nightMode;
    this.applySettings();
  }

  private applyFontSize(value: number): void {
    const clamped = Math.min(ReaderConstants.MAX_FONT_SIZE, Math.max(ReaderConstants.MIN_FONT_SIZE, Math.round(value)));
    this.fontSize = clamped;
    this.readerSetting.fontSize = clamped;
    this.applySettings();
  }

  private applyLineHeight(value: number): void {
    const clamped = Math.min(ReaderConstants.MAX_LINE_HEIGHT, Math.max(ReaderConstants.MIN_LINE_HEIGHT, value));
    this.lineHeight = clamped;
    this.readerSetting.lineHeight = clamped;
    this.applySettings();
  }

  private applyFlipMode(mode: string): void {
    this.flipMode = mode;
    this.readerSetting.flipMode = mode;
    this.applySettings();
  }

  private toggleNightMode(isOn: boolean): void {
    this.applyBackgroundOption(isOn ? 2 : 0);
  }

  private toggleSidebar(): void {
    this.isSidebarCollapsed = !this.isSidebarCollapsed;
  }

  private turnPage(isNext: boolean): void {
    if (this.isBookOpened) {
      this.readerComponentController.flipPage(isNext);
    }
  }

  build() {
    Column() {
      TopBar({
        isSidebarCollapsed: this.isSidebarCollapsed,
        bookTitle: this.bookTitle,
        bookAuthor: this.bookAuthor,
        statusMessage: this.statusMessage,
        onToggleSidebar: (): void => this.toggleSidebar()
      })
      Row() {
        if (!this.isSidebarCollapsed) {
          SidebarPanel({
            bookTitle: this.bookTitle,
            bookAuthor: this.bookAuthor,
            bookCover: this.bookCover,
            catalogItemList: this.catalogItemList,
            selectedFontIndex: this.selectedFontIndex,
            selectedBackgroundIndex: this.selectedBackgroundIndex,
            fontSize: this.fontSize,
            lineHeight: this.lineHeight,
            flipMode: this.flipMode,
            nightMode: this.nightMode,
            scaledDensity: this.scaledDensity,
            onSelectCatalogItem: (item: bookParser.CatalogItem): void => this.jumpToCatalogItem(item),
            onSelectFont: (index: number): void => this.applyFontOption(index),
            onSelectBackground: (index: number): void => this.applyBackgroundOption(index),
            onFontSizeChange: (value: number): void => this.applyFontSize(value),
            onLineHeightChange: (value: number): void => this.applyLineHeight(value),
            onSelectFlipMode: (mode: string): void => this.applyFlipMode(mode),
            onToggleNightMode: (isOn: boolean): void => this.toggleNightMode(isOn)
          })
          Divider().vertical(true).strokeWidth(1).color(ReaderConstants.COLOR_DIVIDER)
        }
        Column() {
          ReaderStage({
            controller: this.readerComponentController,
            isLoading: this.isLoading,
            readerCallback: (err: BusinessError, data: readerCore.ReaderComponentController): void => {
              if (err) {
                this.statusMessage = `Reader initialization failed: ${err.message}`;
                hilog.error(DOMAIN, TAG, `readerCallback error, code: ${err.code}, message: ${err.message}`);
                return;
              }
              this.readerComponentController = data;
              this.isControllerReady = true;
              this.registerListeners();
              this.maybeOpenBook();
            },
            onStageAreaChange: (area: Area): void => this.handleAreaChange(area)
          })
          NavigationBar({
            flipMode: this.flipMode,
            onTurnPage: (isNext: boolean): void => this.turnPage(isNext)
          })
        }
        .layoutWeight(1)
        .height('100%')
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
