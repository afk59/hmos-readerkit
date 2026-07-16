import { image } from '@kit.ImageKit';
import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct BookInfoSection {
  @Prop bookTitle: string;
  @Prop bookAuthor: string;
  @Prop bookCover: image.PixelMap | null;

  build() {
    Column() {
      Text('Book')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        .margin({ bottom: 8 })
      Row() {
        if (this.bookCover) {
          Image(this.bookCover)
            .width(56)
            .height(76)
            .borderRadius(4)
            .objectFit(ImageFit.Cover)
        } else {
          Column()
            .width(56)
            .height(76)
            .borderRadius(4)
            .backgroundColor(ReaderConstants.COLOR_COVER_PLACEHOLDER_BG)
        }
        Column() {
          Text(this.bookTitle.length > 0 ? this.bookTitle : 'Sample Book')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
            .maxLines(2)
          Text(this.bookAuthor.length > 0 ? this.bookAuthor : 'Reader Kit')
            .fontSize(12)
            .fontColor(ReaderConstants.COLOR_TEXT_SECONDARY)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        .layoutWeight(1)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
