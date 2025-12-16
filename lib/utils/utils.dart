import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:PiliPlus/common/constants.dart';
import 'package:catcher_2/catcher_2.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

abstract class Utils {
  static final random = Random();

  static const channel = MethodChannel(Constants.appName);

  @pragma("vm:platform-const")
  // Harmony 设备类型缓存（通过 MethodChannel 异步获取）
  static String? _harmonyDeviceType;

  /// 主动获取并缓存 Harmony 设备类型；在应用启动时调用一次即可。
  static Future<void> initHarmonyDeviceType() async {
    if (!isHarmony || _harmonyDeviceType != null) return;
    try {
      _harmonyDeviceType ??=
          await const MethodChannel('com.piliplus/device_info')
              .invokeMethod<String>('DeviceType');
    } catch (_) {
      // 保持 null，后续调用仍可重试。
    }
  }

  static Future<String?> get harmonyDeviceType async {
    await initHarmonyDeviceType();
    return _harmonyDeviceType;
  }

  // 基础判定：Android / iOS / Harmony 手机/平板
  static Future<bool> get isHarmonyMobile async {
    if (!isHarmony) return false;
    await initHarmonyDeviceType();
    return _harmonyDeviceType == 'phone' || _harmonyDeviceType == 'tablet';
  }

  static Future<bool> get isHarmonyDesktop async {
    if (!isHarmony) return false;
    await initHarmonyDeviceType();
    return _harmonyDeviceType == '2in1' || _harmonyDeviceType == 'pc';
  }

  // 统一移动端判定（含 Harmony 手机/平板）
  static Future<bool> get isMobileAsync async =>
      Platform.isAndroid || Platform.isIOS || await isHarmonyMobile;

  @pragma("vm:platform-const")
  static final bool isMobileBase = Platform.isAndroid || Platform.isIOS;

  // 同步移动端判定：Android/iOS 直接返回；Harmony 根据已缓存的设备类型，
  // 尚未获取到类型时默认按移动端处理，避免 UI 逻辑被阻塞。
  static bool get isMobile {
    if (Platform.isAndroid || Platform.isIOS) return true;
    if (isHarmony) {
      return _harmonyDeviceType == null ||
          _harmonyDeviceType == 'phone' ||
          _harmonyDeviceType == 'tablet';
    }
    return false;
  }

  // 桌面判定：Windows / macOS / Linux 以及 Harmony 的 2in1、pc
  static bool get isDesktop {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return true;
    if (isHarmony) {
      return _harmonyDeviceType == '2in1' || _harmonyDeviceType == 'pc';
    }
    return false;
  }

  static final bool isHarmony = Platform.operatingSystem == "ohos";

  static const jsonEncoder = JsonEncoder.withIndent('    ');

  static Future<void> saveBytes2File({
    required String name,
    required Uint8List bytes,
    required List<String> allowedExtensions,
    FileType type = FileType.custom,
  }) async {
    try {
      final path = await FilePicker.platform.saveFile(
        allowedExtensions: allowedExtensions,
        type: type,
        fileName: name,
        bytes: Utils.isDesktop ? null : bytes,
      );
      if (path == null) {
        SmartDialog.showToast("取消保存");
        return;
      }
      if (Utils.isDesktop) {
        await File(path).writeAsBytes(bytes);
      }
      SmartDialog.showToast("已保存");
    } catch (e) {
      SmartDialog.showToast("保存失败: $e");
    }
  }

  static int? safeToInt(dynamic value) => switch (value) {
    int e => e,
    String e => int.tryParse(e),
    num e => e.toInt(),
    _ => null,
  };

  static Future<bool> get isWiFi async {
    try {
      // HarmonyOS: 调用 Connectivity 可能触发权限校验；仅在 Harmony 手机/平板上才使用。
      if (Utils.isHarmony) {
        if (await Utils.isHarmonyMobile) {
          final result = await Connectivity().checkConnectivity();
          return result == ConnectivityResult.wifi;
        }
        // 桌面/2in1 直接认为有网，不做校验
        return true;
      }
      if (!Utils.isMobileBase) return false;
      final result = await Connectivity().checkConnectivity();
      return result == ConnectivityResult.wifi;
    } catch (_) {
      return true;
    }
  }

  static Color parseColor(String color) =>
      Color(int.parse(color.replaceFirst('#', 'FF'), radix: 16));

  static int? _sdkInt;
  static Future<int> get sdkInt async {
    return _sdkInt ??= (await DeviceInfoPlugin().androidInfo).version.sdkInt;
  }

  static bool? _isIpad;
  static Future<bool> get isIpad async {
    if (!Platform.isIOS) return false;
    return _isIpad ??= (await DeviceInfoPlugin().iosInfo).model
        .toLowerCase()
        .contains('ipad');
  }

  static Future<Rect?> get sharePositionOrigin async {
    if (await isIpad) {
      final size = Get.size;
      return Rect.fromLTWH(0, 0, size.width, size.height / 2);
    }
    return null;
  }

  static Future<void> shareText(String text) async {
    if (Utils.isDesktop) {
      copyText(text);
      return;
    }
    try {
      await Share.share(
        text,
        sharePositionOrigin: await sharePositionOrigin,
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  static final numericRegex = RegExp(r'^[\d\.]+$');
  static bool isStringNumeric(String str) {
    return numericRegex.hasMatch(str);
  }

  static String generateRandomString(int length) {
    const characters = '0123456789abcdefghijklmnopqrstuvwxyz';

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length)),
      ),
    );
  }

  static Future<void> copyText(
    String text, {
    bool needToast = true,
    String? toastText,
  }) {
    if (needToast) {
      SmartDialog.showToast(toastText ?? '已复制');
    }
    return Clipboard.setData(ClipboardData(text: text));
  }

  static String makeHeroTag(v) {
    return v.toString() + random.nextInt(9999).toString();
  }

  static List<int> generateRandomBytes(int minLength, int maxLength) {
    return List<int>.generate(
      minLength + random.nextInt(maxLength - minLength + 1),
      (_) => 0x26 + random.nextInt(0x59), // dm_img_str不能有`%`
    );
  }

  static String base64EncodeRandomString(int minLength, int maxLength) {
    final randomBytes = generateRandomBytes(minLength, maxLength);
    final randomBase64 = base64.encode(randomBytes);
    return randomBase64.substring(0, randomBase64.length - 2);
  }

  static String getFileName(String uri, {bool fileExt = true}) {
    final i0 = uri.lastIndexOf('/') + 1;
    final i1 = fileExt ? uri.length : uri.lastIndexOf('.');
    return uri.substring(i0, i1);
  }

  /// When calling this from a `catch` block consider annotating the method
  /// containing the `catch` block with
  /// `@pragma('vm:notify-debugger-on-exception')` to allow an attached debugger
  /// to treat the exception as unhandled.
  static void reportError(Object exception, [StackTrace? stack]) {
    Catcher2.reportCheckedError(exception, stack);
  }
}
