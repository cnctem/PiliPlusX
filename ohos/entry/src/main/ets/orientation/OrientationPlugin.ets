import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

// 简单方向/全屏控制插件，仅用于 OHOS 自定义播放器控制层
export default class OrientationPlugin
  implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;

  getUniqueClassName(): string {
    return 'OrientationPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(
      binding.getBinaryMessenger(),
      'com.piliplus/orientation',
    );
    // 必须绑定到具体函数，否则 MethodChannel 收到调用时会报 “undefined is not callable”
    this.channel.setMethodCallHandler(this.onMethodCall.bind(this));
  }

  onDetachedFromEngine(_: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    /* no-op */
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    if (!this.context) {
      result.error('NO_CONTEXT', 'UIAbilityContext is null', null);
      return;
    }

    const orientation: string | null = call.argument('orientation');
    const fullscreen: boolean = call.argument('fullscreen') ?? false;

    switch (call.method) {
      case 'set': {
        await this.applyOrientation(orientation, fullscreen);
        result.success(null);
        break;
      }
      case 'reset': {
        await this.applyOrientation(orientation, false);
        result.success(null);
        break;
      }
      default: {
        result.notImplemented();
      }
    }
  }

  private async applyOrientation(
    orientation: string | null,
    fullscreen: boolean,
  ): Promise<void> {
    const lastWindow = await window.getLastWindow(this.context!);

    // System bar
    if (fullscreen) {
      lastWindow.setWindowSystemBarEnable([]);
      lastWindow.enableLandscapeMultiWindow();
    } else {
      lastWindow.setWindowSystemBarEnable(['status']);
      lastWindow.disableLandscapeMultiWindow();
    }

    // Orientation
    let target = window.Orientation.UNSPECIFIED;
    switch (orientation) {
      case 'portrait':
        target = window.Orientation.PORTRAIT;
        break;
      case 'landscape':
        target = window.Orientation.LANDSCAPE;
        break;
      case 'auto':
      default:
        target = window.Orientation.UNSPECIFIED;
        break;
    }
    lastWindow.setPreferredOrientation(target);
  }
}
