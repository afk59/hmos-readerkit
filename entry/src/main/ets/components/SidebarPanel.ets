import { bookParser } from '@kit.ReaderKit';
import { image } from '@kit.ImageKit';
import { ReaderConstants } from '../common/ReaderConstants';
import { BookInfoSection } from './BookInfoSection';
import { CatalogSection } from './CatalogSection';
import { FontSection } from './FontSection';
import { BackgroundSection } from './BackgroundSection';
import { TypographySection } from './TypographySection';
import { FlipModeSection } from './FlipModeSection';
import { DarkModeSection } from './DarkModeSection';
import { ScalingSection } from './ScalingSection';

@Component
export struct SidebarPanel {
  @Prop bookTitle: string;
  @Prop bookAuthor: string;
  @Prop bookCover: image.PixelMap | null;
  @Prop catalogItemList: bookParser.CatalogItem[];
  @Prop selectedFontIndex: number;
  @Prop selectedBackgroundIndex: number;
  @Prop fontSize: number;
  @Prop lineHeight: number;
  @Prop flipMode: string;
  @Prop nightMode: boolean;
  @Prop scaledDensity: number;

  onSelectCatalogItem: (item: bookParser.CatalogItem) => void = () => {};
  onSelectFont: (index: number) => void = () => {};
  onSelectBackground: (index: number) => void = () => {};
  onFontSizeChange: (value: number) => void = () => {};
  onLineHeightChange: (value: number) => void = () => {};
  onSelectFlipMode: (mode: string) => void = () => {};
  onToggleNightMode: (isOn: boolean) => void = () => {};

  build() {
    Scroll() {
      Column() {
        BookInfoSection({
          bookTitle: this.bookTitle,
          bookAuthor: this.bookAuthor,
          bookCover: this.bookCover
        })
        Divider().margin({ top: 12, bottom: 12 }).color(ReaderConstants.COLOR_DIVIDER)
        CatalogSection({
          catalogItemList: this.catalogItemList,
          onSelect: this.onSelectCatalogItem
        })
        Divider().margin({ top: 12, bottom: 12 }).color(ReaderConstants.COLOR_DIVIDER)
        FontSection({
          selectedIndex: this.selectedFontIndex,
          onSelect: this.onSelectFont
        })
        Divider().margin({ top: 12, bottom: 12 }).color(ReaderConstants.COLOR_DIVIDER)
        BackgroundSection({
          selectedIndex: this.selectedBackgroundIndex,
          onSelect: this.onSelectBackground
        })
        Divider().margin({ top: 12, bottom: 12 }).color(ReaderConstants.COLOR_DIVIDER)
        TypographySection({
          fontSize: this.fontSize,
          lineHeight: this.lineHeight,
          onFontSizeChange: this.onFontSizeChange,
          onLineHeightChange: this.onLineHeightChange
        })
        Divider().margin({ top: 12, bottom: 12 }).color(ReaderConstants.COLOR_DIVIDER)
        FlipModeSection({
          flipMode: this.flipMode,
          onSelect: this.onSelectFlipMode
        })
        Divider().margin({ top: 12, bottom: 12 }).color(ReaderConstants.COLOR_DIVIDER)
        DarkModeSection({
          nightMode: this.nightMode,
          onToggle: this.onToggleNightMode
        })
        Divider().margin({ top: 12, bottom: 12 }).color(ReaderConstants.COLOR_DIVIDER)
        ScalingSection({
          scaledDensity: this.scaledDensity
        })
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
    }
    .width(ReaderConstants.SIDEBAR_WIDTH)
    .height('100%')
    .backgroundColor(ReaderConstants.COLOR_SURFACE_SIDEBAR)
  }
}
