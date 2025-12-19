import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import type Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import OrientationPlugin from '../orientation/OrientationPlugin';
import DeviceInfoBridge from '../plugins/DeviceInfoBridge';
import BackgroundPlugin from '../plugins/BackgroundPlugin';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
// abilityAccessCtrl/hilog 已在后台插件内部使用，这里无需引入

export default class EntryAbility extends FlutterAbility {
  // private windowManagerPlugin: WindowManagerPlugin = new WindowManagerPlugin()
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    flutterEngine.getPlugins()?.add(new OrientationPlugin());
    flutterEngine.getPlugins()?.add(new DeviceInfoBridge());
    flutterEngine.getPlugins()?.add(new BackgroundPlugin());
    // flutterEngine.getPlugins()?.add(this.windowManagerPlugin);
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    super.onCreate(want, launchParam);
  }

  // async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
  //   super.onWindowStageCreate(windowStage)
  //   const appWindow = await windowStage.getMainWindow();
  //   let callback: Callback<number> = (data: number) => {
  //     let orientation = display.getDefaultDisplaySync().orientation
  //     if (orientation == 1 || orientation == 3) {
  //       appWindow.enableLandscapeMultiWindow();
  //     } else {
  //       appWindow.disableLandscapeMultiWindow();
  //     }
  //   };
  //   display.on('change', callback)
  // }
}
