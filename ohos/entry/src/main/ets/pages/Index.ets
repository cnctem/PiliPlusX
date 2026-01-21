
import common from '@ohos.app.ability.common';
import { FlutterPage } from '@ohos/flutter_ohos'
import { AVVolumePanel } from '@kit.AudioKit';

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = "";
  @State volume: number = 0;

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
      AVVolumePanel({
        volumeLevel: this.volume,
        volumeParameter: {
          position: {
            x: -100,
            y: -200
          }
        }
      })
    }
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}