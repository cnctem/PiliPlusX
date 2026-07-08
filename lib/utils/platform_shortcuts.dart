import 'dart:io';

import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

bool get isPrimaryModifierPressed {
  switch (defaultTargetPlatform) {
    case TargetPlatform.macOS:
      return HardwareKeyboard.instance.isMetaPressed;
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return HardwareKeyboard.instance.isControlPressed;
  }
}

class ShortcutHandler {
  static KeyEventResult? handleQuitKey(KeyEvent event) {
    if (!Pref.keyboardControl) return null;
    if (event is! KeyDownEvent) return null;
    if (event.logicalKey != LogicalKeyboardKey.keyQ) return null;
    if (Platform.isMacOS && HardwareKeyboard.instance.isMetaPressed) {
      exit(0);
    }
    return null;
  }

  static KeyEventResult? handleRefreshKey(KeyEvent event) {
    if (!Pref.keyboardControl) return null;
    if (event is! KeyDownEvent) return null;
    if (event.logicalKey != LogicalKeyboardKey.keyR) return null;
    if (!isPrimaryModifierPressed) return null;
    if (HardwareKeyboard.instance.isShiftPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return null;
    }
    handleRefreshShortcut();
    return KeyEventResult.handled;
  }

  static KeyEventResult? handleSettingsKey(KeyEvent event) {
    if (!Pref.keyboardControl) return null;
    if (event is! KeyDownEvent) return null;
    if (event.logicalKey != LogicalKeyboardKey.comma) return null;
    if (!isPrimaryModifierPressed) return null;
    if (HardwareKeyboard.instance.isShiftPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return null;
    }
    handleSettingsShortcut();
    return KeyEventResult.handled;
  }

  static void handleRefreshShortcut() {
    final currentController = _getCurrentPageController();
    if (currentController is ScrollOrRefreshMixin) {
      currentController.onRefresh();
    }
  }

  static dynamic _getCurrentPageController() {
    try {
      final mainController = Get.find<MainController>();
      final currentIndex = mainController.selectedIndex.value;
      if (mainController.navigationBars[currentIndex] ==
          NavigationBarType.home) {
        return Get.find<HomeController>().controller;
      } else if (mainController.navigationBars[currentIndex] ==
          NavigationBarType.dynamics) {
        return Get.find<DynamicsController>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static KeyEventResult? handleHomeShortcut(KeyEvent event) {
    if (!Pref.keyboardControl) return null;
    if (event is! KeyDownEvent) return null;
    if (event.logicalKey != LogicalKeyboardKey.keyH) return null;
    if (!HardwareKeyboard.instance.isAltPressed) return null;
    if (HardwareKeyboard.instance.isShiftPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      return null;
    }
    handleHomeShortcutAction();
    return KeyEventResult.handled;
  }

  static void handleHomeShortcutAction() {
    final plCtr = PlPlayerController.instance;
    if (plCtr != null) {
      plCtr
        ..isCloseAll = true
        ..dispose();
    }
    Get.until((route) => route.isFirst);
  }

  static void handleSettingsShortcut() {
    Get.toNamed('/setting', preventDuplicates: false);
  }
}
