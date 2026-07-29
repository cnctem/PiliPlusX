import 'package:PiliPlus/harmony_adapt/harmony_channel.dart';
import 'package:flutter/material.dart';

/// 监听全局路由变化，自动控制 ArkTS HDS 底栏的显隐。
/// 路由栈深度 > 1 时（有页面覆盖在主页之上）隐藏底栏，回到栈底时恢复。
class ShellBarsObserver extends NavigatorObserver {
  final Set<Route<dynamic>> _activeRoutes = {};

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

  void _sync() {
    HarmonyChannel.setShellBarsHidden(_activeRoutes.length > 1);
  }
}
