import ConfigurationConstant from "@ohos.app.ability.ConfigurationConstant";
import window from "@ohos.window";
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodChannel,
  MethodResult,
} from "@ohos/flutter_ohos";

// import display from "@ohos.display";

export default class HarmonyChannel implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private lastWindow: window.Window | null = null;

  getUniqueClassName(): string {
    return "HarmonyChannel";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "harmonyChannel");
    this.channel.setMethodCallHandler(this);
    // // 监听画面方向
    // display.on('change', () => {
    //   // 获取当前旋转角度
    //   let rotation = display.getDefaultDisplaySync().rotation;
    //   this.channel!.invokeMethod('onRotationChange', { 'rotation': rotation })
    // })
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
  }

  async csy(call: MethodCall) {
    this.lastWindow ??= await window.getLastWindow(getContext());
    return this.lastWindow.setSpecificSystemBarEnabled("status", call.argument("value"), true);
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case "csy":
        result.success(await this.csy(call));
        break;
      case "setMiniWindowLandscape":
        const landscape: boolean = call.argument("landscape") ?? false;
        await this.setMiniWindowLandscape(landscape);
        result.success(true);
        break;
      case "autoRotateLandscape":
        await this.autoRotateLandscape();
        result.success(true);
        break;
      case "setDecorButtonDark": {
        const dark: boolean = call.argument("dark") ?? false;
        await this.setDecorButtonDark(dark);
        result.success(true);
        break;
      }
      // case 'setWindowLayoutFullScreen': {
      //   this.lastWindow ??= await window.getLastWindow(getContext())
      //   this.lastWindow.setWindowLayoutFullScreen(call.argument('fullScreen'));
      //   result.success(true);
      //   break;
      // }
      default:
        result.notImplemented();
        break;
    }
  }

  public onFloatingWindowChange(isFloatingWindow: boolean) {
    this.channel?.invokeMethod("onFloatingWindowChange", { isFloatingWindow: isFloatingWindow });
  }

  private async setMiniWindowLandscape(landscape: boolean) {
    this.lastWindow ??= await window.getLastWindow(getContext());
    if (landscape) {
      this.lastWindow.enableLandscapeMultiWindow();
    } else {
      this.lastWindow.disableLandscapeMultiWindow();
    }
  }

  async autoRotateLandscape() {
    this.lastWindow ??= await window.getLastWindow(getContext());
    this.lastWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_LANDSCAPE)
  }

  /**
   * 自由多窗装饰栏按钮颜色：dark=true 时按深色模式渲染（浅色按钮，适配
   * 深色内容顶部），false 恢复跟随系统颜色模式。仅装饰栏可见（自由窗口）
   * 时有视觉效果，其余窗口形态下为无害空操作。
   */
  private async setDecorButtonDark(dark: boolean) {
    this.lastWindow ??= await window.getLastWindow(getContext());
    try {
      this.lastWindow.setDecorButtonStyle({
        colorMode: dark
          ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK
          : ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
      });
    } catch (err) {
      console.error("HarmonyChannel", `setDecorButtonStyle failed: ${err}`);
    }
  }
}
