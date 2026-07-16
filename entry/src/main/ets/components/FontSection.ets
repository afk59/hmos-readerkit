import { FontOption, FONT_OPTIONS } from '../model/ReaderOptions';
import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct FontSection {
  @Prop selectedIndex: number;
  onSelect: (index: number) => void = () => {};

  build() {
    Column() {
      Text('Font')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        .margin({ bottom: 8 })
      Row() {
        ForEach(FONT_OPTIONS, (option: FontOption, index: number) => {
          Button(option.label)
            .fontSize(12)
            .backgroundColor(this.selectedIndex === index ? ReaderConstants.COLOR_CHIP_BG_ACTIVE : ReaderConstants.COLOR_CHIP_BG)
            .fontColor(this.selectedIndex === index ? ReaderConstants.COLOR_TEXT_ON_ACCENT : ReaderConstants.COLOR_TEXT_PRIMARY)
            .margin({ right: 8 })
            .onClick(() => this.onSelect(index))
        }, (option: FontOption) => option.label)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
