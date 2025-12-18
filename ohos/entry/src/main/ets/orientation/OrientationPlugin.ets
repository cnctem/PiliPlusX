import {
  AbilityAware,
  AbilityPluginBinding,
  EventChannel,
  EventSink,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler,
} from '@ohos/flutter_ohos';
import { window, display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

// 方向控制与方向事件上报插件（Harmony 专用）
interface WinSize {
  width: number;
  height: number;
}

export default class OrientationPlugin
  implements FlutterPlugin, MethodCallHandler, AbilityAware, StreamHandler {
  private channel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private sink: EventSink | null = null;
  private context: common.UIAbilityContext | null = null;
  private listenerRegistered = false;
  private displayCallback: ((displayId: number) => void) | null = null;
  private windowCallback: ((size: WinSize) => void) | null = null;

  getUniqueClassName(): string {
    return 'OrientationPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    // MethodChannel：方向/全屏设置
    this.channel = new MethodChannel(
      binding.getBinaryMessenger(),
      'com.piliplus/orientation',
    );
    this.channel.setMethodCallHandler(this);

    // EventChannel：推送方向变化
    this.eventChannel = new EventChannel(
      binding.getBinaryMessenger(),
      'com.piliplus/orientation/events',
    );
    this.eventChannel.setStreamHandler(this);
  }

  onDetachedFromEngine(_: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.eventChannel?.setStreamHandler(null);
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    /* no-op */
  }

  // -------------------- MethodChannel --------------------
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
        // 旧参数保留：锁定横屏
        target = window.Orientation.LANDSCAPE;
        break;
      case 'auto_landscape':
        // 仅允许横向，但跟随传感器（支持两个横向朝向），便于监听旋转事件
        target = window.Orientation.AUTO_ROTATION_LANDSCAPE;
        break;
      case 'auto':
      default:
        // 传感器自动旋转。UNSPECIFIED 有时不会触发窗口宽高变化，这里强制用 AUTO_ROTATION。
        target = window.Orientation.AUTO_ROTATION;
        break;
    }
    lastWindow.setPreferredOrientation(target);
  }

  // -------------------- EventChannel --------------------
  onListen(arguments_: Object | null, sink: EventSink): void {
    this.sink = sink;
    if (this.listenerRegistered) return;

    // 监听系统 display 变化，回调参数为 displayId
    this.displayCallback = (displayId: number) => {
      try {
        const disp: display.Display = display.getDisplayByIdSync(displayId);
        const rotation: number = disp.rotation;
        const orientation: string =
          rotation % 2 === 1 ? 'landscape' : 'portrait';
        this.sink?.success({ orientation: orientation, rotation: rotation });
      } catch (e) {
        // ignore
      }
    };
    display.on('change', this.displayCallback);

    // 同时监听窗口尺寸变化，按宽高比推送一次（部分机型 rotation 事件缺失时兜底）
    window.getLastWindow(this.context!).then((win) => {
      this.windowCallback = (size: WinSize) => {
        const orientation =
          size.width > size.height ? 'landscape' : 'portrait';
        this.sink?.success({
          orientation: orientation,
          rotation: orientation === 'landscape' ? 1 : 0,
        });
      };
      win.on('windowSizeChange', this.windowCallback);
    });

    // 立即推送一次当前方向（默认 display）
    try {
      const disp: display.Display = display.getDefaultDisplaySync();
      const rotation: number = disp.rotation;
      const orientation: string =
        rotation % 2 === 1 ? 'landscape' : 'portrait';
      this.sink?.success({ orientation: orientation, rotation: rotation });
    } catch (_) {}
    this.listenerRegistered = true;
  }

  onCancel(arguments_: Object | null): void {
    if (this.listenerRegistered && this.displayCallback) {
      display.off('change', this.displayCallback);
    }
    if (this.listenerRegistered && this.windowCallback) {
      window.getLastWindow(this.context!).then((win) => {
        win.off('windowSizeChange', this.windowCallback!);
      });
    }
    this.displayCallback = null;
    this.windowCallback = null;
    this.listenerRegistered = false;
    this.sink = null;
  }
}
