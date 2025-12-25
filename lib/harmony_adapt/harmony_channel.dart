import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class HarmonyChannel {
  static const _channel = MethodChannel('harmonyChannel');

  static Future<String> getDeviceType() async {
    try {
       await _channel.invokeMethod('getDeviceType');
    } catch (e) {
      debugPrint('⚠️⚠️⚠️harmonyChannel getDeviceType failed: $e');
      throw Exception('⚠️⚠️⚠️harmonyChannel getDeviceType failed: $e');
    }
    return 'null';
  }
}
