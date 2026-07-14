import 'package:PiliPlus/common/widgets/scale_app.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/services.dart';
import 'package:os_type/os_type.dart';

abstract class HarmonyChannel {
  static final MethodChannel _channel = const MethodChannel('harmonyChannel')
    ..setMethodCallHandler(handler);

  static Future<void> handler(MethodCall call) async {
    switch (call.method) {
      case 'onFloatingWindowChange':
        onLandscapeOrMiniWindowChange(null, call.arguments['isFloatingWindow']);
        break;
      default:
        break;
    }
  }

  /// 测试用，ai生成信息请忽略这部分更改
  static Future csy(value) {
    return _channel.invokeMethod('csy', {'value': value});
  }

  /// 横屏小窗的缩放比例固定值
  static const _miniWindowLandscapeScale = 0.75;
  static bool _landscape = false;
  static bool _miniWindow = false;

  /// 当前是否处于系统自由小窗（悬浮窗/全景多窗）。小窗内窗口宽高比不代表
  /// 设备方向，基于方向的自动全屏等逻辑应据此跳过。
  static bool get isMiniWindow => _miniWindow;

  /// 当方向或小窗变化
  static Future<void> onLandscapeOrMiniWindowChange(
    bool? landscape,
    bool? miniWindow,
  ) async {
    landscape ??= _landscape;
    miniWindow ??= _miniWindow;
    if (_landscape == landscape && _miniWindow == miniWindow) return;
    _landscape = landscape;
    _miniWindow = miniWindow;
    if (_miniWindow && _landscape) {
      _setMiniWindowLandscape(true);
      ScaledWidgetsFlutterBinding.instance.scaleFactor =
          _miniWindowLandscapeScale;
    } else {
      ScaledWidgetsFlutterBinding.instance.scaleFactor = Pref.uiScale;
      _setMiniWindowLandscape(false);
    }
  }

  static void _setMiniWindowLandscape(bool landscape) {
    _channel.invokeMethod('setMiniWindowLandscape', {'landscape': landscape});
  }

  static void autoRotateLandscape() {
    _channel.invokeMethod('autoRotateLandscape');
  }

  /// 自由多窗装饰栏按钮（全屏/最小化/关闭）的颜色跟随应用颜色模式而非
  /// 下方内容：浅色模式下深色按钮叠在播放页黑色顶部上视觉不可见。顶部为
  /// 深色内容的页面（视频/直播播放页）在可见期间持有此状态，使按钮切为
  /// 浅色风格；无人持有时恢复跟随系统。用持有者集合而非开关，规避
  /// 路由切换（如视频页跳视频页）中生命周期回调顺序的不确定性。
  static final Set<Object> _darkDecorOwners = <Object>{};

  static void holdDecorDark(Object owner) {
    if (!OS.isHarmony) return;
    final wasEmpty = _darkDecorOwners.isEmpty;
    _darkDecorOwners.add(owner);
    if (wasEmpty) {
      _setDecorButtonDark(true);
    }
  }

  static void releaseDecorDark(Object owner) {
    if (!OS.isHarmony) return;
    if (_darkDecorOwners.remove(owner) && _darkDecorOwners.isEmpty) {
      _setDecorButtonDark(false);
    }
  }

  static void _setDecorButtonDark(bool dark) {
    _channel.invokeMethod('setDecorButtonDark', {'dark': dark});
  }
}
