import 'package:flutter/services.dart';

abstract class HarmonyChannel {
  static const _channel = MethodChannel('harmonyChannel');

  static Future<bool> setMiniWindowLandscape(bool landscape) async {
    final result = await _channel.invokeMethod<bool>('setMiniWindowLandscape', {
      'landscape': landscape,
    });
    return result ?? false;
  }
}
