import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct TypographySection {
  @Prop fontSize: number;
  @Prop lineHeight: number;
  onFontSizeChange: (value: number) => void = () => {};
  onLineHeightChange: (value: number) => void = () => {};

  build() {
    Column() {
      Text('Font Size & Line Height')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        .margin({ bottom: 8 })
      Row() {
        Text('Size').fontSize(12).fontColor(ReaderConstants.COLOR_TEXT_PRIMARY).width(50)
        Slider({
          value: this.fontSize,
          min: ReaderConstants.MIN_FONT_SIZE,
          max: ReaderConstants.MAX_FONT_SIZE,
          step: 1
        })
          .layoutWeight(1)
          .onChange((value: number) => this.onFontSizeChange(value))
        Text(`${this.fontSize}`).fontSize(12).fontColor(ReaderConstants.COLOR_TEXT_PRIMARY).width(28).textAlign(TextAlign.End)
      }
      .width('100%')

      Row() {
        Text('Line').fontSize(12).fontColor(ReaderConstants.COLOR_TEXT_PRIMARY).width(50)
        Slider({
          value: this.lineHeight,
          min: ReaderConstants.MIN_LINE_HEIGHT,
          max: ReaderConstants.MAX_LINE_HEIGHT,
          step: 0.1
        })
          .layoutWeight(1)
          .onChange((value: number) => this.onLineHeightChange(value))
        Text(this.lineHeight.toFixed(1)).fontSize(12).fontColor(ReaderConstants.COLOR_TEXT_PRIMARY).width(28).textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
