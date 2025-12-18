import 'dart:async';
import 'dart:io';

import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

bool _isDesktopFullScreen = false;
const _harmonyOrientationChannel = MethodChannel('com.piliplus/orientation');
const _harmonyOrientationEvents = EventChannel('com.piliplus/orientation/events');

// OHOS 方向事件流（横竖信息）
Stream<Map<String, dynamic>>? _harmonyOrientationStream;

Future<bool> setHarmonyMiniWindowLandscape(bool landscape) async {
  if (!Utils.isHarmony) return false;
  final result = await _harmonyOrientationChannel.invokeMethod<bool>(
    'setMiniWindowLandscape',
    {
      'landscape': landscape,
    },
  );
  return result ?? false;
}

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
Future<void> landscape({bool forceLandscape = false}) async {
  if (Utils.isHarmony) {
    await _harmonyOrientationChannel.invokeMethod('set', {
      // 手动全屏锁定横向（90/270），自动全屏保持全向（0/90/180/270）
      'orientation': forceLandscape ? 'auto_landscape' : 'auto',
      'fullscreen': true,
    });
    return;
  }
  setHarmonyMiniWindowLandscape(true);
  if (forceLandscape) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } else {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

//竖屏
Future<void> verticalScreenForTwoSeconds({bool forcePortrait = false}) async {
  if (Utils.isHarmony) {
    // 退出时恢复全向自动，让后续竖屏半屏可自由旋转
    await _harmonyOrientationChannel.invokeMethod('set', {
      'orientation': 'auto',
      'fullscreen': false,
    });
    return;
  }
  if (forcePortrait) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    Future.delayed(const Duration(milliseconds: 500), () {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  } else {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  await autoScreen();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
}

//全向
bool allowRotateScreen = Pref.allowRotateScreen;

Future<void> autoScreen() async {
  if (!allowRotateScreen) return;

  if (Utils.isHarmony) {
    await _harmonyOrientationChannel.invokeMethod('set', {
      'orientation': 'auto',
      'fullscreen': false,
    });
    return;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    // DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

Future<void> fullAutoModeForceSensor() {
  if (Utils.isHarmony) {
    return _harmonyOrientationChannel
        .invokeMethod('set', {'orientation': 'auto', 'fullscreen': false})
        .then((_) => null);
  }
  return AutoOrientation.fullAutoMode();
}

// 订阅 Harmony 方向事件流
Stream<Map<String, dynamic>> harmonyOrientationStream() {
  _harmonyOrientationStream ??= _harmonyOrientationEvents
      .receiveBroadcastStream()
      .map((event) => Map<String, dynamic>.from(event as Map));
  return _harmonyOrientationStream!;
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
