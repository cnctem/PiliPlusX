import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    show ExtendedNestedScrollViewState;
import 'package:flutter/widgets.dart' show Element, Curves;

extension ExtendedNestedScrollViewStateExt on ExtendedNestedScrollViewState {
  void refresh() {
    if (mounted) {
      (context as Element).markNeedsBuild();
    }
  }

  void animToTop() {
    if (mounted) {
      final position = innerNestedPositions.first;
      final maxOffset = position.viewportDimension * 2;
      if (position.pixels >= maxOffset) {
        position.localJumpTo(maxOffset);
      }
      outerController.animateTo(
        outerController.offset,
        curve: Curves.easeOutCirc,
        duration: const Duration(milliseconds: 800),
      );
    }
  }
}
