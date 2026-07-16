import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct DarkModeSection {
  @Prop nightMode: boolean;
  onToggle: (isOn: boolean) => void = () => {};

  build() {
    Column() {
      Text('Dark Mode')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        .margin({ bottom: 8 })
      Row() {
        Text(this.nightMode ? 'Dark theme active' : 'Light theme active')
          .fontSize(12)
          .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.nightMode })
          .onChange((isOn: boolean) => this.onToggle(isOn))
      }
      .width('100%')
      Text('Also follows the system color scheme automatically.')
        .fontSize(11)
        .fontColor(ReaderConstants.COLOR_TEXT_SECONDARY)
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
