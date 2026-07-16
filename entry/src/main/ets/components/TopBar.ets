import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct TopBar {
  @Prop isSidebarCollapsed: boolean;
  @Prop bookTitle: string;
  @Prop bookAuthor: string;
  @Prop statusMessage: string;
  onToggleSidebar: () => void = () => {};

  build() {
    Row() {
      Button(this.isSidebarCollapsed ? 'Menu' : 'Hide')
        .fontSize(13)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        .backgroundColor(ReaderConstants.COLOR_CHIP_BG)
        .width(64)
        .height(36)
        .margin({ right: 14 })
        .onClick(() => this.onToggleSidebar())

      Column() {
        Text('Reader Kit Showcase')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        Text(this.bookTitle.length > 0 ? `${this.bookTitle} by ${this.bookAuthor}` : 'Preparing sample book...')
          .fontSize(13)
          .fontColor(ReaderConstants.COLOR_TEXT_SECONDARY)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      if (this.statusMessage.length > 0) {
        Text(this.statusMessage)
          .fontSize(12)
          .fontColor(ReaderConstants.COLOR_ERROR)
          .maxLines(2)
          .constraintSize({ maxWidth: 280 })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .backgroundColor(ReaderConstants.COLOR_SURFACE_TOPBAR)
  }
}
