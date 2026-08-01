import 'dart:async';
import 'dart:io' show Platform;

import 'package:PiliPlus/harmony_adapt/harmony_channel.dart';
import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart'
    show SystemChrome, MethodChannel, SystemUiOverlay, DeviceOrientation;
import 'package:os_type/os_type.dart';

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

// 全向旋转开关（鸿蒙/安卓），由播放器设置页写入
bool allowRotateScreen = Pref.allowRotateScreen;

List<DeviceOrientation>? _lastOrientation;
Future<void>? _setPreferredOrientations(List<DeviceOrientation> orientations) {
  if (_lastOrientation == orientations) {
    return null;
  }
  _lastOrientation = orientations;
  return SystemChrome.setPreferredOrientations(orientations);
}

/// 鸿蒙：让系统在「左右两个横屏方向」之间按重力自动旋转，且不受控制中心旋转锁影响。
///
/// 上游是靠 native_device_orientation 的方向监听器判断当前朝向、再指定单一方向
/// （landscapeLeft / landscapeRight）；鸿蒙没有该插件实现，若沿用上游逻辑会因拿不到
/// 朝向而恒定锁死在一个方向。这里改用原生的 AUTO_ROTATION_LANDSCAPE 交给系统判断。
Future<void>? harmonyLandscapeAutoMode() {
  _invalidateOrientationCache();
  HarmonyChannel.autoRotateLandscape();
  return null;
}

/// 鸿蒙 gravity（强制重力转屏）模式：放开四个方向交给系统按重力旋转。
Future<void> harmonyFullAutoMode() {
  _invalidateOrientationCache();
  return AutoOrientation.fullAutoMode();
}

/// 上面两个走的都是原生 window.setPreferredOrientation / auto_orientation 插件，
/// 绕过了 SystemChrome，[_lastOrientation] 不会更新。必须显式作废缓存，否则退出全屏时
/// [_setPreferredOrientations] 会误判「方向没变」而跳过，把屏幕卡在横屏。
void _invalidateOrientationCache() => _lastOrientation = null;

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
  // 鸿蒙/安卓上「全向旋转」关闭时不放开自由旋转，等价于原 autoScreen() 的行为
  if (PlatformUtils.isMobile && !allowRotateScreen) {
    return null;
  }
  final result = _setPreferredOrientations(
    const [.portraitUp, .portraitDown, .landscapeLeft, .landscapeRight],
  );
  // 实测鸿蒙上全向旋转功能需调用此方法才能和安卓效果一致
  // 背后的鸿蒙代码参考文档
  // 自动旋转方向类型 AUTO_ROTATION_UNSPECIFIED
  // 跟随传感器自动旋转，受控制中心的旋转开关控制，且可旋转方向受系统判定
  // （如在某种设备，可以旋转到竖屏、横屏、反向横屏三个方向，无法旋转到反向竖屏）。
  if (OS.isHarmony) {
    AutoOrientation.setScreenOrientationUser();
  }
  return result;
}

bool _showSystemBar = true;
bool get showSystemBar_ => _showSystemBar;
Future<void>? hideSystemBar() {
  if (!_showSystemBar) {
    return null;
  }
  _showSystemBar = false;
  return SystemChrome.setEnabledSystemUIMode(.immersiveSticky);
}

//退出全屏显示
Future<void>? showSystemBar(String reason) {
  if (_showSystemBar) {
    return null;
  }
  _showSystemBar = true;
  debugPrint('showSystemBar: $reason');
  return SystemChrome.setEnabledSystemUIMode(
    Platform.isAndroid && DeviceUtils.sdkInt < 29 ? .manual : .edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
}

Future<void> toggleSystemBar() {
  _showSystemBar = !_showSystemBar;
  return SystemChrome.setEnabledSystemUIMode(
    _showSystemBar ? .edgeToEdge : .immersiveSticky,
  );
}
