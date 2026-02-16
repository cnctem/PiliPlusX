import 'dart:async';
import 'dart:io';

import 'package:PiliPlus/harmony_adapt/harmony_channel.dart';
import 'package:PiliPlus/harmony_adapt/status_bar.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
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
    // 鸿蒙将小窗设为横屏
    if (PlatformUtils.isHarmony) HarmonyChannel.setMiniWindowLandscape(true);
    await AutoOrientation.landscapeAutoMode(forceSensor: true);
  } catch (e) {
    print('横屏时出错：$e');
  }
}

//竖屏
Future<void> verticalScreenForTwoSeconds() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await autoScreen();
}

//全向
bool allowRotateScreen = Pref.allowRotateScreen;
Future<void> autoScreen() async {
  if (PlatformUtils.isMobile && allowRotateScreen) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      // DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 实测鸿蒙上全向旋转功能需调用此方法才能和安卓效果一致
    // 背后的鸿蒙代码参考文档
    // 自动旋转方向类型 AUTO_ROTATION_UNSPECIFIED
    // 跟随传感器自动旋转，受控制中心的旋转开关控制，且可旋转方向受系统判定
    // （如在某种设备，可以旋转到竖屏、横屏、反向横屏三个方向，无法旋转到反向竖屏）。
    if (PlatformUtils.isHarmony) await AutoOrientation.setScreenOrientationUser();
  }
}

Future<void> fullAutoModeForceSensor() {
  // 鸿蒙的AutoOrientation插件没有上游版本的forceSensor参数
  return AutoOrientation.fullAutoMode();
  // return AutoOrientation.fullAutoMode(forceSensor: true);
}

bool _showStatusBar = true;
Future<void> hideStatusBar() async {
  _showStatusBar = false;
  StatusBar.i.hidden = true;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

Future<void> hideStatusBarKeepNav() async {
  _showStatusBar = false;
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.bottom],
  );
}

//退出全屏显示
Future<void> showStatusBar() async {
  _showStatusBar = true;
  StatusBar.i.hidden = false;
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
