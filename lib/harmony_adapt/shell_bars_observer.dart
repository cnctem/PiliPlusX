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
    // 回到主页时清除方向隐藏标记，由 _sync 决定最终状态
    if (_activeRoutes.length <= 1) {
      _orientationHidden = false;
    }
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _activeRoutes.remove(route);
    if (_activeRoutes.length <= 1) {
      _orientationHidden = false;
    }
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _activeRoutes.remove(oldRoute);
    if (newRoute != null) _activeRoutes.add(newRoute);
    _sync();
  }

  /// 由 didChangeDependencies 调用：横屏时隐藏底栏（仅在主页时生效）
  void onOrientationChanged(bool isPortrait) {
    if (_activeRoutes.length > 1) return; // 有子页面时由路由控制
    _orientationHidden = !isPortrait;
    _sync();
  }

  void _sync() {
    HarmonyChannel.setShellBarsHidden(
      _activeRoutes.length > 1 || _orientationHidden,
    );
  }
}
