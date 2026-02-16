import 'package:PiliPlus/harmony_adapt/scalable_binding.dart';
import 'package:flutter/services.dart';

abstract class HarmonyChannel {
  static final MethodChannel _channel = const MethodChannel('harmonyChannel')
    ..setMethodCallHandler(handler);

  static const _miniWindowLandscapeScale = 0.75;

  static bool _miniWindowLandscape = false;
  static bool _isFloatingWindow = false;

  static Future<void> handler(MethodCall call) async {
    switch (call.method) {
      case 'onFloatingWindowChange':
        _onFloatingWindowChange(call.arguments['isFloatingWindow']);
        break;
      // case 'onRotationChange':
      //   StatusBar.i.onRotationChange(call.arguments['rotation']);
      //   break;
      default:
        break;
    }
  }

  /// 测试用，ai生成信息请忽略这部分更改
  static Future csy(value) {
    return _channel.invokeMethod('csy', {'value': value});
  }

  /// 当进入或退出浮窗
  static void _onFloatingWindowChange(bool isFloatingWindow) {
    _isFloatingWindow = isFloatingWindow;
    if (!isFloatingWindow) {
      ScalableWidgetsFlutterBinding.ensureInitialized().setScale(1);
    } else {
      if (_miniWindowLandscape) {
        ScalableWidgetsFlutterBinding.ensureInitialized().setScale(
          _miniWindowLandscapeScale,
        );
        _channel.invokeMethod('setMiniWindowLandscape', {
          'landscape': true,
        });
      } else {
        _channel.invokeMethod('setMiniWindowLandscape', {
          'landscape': false,
        });
      }
    }
  }

  /// 设置小窗横屏
  static Future<bool> setMiniWindowLandscape(bool landscape) async {
    _miniWindowLandscape = landscape;
    if (!landscape) {
      ScalableWidgetsFlutterBinding.ensureInitialized().setScale(1);
    } else if (_isFloatingWindow) {
      ScalableWidgetsFlutterBinding.ensureInitialized().setScale(
        _miniWindowLandscapeScale,
      );
    }
    if (_isFloatingWindow) {
      final result = await _channel.invokeMethod<bool>(
        'setMiniWindowLandscape',
        {'landscape': landscape},
      );
      if (result == true) {
        return true;
      }
      return false;
    }
    return true;
  }
}
