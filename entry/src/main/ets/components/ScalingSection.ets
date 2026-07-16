import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct ScalingSection {
  @Prop scaledDensity: number;

  build() {
    Column() {
      Text('Text Scaling Factor')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        .margin({ bottom: 8 })
      Text(`Current scaledDensity: ${this.scaledDensity.toFixed(2)}`)
        .fontSize(12)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
      Text('Automatically re-typesets the page when the system font/display scale changes, for example during multi-window resize.')
        .fontSize(11)
        .fontColor(ReaderConstants.COLOR_TEXT_SECONDARY)
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
