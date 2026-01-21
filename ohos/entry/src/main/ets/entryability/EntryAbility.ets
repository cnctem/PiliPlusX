import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import type Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { VolumeFactory } from './VolumeFactory';
import HarmonyChannel from '../plugins/HarmonyChannel';
import window from '@ohos.window';
import { AVVolumePanelParameter } from '@kit.AudioKit';

const hide: AVVolumePanelParameter =
  {
    position: {
      x: -10000,
      y: -10000
    }
  }

export default class EntryAbility extends FlutterAbility {
  harmonyChannel: HarmonyChannel = new HarmonyChannel()
  wasFloatingWindow: boolean = false

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    flutterEngine.getPlatformViewsController()?.getRegistry().registerViewFactory(
      'AVVolumePanel',
      new VolumeFactory(flutterEngine.dartExecutor.getBinaryMessenger())
    )
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    flutterEngine.getPlugins()?.add(this.harmonyChannel);
    
    AppStorage.setOrCreate('volumeParameter', hide)
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    super.onCreate(want, launchParam);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    super.onWindowStageCreate(windowStage)
    let w = windowStage.getMainWindowSync()
    w.on('windowStatusChange', (type) => {
      if (type == window.WindowStatusType.FLOATING && !this.wasFloatingWindow) {
        this.harmonyChannel.onFloatingWindowChange(true)
        this.wasFloatingWindow = true
      } else if (this.wasFloatingWindow && type != window.WindowStatusType.FLOATING) {
        this.harmonyChannel.onFloatingWindowChange(false)
        this.wasFloatingWindow = false
      }
    })
  }
}
