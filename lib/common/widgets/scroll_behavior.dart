import 'dart:io' show Platform;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:os_type/os_type.dart';

const Set<PointerDeviceKind> desktopDragDevices = {
  .touch,
  .mouse,
  .trackpad,
  .stylus,
  .invertedStylus,
  .unknown,
};

class CustomScrollBehavior extends MaterialScrollBehavior {
  const CustomScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (Platform.isAndroid) {
      return StretchingOverscrollIndicator(
        axisDirection: details.direction,
        clipBehavior: details.decorationClipBehavior ?? .hardEdge,
        child: child,
      );
    }
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => desktopDragDevices;
}

class NoOverscrollIndicator extends CustomScrollBehavior {
  const NoOverscrollIndicator();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// 鸿蒙上对齐 Flutter 在 iOS 上的滚动物理
/// 补充：保证 Flutter 上列表滚动物理和鸿蒙原生界面滚动物理保持一致
/// 与 scroll_configuration.dart 中 iOS 的 _bouncingPhysics 完全一致，
/// 即 BouncingScrollPhysics + RangeMaintainingScrollPhysics。
/// 过滚动指示沿用 [CustomScrollBehavior]：ohos 上非 Platform.isAndroid，
/// 走 return child，无拉伸/发光，与 iOS 一致
class HarmonyScrollBehavior extends CustomScrollBehavior {
  const HarmonyScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (OS.isHarmony) {
      return const BouncingScrollPhysics(
        parent: RangeMaintainingScrollPhysics(),
      );
    }
    return super.getScrollPhysics(context);
  }
}
