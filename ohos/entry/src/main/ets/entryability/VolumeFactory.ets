import {
  PlatformViewFactory,
  BinaryMessenger,
  StandardMessageCodec,
  PlatformView,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { audio, AVVolumePanel, AVVolumePanelParameter } from '@kit.AudioKit';

// const hide: AVVolumePanelParameter =
//   {
//     position: {
//       x: -1,
//       y: -1
//     }
//   }
const volumeGroupId = audio.DEFAULT_VOLUME_GROUP_ID

AppStorage.setOrCreate('volume', 0)

// AppStorage.setOrCreate('volumeParameter', hide)

export class VolumeFactory extends PlatformViewFactory {
  private binaryMessenger: BinaryMessenger

  constructor(binaryMessenger: BinaryMessenger) {
    super(StandardMessageCodec.INSTANCE);
    this.binaryMessenger = binaryMessenger
  }

  public create(context: common.Context, viewId: number, args: Object): PlatformView {
    return new VolumeView(viewId, this.binaryMessenger);
  }
}

@Component
struct VolumeComponent {
  @StorageLink('volume') volume: number = 0

  // @StorageLink('volumeParameter') volumeParameter?: AVVolumePanelParameter = hide

  build() {
    AVVolumePanel({
      volumeLevel: this.volume,
      // volumeParameter: this.volumeParameter
    })
  }
}

@Builder
function VolumeComponentBuilder(params: Params) {
  VolumeComponent()
}

@Observed
export class VolumeView extends PlatformView implements MethodCallHandler {
  methodChannel: MethodChannel;
  /**
   系统最小音量
   */
  private minVolume: number
  /**
   系统最大音量减最小音量
   */
  private volumeRange: number
  private volumeManager: audio.AudioVolumeManager

  constructor(viewId: number, binaryMessenger: BinaryMessenger) {
    super();
    this.methodChannel =
      new MethodChannel(binaryMessenger, `AVVolumePanel_${viewId}`);
    this.methodChannel.setMethodCallHandler(this);
    this.volumeManager = audio.getAudioManager().getVolumeManager()
    this.minVolume = this.volumeManager.getMinVolumeByStream(volumeGroupId)
    this.volumeRange = this.volumeManager.getMaxVolumeByStream(volumeGroupId) - this.minVolume
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    let method: string = call.method;
    // let volumeParameterLink: SubscribedAbstractProperty<AVVolumePanelParameter> =
    AppStorage.link('volumeParameter');
    switch (method) {
      case 'setVolume':
        let volumeLink: SubscribedAbstractProperty<number> = AppStorage.link('volume');
        const volume: number = call.argument('volume')
        // 隐藏音量条
        // volumeParameterLink.set(hide)
        // [0 ,1]转系统音量
        volumeLink.set(this.minVolume + volume * this.volumeRange)
        result.success(true)
        break;
      // 恢复显示音量条
      // case 'restorePanel':
      //   volumeParameterLink.set(undefined)
      //   result.success(true)
      //   break;
      case 'getVolume':
        const systemVolume = this.volumeManager.getVolumeByStream(volumeGroupId)
        // 系统音量转[0, 1]
        result.success((systemVolume - this.minVolume) / this.volumeRange)
        break;
      default:
        result.notImplemented()
        break;
    }
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(VolumeComponentBuilder);
  }

  dispose(): void {
  }
}