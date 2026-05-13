import 'package:PiliPlus/common/widgets/scale_app.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/services.dart';

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
}
