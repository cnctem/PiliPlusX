import 'package:flutter/material.dart';

class HarmonyStatusBar extends ChangeNotifier {
  static final HarmonyStatusBar i = HarmonyStatusBar._();
  HarmonyStatusBar._();
  double _height = 0.0;

  double get height => _height;

  bool _avoidStatusBar = false;

  bool _isLandscape = false;

  Widget avoidWidget({required Widget child}) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, child) {
        return Padding(
          padding: _avoidStatusBar
              ? EdgeInsets.only(top: height)
              : EdgeInsets.zero,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 设置或许避让状态栏
  void mayBeAvoidStatusBar(bool avoidStatusBar) {
    if (_avoidStatusBar == avoidStatusBar) return;
    if (_isLandscape && avoidStatusBar) return; // 横屏不能启用避让
    notifyListeners();
    _avoidStatusBar = avoidStatusBar;
  }

  void onHeightCHange(double newHeight) {
    if (newHeight <= 0 || _height == newHeight) return;
    notifyListeners();
    _height = newHeight;
  }

  void onRotationChange(int rotation) {
    if (rotation == 1 || rotation == 3) {
      // 横屏，主动关闭避让
      mayBeAvoidStatusBar(false);
      _isLandscape = true;
    } else {
      _isLandscape = false;
    }
  }

  // 名称	值	说明
  // PORTRAIT	0	表示设备当前以竖屏方式显示。
  // LANDSCAPE	1	表示设备当前以横屏方式显示。
  // PORTRAIT_INVERTED	2	表示设备当前以反向竖屏方式显示。
  // LANDSCAPE_INVERTED	3	表示设备当前以反向横屏方式显示。
}
