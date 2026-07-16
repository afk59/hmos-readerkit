# How to Use Reader Kit — A Complete CodeLab

Reader Kit is HarmonyOS's eBook parsing, typesetting, and reading-interaction toolkit. It gives you two building blocks: **BookParser**, an engine that extracts metadata and content from TXT/EPUB/MOBI/AZW/AZW3 files, and **ReadPageComponent**, a GPU-accelerated (OpenGL) component that paginates and renders that content with tap/swipe page-turning.

This guide takes you from opening a local book file to a fully customized, production-ready reading page.

## Before You Start

- **Devices**: phones, PCs/2-in-1s, and tablets on HarmonyOS NEXT 5.0.4+.
- **Emulator**: not supported — always test on a real device.
- **Region**: currently available only in the Chinese mainland.
- **Files**: Reader Kit only reads local files from the app sandbox — no streaming, no DRM. Give each book its own directory.
- All snippets assume a book file already sits in your sandbox, e.g. imported earlier via `DocumentViewPicker`:

```typescript
const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
const path = `${context.filesDir}/books/abc.epub`;
```

---

## Part 1 — Parsing a Book with BookParser

### 1.1 Get a Parser Handle

Every BookParser operation starts with `getDefaultHandler`, which returns a `BookParserHandler` bound to one file.

```typescript
import { common } from '@kit.AbilityKit';
import { bookParser } from '@kit.ReaderKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct BookDetailPage {
  private defaultHandler: bookParser.BookParserHandler | null = null;

  aboutToAppear(): void {
    this.initParser().then(() => {
      this.loadBookInfo();
      this.loadCatalog();
    });
  }

  private async initParser(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const path = `${context.filesDir}/books/abc.epub`;
    try {
      this.defaultHandler = await bookParser.getDefaultHandler(path);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0000, 'ReaderDemo', `getDefaultHandler failed, code: ${err.code}, message: ${err.message}`);
    }
  }

  build() {
  }
}
```

### 1.2 Read Book Info (Title, Author, Cover)

`getBookInfo()` returns metadata synchronously; the cover is fetched separately through `getResourceContent`, passing `-1` as the spine index since the cover isn't tied to a spine item.

```typescript
@State bookCover: image.PixelMap | null = null;
@State bookTitle: string = '';
@State author: string = '';

private async loadBookInfo(): Promise<void> {
  try {
    const bookInfo = this.defaultHandler?.getBookInfo();
    if (bookInfo) {
      this.bookTitle = bookInfo.bookTitle || '';
      this.author = bookInfo.bookCreator || '';
      const buffer = this.defaultHandler?.getResourceContent(-1, bookInfo.bookCoverImage);
      if (buffer) {
        const imageSource: image.ImageSource = image.createImageSource(buffer);
        this.bookCover = await imageSource.createPixelMap();
        imageSource.release();
      }
    }
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'ReaderDemo', `getBookInfo failed, code: ${err.code}, message: ${err.message}`);
  }
}

build() {
  Column() {
    Text(`Book title: ${this.bookTitle}`)
      .fontSize(20)
      .fontColor('#E6000000')
      .margin({ top: 50 })
    Text(`Author: ${this.author}`)
      .fontSize(20)
      .fontColor('#E6000000')
      .margin({ top: 10 })
    Image(this.bookCover)
      .width(200)
      .aspectRatio(3 / 4)
      .borderRadius(5)
      .margin({ top: 10 })
  }
  .alignItems(HorizontalAlign.Start)
  .margin({ left: 10, right: 10 })
}
```

### 1.3 Read the Catalog (Table of Contents)

`getCatalogList()` returns the hierarchical chapter list. Tapping an item resolves its `domPos` and spine index so you can later hand them to `startPlay`.

```typescript
@State catalogItemList: bookParser.CatalogItem[] = [];

private loadCatalog(): void {
  try {
    this.catalogItemList = this.defaultHandler?.getCatalogList() || [];
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'ReaderDemo', `getCatalogList failed, code: ${err.code}, message: ${err.message}`);
  }
}

build() {
  List() {
    ForEach(this.catalogItemList, (item: bookParser.CatalogItem) => {
      ListItem() {
        Row() {
          Text(item.catalogName)
            .fontSize(14)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(2)
            .layoutWeight(1)
        }
        .padding({
          left: item.catalogLevel ? item.catalogLevel * 26 : 10,
          right: item.catalogLevel ? item.catalogLevel * 26 : 10,
          top: 6,
          bottom: 6
        })
        .onClick(() => {
          this.openChapter(item);
        })
      }
    })
  }
  .width('100%')
  .height('100%')
}
```

### 1.4 Resolve a Catalog Item to a Reading Position

```typescript
private resolveDomPos(catalogItem: bookParser.CatalogItem): string {
  try {
    return this.defaultHandler?.getDomPosByCatalogHref(catalogItem.href || '') || '';
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'ReaderDemo', `getDomPosByCatalogHref failed, code: ${err.code}, message: ${err.message}`);
    return '';
  }
}

private resolveSpineItem(catalogItem: bookParser.CatalogItem): bookParser.SpineItem {
  const resourceFile = catalogItem.resourceFile || '';
  try {
    const spineList = this.defaultHandler?.getSpineList() || [];
    const match = spineList.find(item => item.href === resourceFile);
    if (match) {
      return match;
    }
    if (spineList.length > 0) {
      return spineList[0];
    }
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'ReaderDemo', `getSpineList failed, code: ${err.code}, message: ${err.message}`);
  }
  return { idRef: '', index: 0, href: '', properties: '' };
}

private openChapter(catalogItem: bookParser.CatalogItem): void {
  const domPos = this.resolveDomPos(catalogItem);
  const spineIndex = this.resolveSpineItem(catalogItem).index;
  this.getUIContext().getRouter().pushUrl({
    url: 'pages/ReaderPage',
    params: { spineIndex, domPos }
  });
}
```

---

## Part 2 — Building the Reader with ReadPageComponent

The reader page owns a `ReaderComponentController`, a `ReaderSetting` object, and the `ReadPageComponent` itself. The controller must be initialized, given a page config, given a parser, and only then told to `startPlay` — in that exact order.

```typescript
import { bookParser, ReadPageComponent, readerCore } from '@kit.ReaderKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct ReaderPage {
  private readerComponentController: readerCore.ReaderComponentController = new readerCore.ReaderComponentController();
  private bookParserHandler: bookParser.BookParserHandler | null = null;
  private readerSetting: readerCore.ReaderSetting = {
    fontName: 'System font',
    fontPath: '',
    fontSize: 18,
    fontColor: '#000000',
    fontWeight: 400,
    lineHeight: 1.9,
    nightMode: false,
    themeColor: 'rgba(248, 249, 250, 1)',
    themeBgImg: '',
    flipMode: '0',
    scaledDensity: display.getDefaultDisplaySync().scaledDensity > 0
      ? display.getDefaultDisplaySync().scaledDensity : 1,
    viewPortWidth: 1260,
    viewPortHeight: 2720,
  };
  @State isLoading: boolean = true;

  build() {
    Stack() {
      ReadPageComponent({
        controller: this.readerComponentController,
        readerCallback: (err: BusinessError, data: readerCore.ReaderComponentController) => {
          if (err) {
            hilog.error(0x0000, 'ReaderDemo', `ReadPageComponent callback error, code: ${err.code}`);
            return;
          }
          this.readerComponentController = data;
          this.registerListeners();
          this.openBook();
        }
      })

      Row() {
        Text('Loading...')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Color.White)
      .visibility(this.isLoading ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .height('100%')
  }

  private registerListeners(): void {
    this.readerComponentController.on('pageShow', (data: readerCore.PageDataInfo): void => {
      if (data.state === readerCore.PageState.PAGE_ON_SHOW) {
        this.isLoading = false;
      }
    });
  }

  private async openBook(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const filePath = `${context.filesDir}/books/abc.epub`;
    const spineIndex = 0;
    const domPos = '';
    try {
      const initPromise = this.readerComponentController.init(context);
      const handlerPromise = bookParser.getDefaultHandler(filePath);
      const [handler] = await Promise.all([handlerPromise, initPromise]);
      this.bookParserHandler = handler;
      this.readerComponentController.setPageConfig(this.readerSetting);
      this.readerComponentController.registerBookParser(this.bookParserHandler);
      await this.readerComponentController.startPlay(spineIndex, domPos);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0000, 'ReaderDemo', `openBook failed, code: ${err.code}, message: ${err.message}`);
    }
  }

  aboutToDisappear(): void {
    this.readerComponentController.off('pageShow');
    this.readerComponentController.releaseBook();
  }
}
```

> **Why `openBook()` runs from `readerCallback` and not `aboutToAppear()`:** the controller you get in `readerCallback` is the real, component-bound instance. Calling `init`/`setPageConfig`/`startPlay` any earlier risks running them against the placeholder instance created by `new readerCore.ReaderComponentController()`, before the component has attached to it.

---

## Part 3 — Customizing the Reading Experience

Everything below mutates `this.readerSetting` and re-applies it with `this.readerComponentController.setPageConfig(this.readerSetting)`. Add these methods to `ReaderPage`.

### 3.1 Custom Fonts

Font files can live in `resources/rawfile` or the app sandbox. Set `fontName`/`fontPath`, then answer the engine's resource requests.

```typescript
private applyCustomFont(): void {
  this.readerSetting.fontName = 'Source Han Serif';
  this.readerSetting.fontPath = 'fonts/SourceHanSerifCN-VF.ttf';
  this.readerComponentController.setPageConfig(this.readerSetting);
}
```

### 3.2 Custom Page Background

`themeColor` paints the flip-back face during simulated page turns and, absent an image, the page itself. `themeBgImg` overlays an image. Keep `fontColor` and `nightMode` coherent with whichever background you pick.

```typescript
private applyLightBackground(): void {
  this.readerSetting.themeColor = '#FFFFFF';
  this.readerSetting.themeBgImg = '';
  this.readerSetting.nightMode = false;
  this.readerSetting.fontColor = '#000000';
  this.readerComponentController.setPageConfig(this.readerSetting);
}

private applyImageBackground(): void {
  this.readerSetting.themeBgImg = 'paper_texture.jpg';
  this.readerSetting.themeColor = '#F5F0E6';
  this.readerSetting.nightMode = false;
  this.readerSetting.fontColor = '#000000';
  this.readerComponentController.setPageConfig(this.readerSetting);
}
```

### 3.3 Serving Font and Background Resources

Both features rely on the same `resourceRequest` event. Register a single handler that recognizes font extensions and falls back to treating the request as an image; check `resources/rawfile` first, then the sandbox.

```typescript
import { fileIo as fs } from '@kit.CoreFileKit';

private isFont(filePath: string): boolean {
  const fontExtensions = ['.ttf', '.woff2', '.otf'];
  const path = filePath.toLowerCase();
  return fontExtensions.some(ext => path.endsWith(ext));
}

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
    hilog.error(0x0000, 'ReaderDemo', `resourceRequest rawfile lookup failed, code: ${err.code}, message: ${err.message}`);
  }
  return this.loadFileFromSandbox(filePath);
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
    hilog.error(0x0000, 'ReaderDemo', `loadFileFromSandbox failed, code: ${err.code}, message: ${err.message}`);
    return new ArrayBuffer(0);
  }
}
```

Register and release it alongside `pageShow`:

```typescript
private registerListeners(): void {
  this.readerComponentController.on('pageShow', (data: readerCore.PageDataInfo): void => {
    if (data.state === readerCore.PageState.PAGE_ON_SHOW) {
      this.isLoading = false;
    }
  });
  this.readerComponentController.on('resourceRequest', this.resourceRequest);
}

aboutToDisappear(): void {
  this.readerComponentController.off('pageShow');
  this.readerComponentController.off('resourceRequest');
  this.readerComponentController.releaseBook();
}
```

### 3.4 Page-Turning Mode, Font Size, Line Height

```typescript
private applyTypesetting(flipMode: string, fontSize: number, lineHeight: number): void {
  this.readerSetting.flipMode = flipMode;
  this.readerSetting.fontSize = fontSize;
  this.readerSetting.lineHeight = lineHeight;
  this.readerComponentController.setPageConfig(this.readerSetting);
}
```

`flipMode`: `'0'` for simulated page turning, `'1'` for swipe.

### 3.5 Adapting to Dark and Light Mode

Listen for system theme changes at the `UIAbility` level, push the value through `AppStorage`, and react to it in the reader with `@StorageLink` + `@Watch`.

```typescript
import { Configuration, ConfigurationConstant, UIAbility } from '@kit.AbilityKit';

export default class EntryAbility extends UIAbility {
  onConfigurationUpdate(newConfig: Configuration): void {
    AppStorage.setOrCreate('colorMode', newConfig.colorMode);
  }
}
```

```typescript
@StorageLink('colorMode') @Watch('onColorModeChange') colorMode: ConfigurationConstant.ColorMode =
  ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

private onColorModeChange(): void {
  if (this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
    this.readerSetting.nightMode = true;
    this.readerSetting.fontColor = '#FFFFFF';
    this.readerSetting.themeColor = '#202224';
  } else {
    this.readerSetting.nightMode = false;
    this.readerSetting.fontColor = '#000000';
    this.readerSetting.themeColor = '#FFFFFF';
  }
  this.readerComponentController.setPageConfig(this.readerSetting);
}
```

### 3.6 Reacting to Text Scaling Factor Changes

Multi-window resizing can change `display.scaledDensity` mid-session. When it drifts from the value the reader was configured with, the cleanest fix is to close and reopen the reading page at the same progress.

```typescript
private screenDensityCallback: Callback<number> = (): void => {
  const scaledDensity = display.getDefaultDisplaySync().scaledDensity;
  if (scaledDensity !== this.readerSetting.scaledDensity) {
    AppStorage.setOrCreate('isDensityChange', true);
    this.getUIContext().getRouter().back();
  }
}

aboutToAppear(): void {
  display.on('change', this.screenDensityCallback);
}

aboutToDisappear(): void {
  display.off('change', this.screenDensityCallback);
}
```

On the parent page, watch for the flag and re-enter the reader (resuming at the last saved progress, see Part 4.2):

```typescript
@StorageLink('isDensityChange') isDensityChange: boolean = false;

onPageShow(): void {
  if (this.isDensityChange) {
    this.reopenReader();
    AppStorage.setOrCreate('isDensityChange', false);
  }
}

private reopenReader(): void {
  this.getUIContext().getRouter().pushUrl({ url: 'pages/ReaderPage' }).catch((error: BusinessError) => {
    hilog.error(0x0000, 'ReaderDemo', `pushUrl failed, code: ${error.code}`);
  });
}
```

---

## Part 4 — Advanced Controls

### 4.1 Manually Triggering Page Turns

Useful for earphone buttons, volume-key turning, or custom gestures layered on top of the built-in tap/swipe handling.

```typescript
private turnPage(isNext: boolean): void {
  this.readerComponentController.flipPage(isNext);
}
```

### 4.2 Capturing and Persisting Reading Progress

`pageShow` fires every time a new page renders, carrying the current `resourceIndex` and `startDomPos`. Persist both so the reader can resume exactly where the user left off, even after an unexpected exit.

```typescript
private registerListeners(): void {
  this.readerComponentController.on('pageShow', (data: readerCore.PageDataInfo): void => {
    if (data.state === readerCore.PageState.PAGE_ON_SHOW) {
      this.isLoading = false;
    }
    this.saveProgress(data.resourceIndex, data.startDomPos);
  });
  this.readerComponentController.on('resourceRequest', this.resourceRequest);
}

private saveProgress(resourceIndex: number, domPos: string): void {
  AppStorage.setOrCreate('lastResourceIndex', resourceIndex);
  AppStorage.setOrCreate('lastDomPos', domPos);
}
```

To resume, read the saved values back and feed them into `startPlay`:

```typescript
private async openBook(): Promise<void> {
  const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  const filePath = `${context.filesDir}/books/abc.epub`;
  const spineIndex = AppStorage.get<number>('lastResourceIndex') ?? 0;
  const domPos = AppStorage.get<string>('lastDomPos') ?? '';
  try {
    const initPromise = this.readerComponentController.init(context);
    const handlerPromise = bookParser.getDefaultHandler(filePath);
    const [handler] = await Promise.all([handlerPromise, initPromise]);
    this.bookParserHandler = handler;
    this.readerComponentController.setPageConfig(this.readerSetting);
    this.readerComponentController.registerBookParser(this.bookParserHandler);
    await this.readerComponentController.startPlay(spineIndex, domPos);
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'ReaderDemo', `openBook failed, code: ${err.code}, message: ${err.message}`);
  }
}
```

---

## Recap

| Goal | API |
|---|---|
| Parse a book | `bookParser.getDefaultHandler(path)` |
| Read metadata / cover | `getBookInfo()`, `getResourceContent(-1, coverPath)` |
| Read the table of contents | `getCatalogList()`, `getDomPosByCatalogHref()`, `getSpineList()` |
| Render the reader | `ReadPageComponent`, `ReaderComponentController.init/setPageConfig/registerBookParser/startPlay` |
| Serve fonts & backgrounds | `on('resourceRequest')` |
| Change look & feel | `fontName`, `fontPath`, `fontSize`, `lineHeight`, `themeColor`, `themeBgImg`, `flipMode`, `nightMode` via `setPageConfig` |
| React to system changes | `onConfigurationUpdate`, `display.on('change')` |
| Manual navigation | `flipPage(isNext)` |
| Track progress | `on('pageShow')` → `resourceIndex` / `startDomPos` |
