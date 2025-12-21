import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import type Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import OrientationPlugin from '../orientation/OrientationPlugin';
import DeviceInfoBridge from '../plugins/DeviceInfoBridge';
import BackgroundPlugin from '../plugins/BackgroundPlugin';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { VolumeFactory } from './VolumeFactory';

// abilityAccessCtrl/hilog 已在后台插件内部使用，这里无需引入

import { deviceInfo } from '@kit.BasicServicesKit';
let devicetypeinfo: string = deviceInfo.deviceType;
console.info('deviceType is '+ devicetypeinfo);


export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    flutterEngine.getPlatformViewsController()?.getRegistry().registerViewFactory(
      'AVVolumePanel',
      new VolumeFactory(flutterEngine.dartExecutor.getBinaryMessenger())
    )
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    flutterEngine.getPlugins()?.add(new OrientationPlugin());
    flutterEngine.getPlugins()?.add(new DeviceInfoBridge());
    flutterEngine.getPlugins()?.add(new BackgroundPlugin());
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
