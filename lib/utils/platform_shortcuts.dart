import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// 全局工具：当前是否按下了"本平台的快捷修饰键"
bool get isPrimaryModifierPressed {
  switch (defaultTargetPlatform) {
    case TargetPlatform.macOS:                // macOS 用 ⌘
      return HardwareKeyboard.instance.isMetaPressed;
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.android:
    case TargetPlatform.iOS:                  // iPadOS 外接键盘也走这里
    case TargetPlatform.fuchsia:
      return HardwareKeyboard.instance.isControlPressed; // 其余用 Ctrl
  }
}