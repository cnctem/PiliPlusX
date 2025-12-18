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
    this.channel.setMethodCallHandler(this);
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
    switch (call.method) {
      case 'setMiniWindowLandscape': {
        const landscape: boolean = call.argument('landscape') ?? false;
        await this.setMiniWindowLandscape(landscape);
        result.success(true);
        break;
      }
      case 'set': {
        const orientation: string | null = call.argument('orientation');
        const fullscreen: boolean = call.argument('fullscreen') ?? false;
        await this.applyOrientation(orientation, fullscreen);
        result.success(true);
        break;
      }
      case 'reset': {
        const orientation: string | null = call.argument('orientation');
        await this.applyOrientation(orientation, false);
        result.success(true);
        break;
      }
      default: {
        result.notImplemented();
      }
    }
  }

  private async setMiniWindowLandscape(landscape: boolean) {
    const lastWindow = await window.getLastWindow(this.context!);
    if (landscape) {
      lastWindow.enableLandscapeMultiWindow();
    } else {
      lastWindow.disableLandscapeMultiWindow();
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
