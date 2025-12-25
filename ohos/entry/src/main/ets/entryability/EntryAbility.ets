import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import type Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import OrientationPlugin from '../orientation/OrientationPlugin';
import BackgroundPlugin from '../plugins/BackgroundPlugin';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { VolumeFactory } from './VolumeFactory';

import { deviceInfo } from '@kit.BasicServicesKit';
import HarmonyChannel from '../plugins/HarmonyChannel';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    flutterEngine.getPlatformViewsController()?.getRegistry().registerViewFactory(
      'AVVolumePanel',
      new VolumeFactory(flutterEngine.dartExecutor.getBinaryMessenger())
    )
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    flutterEngine.getPlugins()?.add(new HarmonyChannel());
    flutterEngine.getPlugins()?.add(new OrientationPlugin());
    flutterEngine.getPlugins()?.add(new BackgroundPlugin());
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    super.onCreate(want, launchParam);
  }
}
