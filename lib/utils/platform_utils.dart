import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

abstract final class PlatformUtils {
  static final isHarmony = Platform.operatingSystem == "ohos";
  static late final String harmonyDeviceType;

  static Future<void> initHarmonyDeviceType() async {
    final type = (await DeviceInfoPlugin().ohosInfo).deviceType;
    if (type == null) throw Exception("Failed to init device type");
    harmonyDeviceType = type;
  }

  static final isMobile =
      Platform.isAndroid ||
      Platform.isIOS ||
      (isHarmony &&
          (harmonyDeviceType == 'phone' || harmonyDeviceType == 'tablet'));

  static final isDesktop = !isMobile;
}
