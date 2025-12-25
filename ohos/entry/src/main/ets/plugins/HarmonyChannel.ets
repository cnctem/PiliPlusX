import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult } from "@ohos/flutter_ohos";
import deviceInfo from "@ohos.deviceInfo";

export default class HarmonyChannel implements FlutterPlugin {
  private channel: MethodChannel | null = null;

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

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      default:
        result.notImplemented();
        break;
    }
  }
}
