import 'dart:io' show Platform;

import 'package:PiliPlus/harmony_adapt/harmony_channel.dart';
import 'package:PiliPlus/utils/device_utils.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart'
    show SystemChrome, MethodChannel, SystemUiOverlay, DeviceOrientation;
import 'package:os_type/os_type.dart';

/// 鸿蒙侧系统栏显隐后，安全区变化传到 Flutter（MediaQuery padding）需要数帧。
/// 退出全屏时等待该时长再旋转/切回普通布局，避免普通页 AppBar 在旋转结束后
/// 才“长高”导致整体下移一跳。
const Duration kSystemBarSettleDelay = Duration(milliseconds: 120);

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
Future<void>? showSystemBar(String reason) {
  if (_showSystemBar) {
    return null;
  }
  _showSystemBar = true;
  debugPrint('showSystemBar: $reason');
  if (OS.isHarmony) {
    return HarmonyChannel.setFullScreenBars(false);
  }
  return SystemChrome.setEnabledSystemUIMode(
    Platform.isAndroid && DeviceUtils.sdkInt < 29 ? .manual : .edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
}

/// 供路由观察器在页面回到栈底时调用：若系统栏当前被隐藏则恢复。
/// 与原生顶栏的显隐同频，避免「顶栏已先出现、状态栏要等转场结束才恢复」
/// 导致页面布局在转场结束后下移（issue #151）。
void restoreSystemBarIfHidden() {
  if (!_showSystemBar) {
    showSystemBar('observer_sync');
  }
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
