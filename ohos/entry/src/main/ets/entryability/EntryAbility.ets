
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import DeviceInfoBridge from '../plugins/DeviceInfoBridge';
import OrientationPlugin from '../orientation/OrientationPlugin';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    // 手动注册本地自定义插件，避免被自动生成文件覆盖
    flutterEngine.getPlugins()?.add(new DeviceInfoBridge());
    flutterEngine.getPlugins()?.add(new OrientationPlugin());
  }
}
