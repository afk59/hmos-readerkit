import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct FlipModeSection {
  @Prop flipMode: string;
  onSelect: (mode: string) => void = () => {};

  build() {
    Column() {
      Text('Page-Turning Mode')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        .margin({ bottom: 8 })
      Row() {
        Button('Simulated')
          .fontSize(12)
          .backgroundColor(this.flipMode === '0' ? ReaderConstants.COLOR_CHIP_BG_ACTIVE : ReaderConstants.COLOR_CHIP_BG)
          .fontColor(this.flipMode === '0' ? ReaderConstants.COLOR_TEXT_ON_ACCENT : ReaderConstants.COLOR_TEXT_PRIMARY)
          .margin({ right: 8 })
          .onClick(() => this.onSelect('0'))
        Button('Swipe')
          .fontSize(12)
          .backgroundColor(this.flipMode === '1' ? ReaderConstants.COLOR_CHIP_BG_ACTIVE : ReaderConstants.COLOR_CHIP_BG)
          .fontColor(this.flipMode === '1' ? ReaderConstants.COLOR_TEXT_ON_ACCENT : ReaderConstants.COLOR_TEXT_PRIMARY)
          .onClick(() => this.onSelect('1'))
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
