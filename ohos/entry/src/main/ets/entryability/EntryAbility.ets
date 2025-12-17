
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import OrientationPlugin from '../orientation/OrientationPlugin';
import DeviceInfoBridge from '../plugins/DeviceInfoBridge';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    flutterEngine.getPlugins()?.add(new OrientationPlugin());
    flutterEngine.getPlugins()?.add(new DeviceInfoBridge());
  }
}
