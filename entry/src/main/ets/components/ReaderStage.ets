import { ReadPageComponent, readerCore } from '@kit.ReaderKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ReaderConstants } from '../common/ReaderConstants';

@Component
export struct ReaderStage {
  controller: readerCore.ReaderComponentController = new readerCore.ReaderComponentController();
  readerCallback: (err: BusinessError, data: readerCore.ReaderComponentController) => void = () => {};
  onStageAreaChange: (area: Area) => void = () => {};
  @Prop isLoading: boolean;

  build() {
    Stack() {
      ReadPageComponent({
        controller: this.controller,
        readerCallback: this.readerCallback
      })
        .width('100%')
        .height('100%')

      Column() {
        Text('Loading...')
          .fontSize(14)
          .fontColor(ReaderConstants.COLOR_TEXT_PRIMARY)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(ReaderConstants.COLOR_SURFACE_LOADING)
      .visibility(this.isLoading ? Visibility.Visible : Visibility.None)
    }
    .layoutWeight(1)
    .width('100%')
    .onAreaChange((_oldValue: Area, newValue: Area) => this.onStageAreaChange(newValue))
  }
}
