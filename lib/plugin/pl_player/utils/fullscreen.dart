import 'dart:io' show Platform;

import 'package:PiliPlus/harmony_adapt/harmony_channel.dart';
import 'package:PiliPlus/utils/device_utils.dart';
import 'package:flutter/services.dart'
    show SystemChrome, MethodChannel, SystemUiOverlay, DeviceOrientation;
import 'package:os_type/os_type.dart';

/// 鸿蒙侧系统栏显隐后，安全区变化传到 Flutter（MediaQuery padding）需要数帧。
/// 退出全屏时等待该时长再旋转/切回普通布局，避免普通页 AppBar 在旋转结束后
/// 才“长高”导致整体下移一跳。
const Duration kSystemBarSettleDelay = Duration(milliseconds: 120);

/// 竖屏全屏时的顶部避让高度：仅在全屏 + 竖屏 + 未移除安全边距时返回
/// [topInset]（进全屏前捕获的状态栏/挖孔高度），否则返回 null（不避让）。
/// 播控顶部组件与弹幕共用这一套判断，保证两处行为一致。
double? portraitFullscreenTopInset({
  required bool isFullScreen,
  required bool isPortrait,
  required bool removeSafeArea,
  required double? topInset,
}) {
  if (!isFullScreen || !isPortrait || removeSafeArea) return null;
  final inset = topInset ?? 0;
  return inset > 0 ? inset : null;
}

bool _isDesktopFullScreen = false;

@pragma('vm:notify-debugger-on-exception')
Future<void> enterDesktopFullScreen({bool inAppFullScreen = false}) async {
  if (!inAppFullScreen && !_isDesktopFullScreen) {
    _isDesktopFullScreen = true;
    try {
      await const MethodChannel(
        'com.alexmercerind/media_kit_video',
      ).invokeMethod('Utils.EnterNativeFullscreen');
    } catch (_) {}
  }
}

@pragma('vm:notify-debugger-on-exception')
Future<void> exitDesktopFullScreen() async {
  if (_isDesktopFullScreen) {
    _isDesktopFullScreen = false;
    try {
      await const MethodChannel(
        'com.alexmercerind/media_kit_video',
      ).invokeMethod('Utils.ExitNativeFullscreen');
    } catch (_) {}
  }
}

List<DeviceOrientation>? _lastOrientation;
Future<void>? _setPreferredOrientations(List<DeviceOrientation> orientations) {
  if (_lastOrientation == orientations) {
    return null;
  }
  _lastOrientation = orientations;
  return SystemChrome.setPreferredOrientations(orientations);
}

Future<void>? portraitUpMode() {
  return _setPreferredOrientations(const [.portraitUp]);
}

Future<void>? portraitDownMode() {
  return _setPreferredOrientations(const [.portraitDown]);
}

Future<void>? landscapeLeftMode() {
  return _setPreferredOrientations(const [.landscapeLeft]);
}

Future<void>? landscapeRightMode() {
  return _setPreferredOrientations(const [.landscapeRight]);
}

Future<void>? fullMode() {
  return _setPreferredOrientations(
    const [.portraitUp, .portraitDown, .landscapeLeft, .landscapeRight],
  );
}

/// 鸿蒙强制窗口转回竖屏（修mate80 横屏无法退出全屏bug）
Future<void>? harmonyForcePortrait() {
  if (!OS.isHarmony) return null;
  _lastOrientation = null;
  return HarmonyChannel.setWindowOrientation(1);
}

bool _showSystemBar = true;
bool get showSystemBar_ => _showSystemBar;
Future<void>? hideSystemBar() {
  if (!_showSystemBar) {
    return null;
  }
  _showSystemBar = false;
  if (OS.isHarmony) {
    // 只切换系统栏显隐，不改窗口布局，避免 Flutter 视口尺寸变化导致画面跳动。
    return HarmonyChannel.setFullScreenBars(true);
  }
  return SystemChrome.setEnabledSystemUIMode(.immersiveSticky);
}

//退出全屏显示
Future<void>? showSystemBar() {
  if (_showSystemBar) {
    return null;
  }
  _showSystemBar = true;
  if (OS.isHarmony) {
    return HarmonyChannel.setFullScreenBars(false);
  }
  return SystemChrome.setEnabledSystemUIMode(
    Platform.isAndroid && DeviceUtils.sdkInt < 29 ? .manual : .edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
}
Future<void> toggleSystemBar() {
  _showSystemBar = !_showSystemBar;
  if (OS.isHarmony) {
    return HarmonyChannel.setFullScreenBars(!_showSystemBar);
  }
  return SystemChrome.setEnabledSystemUIMode(
    _showSystemBar ? .edgeToEdge : .immersiveSticky,
  );
}