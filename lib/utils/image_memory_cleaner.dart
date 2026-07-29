import 'dart:async';

import 'package:flutter/widgets.dart';

/// 监听应用生命周期，进入后台后清理 Flutter 内存图片缓存
class ImageMemoryCleaner with WidgetsBindingObserver {
  ImageMemoryCleaner._internal();

  static final ImageMemoryCleaner instance = ImageMemoryCleaner._internal();

  Timer? _timer;

  void register() {
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  void clearImageCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
    } catch (_) {
      // 忽略清理过程中的异常
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 15), () {
        debugPrint('ImageMemoryCleaner: clear image cache after 15s in background');
        clearImageCache();
      });
    } else if (state == AppLifecycleState.resumed || state == AppLifecycleState.inactive) {
      _timer?.cancel();
      _timer = null;
    }
  }
}
