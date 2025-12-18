import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';

export default class WindowManagerPlugin implements FlutterPlugin {
  private channel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return 'WindowManagerPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'com.piliplus/window_manager');
    // this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
  }

  flutterCallBack() {
    this.channel?.invokeMethod('flutterCallBack', null);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      default:
        result.notImplemented();
        break;
    }
  }
}
