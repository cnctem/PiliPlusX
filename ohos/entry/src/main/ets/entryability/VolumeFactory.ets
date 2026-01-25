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
import { BusinessError } from '@ohos.base'

const volumeGroupId = audio.DEFAULT_VOLUME_GROUP_ID

AppStorage.setOrCreate('volume', 0)

AppStorage.setOrCreate('visible', true)

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
  @StorageLink('visible') visible: boolean = true

  build() {
    AVVolumePanel({
      volumeLevel: this.volume,
      volumeParameter: this.visible ? undefined :
        {
          position: {
            x: -1,
            y: -1
          }
        }
    })
  }
}

@Builder
function VolumeComponentBuilder(params: Params) {
  VolumeComponent()
}

const TAG = '音量面板：'

@Observed
export class VolumeView extends PlatformView implements MethodCallHandler {
  volumeLink: SubscribedAbstractProperty<number> = AppStorage.link('volume')
  visibleLink: SubscribedAbstractProperty<boolean> = AppStorage.link('visible');
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
    console.warn(TAG + '创建，请注意有没有重复创建');
    this.methodChannel =
      new MethodChannel(binaryMessenger, `AVVolumePanel_${viewId}`);
    this.methodChannel.setMethodCallHandler(this);
    this.volumeManager = audio.getAudioManager().getVolumeManager()
    this.minVolume = this.volumeManager.getMinVolumeByStream(volumeGroupId)
    this.volumeRange = this.volumeManager.getMaxVolumeByStream(volumeGroupId) - this.minVolume
    this.volumeManager.on('streamVolumeChange', audio.StreamUsage.STREAM_USAGE_MUSIC,
      (streamVolumeEvent) => this.onVolumeChange(streamVolumeEvent.volume));
  }

  systemVolumeToPercent(systemVolume: number): number {
    return (systemVolume - this.minVolume) / this.volumeRange;
  }

  onVolumeChange(systemVolume: number): void {
    let percentVolume = this.systemVolumeToPercent(systemVolume);
    console.log(TAG, '音量变化' + percentVolume);
    this.methodChannel.invokeMethod(
      'onVolumeChange', { 'volume': percentVolume }
    )
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'setVolume':
        try {
          const volume: number = call.argument('volume')
          // [0 ,1]转系统音量
          this.volumeLink.set(this.minVolume + volume * this.volumeRange)
          // console.log(TAG, '调整音量' + volume);
          result.success(null)
        } catch (e) {
          let err = e as BusinessError;
          result.error(err.code.toString(), err.message, err.data)
        }
        break;
      case 'setPanelVisible':
        let visible: boolean = call.argument('visible');
        try {

          this.visibleLink.set(visible)
          console.log(TAG, '是否可见' + visible);
        } catch (e) {
          console.error(TAG, '设置可见失败' + e);
        }
        result.success(true)
        break;
      case 'getVolume':
        const systemVolume = this.volumeManager.getVolumeByStream(volumeGroupId)
        console.log(TAG, '系统音量' + systemVolume);
        // 系统音量转[0, 1]
        result.success(this.systemVolumeToPercent(systemVolume))
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