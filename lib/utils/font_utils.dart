/// 鸿蒙分支差异（上游原文见 4ca037345 `feat: font setting page`）：
///
/// - **安卓分支已摘除**：上游走 JNI 调 `AndroidHelper.fontFamilies()`，而本分支没有
///   `jni` 依赖、`lib/utils/android/bindings.g.dart` 是手写的空实现存根。
/// - **Windows 分支已摘除**：上游用 `win32` 6.4.0 的 API（`GetDC(null)`、
///   `LPARAM(0)` 等），而本分支 `dependency_overrides` 把 win32 钉在 5.5.3
///   （鸿蒙化的插件链要求），两者 API 不兼容。哪天 win32 的 override 放开了，
///   把上游那段 `_initWindows()` / `_enumFontCallback()` 抄回来即可。
/// - Linux 的 fontconfig 分支是纯 `dart:ffi`，原样保留。
///
/// 鸿蒙本身也还没有枚举系统字体的通道，[FontUtils.getFont] 在 ohos 上返回空集合——
/// 设置页的字体下拉框因此不会出现（`font_setting.dart` 里有 `_fonts.isNotEmpty`
/// 守卫），只剩字重和字号可调。将来若接了 ArkTS 侧的字体枚举，在这里补一条
/// `_initHarmony()` 即可。
library;

import 'dart:ffi';
import 'dart:io';

import 'package:PiliPlus/utils/fontconfig.g.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

abstract final class FontUtils {
  static final _fonts = <String>{};
  static bool _initialized = false;

  static Set<String> getFont() {
    if (_initialized) return _fonts;
    _initialized = true;
    // 只有真正实现了枚举的平台才在失败时提示。ohos / 安卓 / Windows / ios / macos
    // 在本分支没有实现（原因见文件头），静默返回空集合即可，弹「加载失败」只会
    // 误导用户——`font_setting.dart` 里有 `_fonts.isNotEmpty` 守卫，字体下拉框
    // 自己就不会出现。
    if (Platform.isLinux && !_initLinux()) {
      SmartDialog.showToast('加载系统字体失败');
    }
    return _fonts;
  }

  @pragma('vm:prefer-inline')
  static bool _initLinux() {
    final FontConfig fc;
    try {
      fc = FontConfig(DynamicLibrary.open('libfontconfig.so.1'));
    } catch (e) {
      if (kDebugMode) debugPrint('无法加载 Fontconfig 库: $e');
      return false;
    }

    final config = fc.FcInitLoadConfigAndFonts();
    if (config == nullptr) {
      if (kDebugMode) debugPrint('Fontconfig 初始化失败');
      return false;
    }

    final fontSet = fc.FcConfigGetFonts(config, FcSetName.FcSetSystem);
    if (fontSet == nullptr) {
      if (kDebugMode) debugPrint('无法获取系统字体集');
      fc.FcConfigDestroy(config);
      return false;
    }

    final nfont = fontSet.ref.nfont;
    final family = FC_FAMILY.toNativeUtf8().cast<Char>();
    for (int i = 0; i < nfont; i++) {
      final pattern = fontSet.ref.fonts[i];
      if (pattern == nullptr) continue;

      final outPtr = calloc<Pointer<UnsignedChar>>();

      try {
        final result = fc.FcPatternGetString(pattern, family, 0, outPtr);

        if (result == 0) {
          final strPtr = outPtr.value;
          if (strPtr != nullptr) {
            _fonts.add(strPtr.cast<Utf8>().toDartString());
          }
        }
      } finally {
        calloc.free(outPtr);
      }
    }
    calloc.free(family);
    fc.FcConfigDestroy(config);

    return true;
  }
}
