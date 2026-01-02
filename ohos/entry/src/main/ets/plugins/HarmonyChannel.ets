import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult } from "@ohos/flutter_ohos";
import window from "@ohos.window";

export default class HarmonyChannel implements FlutterPlugin {
  private channel: MethodChannel | null = null

  getUniqueClassName(): string {
    return 'HarmonyChannel';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'harmonyChannel');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'setMiniWindowLandscape': {
        const landscape: boolean = call.argument('landscape') ?? false;
        await this.setMiniWindowLandscape(landscape);
        result.success(true);
        break;
      }
      default:
        result.notImplemented();
        break;
    }
  }

  private async setMiniWindowLandscape(landscape: boolean) {
    const lastWindow = await window.getLastWindow(getContext());
    if (landscape) {
      lastWindow.enableLandscapeMultiWindow()
    } else {
      lastWindow.disableLandscapeMultiWindow()
    }
  }
}
