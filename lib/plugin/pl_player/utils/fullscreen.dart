import 'dart:async';
import 'dart:io';

import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/services.dart';

bool _isDesktopFullScreen = false;

@pragma('vm:notify-debugger-on-exception')
Future<void> enterDesktopFullscreen({bool inAppFullScreen = false}) async {
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
Future<void> exitDesktopFullscreen() async {
  if (_isDesktopFullScreen) {
    _isDesktopFullScreen = false;
    try {
      await const MethodChannel(
        'com.alexmercerind/media_kit_video',
      ).invokeMethod('Utils.ExitNativeFullscreen');
    } catch (_) {}
  }
}

//横屏
@pragma('vm:notify-debugger-on-exception')
Future<void> landscape() async {
  try {
    await AutoOrientation.landscapeAutoMode(forceSensor: true);
  } catch (_) {}
}

//竖屏
Future<void> verticalScreenForTwoSeconds() async {
  if (Utils.isHarmony) {
    if (await Utils.isHarmonyMobile) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      // Harmony 平板/2in1 直接恢复系统自动旋转
      await SystemChrome.setPreferredOrientations([]);
    }
  } else {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  await autoScreen();
}

//全向
bool allowRotateScreen = Pref.allowRotateScreen;
Future<void> autoScreen() async {
  if (!allowRotateScreen) return;

  if (Utils.isHarmony) {
    if (await Utils.isHarmonyMobile) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Harmony 平板/2in1 恢复系统默认（不限制方向）
      await SystemChrome.setPreferredOrientations([]);
    }
    return;
  }

  if (Utils.isMobile) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      // DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

Future<void> fullAutoModeForceSensor() {
  return AutoOrientation.fullAutoMode();
}

bool _showStatusBar = true;
Future<void> hideStatusBar() async {
  if (!_showStatusBar) {
    return;
  }
  _showStatusBar = false;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

//退出全屏显示
Future<void> showStatusBar() async {
  if (_showStatusBar) {
    return;
  }
  _showStatusBar = true;
  SystemUiMode mode;
  if (Platform.isAndroid && (await Utils.sdkInt < 29)) {
    mode = SystemUiMode.manual;
  } else {
    mode = SystemUiMode.edgeToEdge;
  }
  await SystemChrome.setEnabledSystemUIMode(
    mode,
    overlays: SystemUiOverlay.values,
  );
}
