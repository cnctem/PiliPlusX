import 'package:flutter/widgets.dart' show ScrollController, Curves;

extension ScrollControllerExt on ScrollController {
  void animToTop() => animTo(0);

  void animTo(
    double offset, {
    Duration duration = const Duration(milliseconds: 800),
  }) {
    if (!hasClients) return;
    final maxOffset = position.viewportDimension * 2;
    if ((offset - this.offset).abs() >= maxOffset) {
      jumpTo(maxOffset);
    }
    animateTo(
      offset,
      duration: duration,
      curve: Curves.easeOutCirc,
    );
  }

  void jumpToTop() {
    if (!hasClients) return;
    jumpTo(0);
  }
}
