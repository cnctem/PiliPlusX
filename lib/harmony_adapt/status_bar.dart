import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusBar extends ChangeNotifier {
  static final StatusBar i = StatusBar._();
  StatusBar._();

  bool hidden = false;

  void toggleHide() {
    SystemChrome.setEnabledSystemUIMode(
      hidden ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
    hidden = !hidden;
  }
}
