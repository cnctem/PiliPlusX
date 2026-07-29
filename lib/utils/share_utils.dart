import 'dart:io' show Platform;

import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/rendering.dart' show Rect;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:share_plus/share_plus.dart';

abstract final class ShareUtils {
  static bool? _isIpad;
  static Future<bool> get isIpad async {
    if (!Platform.isIOS) return false;
    return _isIpad ??= (await DeviceInfoPlugin().iosInfo).model
        .toLowerCase()
        .contains('ipad');
  }

  static Future<Rect?> get sharePositionOrigin async {
    if (await isIpad) {
      final screenSize = DeviceUtils.size;
      return Rect.fromLTRB(0, 0, screenSize.width, screenSize.height / 2);
    }
    return null;
  }

  static Future<void> shareText(String text) async {
    if (PlatformUtils.isDesktop) {
      Utils.copyText(text);
      return;
    }
    try {
      // 保留 share_plus 10.x API：鸿蒙适配 fork 停留在 br_share_plus-v10.1.1_ohos
      await Share.share(
        text,
        sharePositionOrigin: await sharePositionOrigin,
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }
}
