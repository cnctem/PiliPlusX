import 'package:PiliPlus/harmony_adapt/harmony_channel.dart';
import 'package:flutter/material.dart';

/// 监听全局路由变化，自动控制 ArkTS HDS 底栏的显隐。
/// 路由栈深度 > 1 时（有页面覆盖在主页之上）隐藏底栏，回到栈底时恢复。
class ShellBarsObserver extends NavigatorObserver {
  final Set<Route<dynamic>> _activeRoutes = {};
  bool _orientationHidden = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _activeRoutes.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _activeRoutes.remove(route);
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _activeRoutes.remove(route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _activeRoutes.remove(oldRoute);
    if (newRoute != null) _activeRoutes.add(newRoute);
    _sync();
  }

  /// 由 MainApp.didChangeDependencies 调用：非竖屏底栏布局（横屏侧栏）时隐藏底栏。
  /// 子页面覆盖期间也照常记录，避免返回主页后用的是过期方向。
  void onOrientationChanged(bool useBottomNav) {
    _orientationHidden = !useBottomNav;
    _sync();
  }

  void _sync() {
    // 底栏隐藏条件：页面覆盖（无弹层）或弹层覆盖（PopupRoute 计入）或横屏。
    // 底栏 + 顶栏宽高比分流共用此信号：dialog/bottomSheet/popupmenu 弹出时
    // 也触发，顶栏按「首页 + 宽高比」由 ArkTS syncTopBarVisibility 收起/隐藏。
    final hasOverlay = _activeRoutes.length > 1 || _orientationHidden;
    HarmonyChannel.setShellBarsHidden(hasOverlay);
    // 顶栏「强制隐藏」仅针对页面覆盖（PageRoute：如视频页/设置页）与横屏；
    // 弹层（PopupRoute：dialog/bottomSheet/popupmenu）不计入，避免顶栏被
    // 直接隐藏而绕过宽高比分流。
    final hasPageOverlay = _activeRoutes.whereType<PageRoute>().length > 1;
    HarmonyChannel.setTopBarHidden(hasPageOverlay || _orientationHidden);
  }
}
