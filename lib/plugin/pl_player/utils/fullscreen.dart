import 'dart:async';
import 'dart:io';

import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/services.dart';

bool _isDesktopFullScreen = false;
const _orientationChannel = MethodChannel('com.piliplus/orientation');

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
  if (Utils.isHarmony) {
    try {
      await _orientationChannel.invokeMethod<void>('set', {
        'orientation': 'landscape',
        'fullscreen': true,
      });
    } catch (_) {}
    return;
  }

  try {
    await AutoOrientation.landscapeAutoMode(forceSensor: true);
  } catch (_) {}
}

//竖屏
Future<void> verticalScreenForTwoSeconds() async {
  if (Utils.isHarmony) {
    try {
      await _orientationChannel.invokeMethod<void>('set', {
        'orientation': 'portrait',
        'fullscreen': false,
      });
    } catch (_) {}
    await autoScreen();
    return;
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await autoScreen();
}

//全向
bool allowRotateScreen = Pref.allowRotateScreen;
Future<void> autoScreen() async {
  if (!allowRotateScreen) return;

  if (Utils.isHarmony) {
    try {
      await _orientationChannel.invokeMethod<void>('set', {
        'orientation': 'auto',
        'fullscreen': false,
      });
    } catch (_) {}
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
  if (Utils.isHarmony) {
    return _orientationChannel.invokeMethod('set', {
      'orientation': 'auto',
      'fullscreen': true,
    });
  }
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
