import { BackgroundOption, BACKGROUND_OPTIONS } from '../model/ReaderOptions';
import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct BackgroundSection {
  @Prop selectedIndex: number;
  onSelect: (index: number) => void = () => {};

  build() {
    Column() {
      Text('Background')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        .margin({ bottom: 8 })
      Row() {
        ForEach(BACKGROUND_OPTIONS, (option: BackgroundOption, index: number) => {
          Column() {
            Column()
              .width(32)
              .height(32)
              .borderRadius(16)
              .backgroundColor(option.themeColor)
              .border({
                width: this.selectedIndex === index ? 2 : 1,
                color: this.selectedIndex === index ? ReaderConstants.COLOR_SWATCH_BORDER_ACTIVE : ReaderConstants.COLOR_SWATCH_BORDER
              })
            Text(option.label)
              .fontSize(11)
              .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
              .margin({ top: 4 })
          }
          .margin({ right: 12 })
          .onClick(() => this.onSelect(index))
        }, (option: BackgroundOption) => option.label)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
