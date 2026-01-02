import 'package:flutter/services.dart';

abstract class HarmonyChannel {
  static const _channel = MethodChannel('harmonyChannel');

  /// 设置小窗横屏
  static Future<bool> setMiniWindowLandscape(bool landscape) async {
    final result = await _channel.invokeMethod<bool>('setMiniWindowLandscape', {
      'landscape': landscape,
    });
    return result ?? false;
  }
}
