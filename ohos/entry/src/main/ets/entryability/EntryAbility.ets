import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import OrientationPlugin from '../orientation/OrientationPlugin';
import DeviceInfoBridge from '../plugins/DeviceInfoBridge';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { display, window } from '@kit.ArkUI';
// import WindowManagerPlugin from '../plugins/WindowManagerPlugin';

export default class EntryAbility extends FlutterAbility {
  // private windowManagerPlugin: WindowManagerPlugin = new WindowManagerPlugin()
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    flutterEngine.getPlugins()?.add(new OrientationPlugin());
    flutterEngine.getPlugins()?.add(new DeviceInfoBridge());
    // flutterEngine.getPlugins()?.add(this.windowManagerPlugin);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    super.onWindowStageCreate(windowStage)
    const appWindow = await windowStage.getMainWindow();
    let callback: Callback<number> = (data: number) => {
      let orientation = display.getDefaultDisplaySync().orientation
      if (orientation == 1 || orientation == 3) {
        appWindow.enableLandscapeMultiWindow();
      } else {
        appWindow.disableLandscapeMultiWindow();
      }
    };
    display.on('change', callback)
  }
}
