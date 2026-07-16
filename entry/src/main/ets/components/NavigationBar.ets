import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct NavigationBar {
  @Prop flipMode: string;
  onTurnPage: (isNext: boolean) => void = () => {};

  build() {
    Row() {
      Button('Previous')
        .fontSize(13)
        .fontColor(ReaderConstants.COLOR_TEXT_ON_DARK)
        .backgroundColor(ReaderConstants.COLOR_ACCENT)
        .margin({ right: 12 })
        .onClick(() => this.onTurnPage(false))
      Text(this.flipMode === '0' ? 'Simulated' : 'Swipe')
        .fontSize(12)
        .fontColor(ReaderConstants.COLOR_TEXT_ON_DARK_MUTED)
        .margin({ right: 12 })
      Button('Next')
        .fontSize(13)
        .fontColor(ReaderConstants.COLOR_TEXT_ON_DARK)
        .backgroundColor(ReaderConstants.COLOR_ACCENT)
        .onClick(() => this.onTurnPage(true))
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(12)
    .backgroundColor(ReaderConstants.COLOR_SURFACE_NAVBAR)
  }
}
