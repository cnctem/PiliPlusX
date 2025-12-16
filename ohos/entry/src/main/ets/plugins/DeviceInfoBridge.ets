import { MethodChannel, MethodCall, MethodResult, FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos';
import { deviceInfo } from '@kit.BasicServicesKit';

export default class DeviceInfoBridge implements FlutterPlugin {
  private channel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return 'DeviceInfoBridge';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'com.piliplus/device_info');
    this.channel.setMethodCallHandler(this.onMethodCall.bind(this));
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'DeviceType':
        result.success(deviceInfo.deviceType);
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}
