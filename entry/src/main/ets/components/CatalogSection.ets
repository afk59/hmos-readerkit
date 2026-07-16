import { bookParser } from '@kit.ReaderKit';
import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct CatalogSection {
  @Prop catalogItemList: bookParser.CatalogItem[];
  onSelect: (item: bookParser.CatalogItem) => void = () => {};

  build() {
    Column() {
      Text('Chapters')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
        .margin({ bottom: 8 })
      if (this.catalogItemList.length === 0) {
        Text('No chapter list for this book.')
          .fontSize(12)
          .fontColor(ReaderConstants.COLOR_TEXT_SECONDARY)
      } else {
        List() {
          ForEach(this.catalogItemList, (item: bookParser.CatalogItem) => {
            ListItem() {
              Text(item.catalogName)
                .fontSize(13)
                .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .maxLines(1)
                .padding({ top: 6, bottom: 6 })
            }
            .onClick(() => this.onSelect(item))
          }, (item: bookParser.CatalogItem) => item.href || item.catalogName)
        }
        .scrollBar(BarState.Auto)
        .width('100%')
        .height(140)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
