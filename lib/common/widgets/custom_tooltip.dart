import 'dart:math' as math;
import 'dart:ui' show clampDouble;

import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart'
    show
        ContainerRenderObjectMixin,
        RenderBoxContainerDefaultsMixin,
        MultiChildLayoutParentData;
import 'package:flutter/widgets.dart';

enum TooltipType { top, right }

class CustomTooltip extends StatefulWidget {
  const CustomTooltip({
    super.key,
    this.type = TooltipType.top,
    required this.overlayWidget,
    required this.child,
    required this.indicator,
  });

  final TooltipType type;
  final Widget child;
  final ValueGetter<Widget> overlayWidget;
  final ValueGetter<Widget> indicator;

  @override
  State<CustomTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip> {
  final OverlayPortalController _overlayController = OverlayPortalController();

  LongPressGestureRecognizer? _longPressRecognizer;
  LongPressGestureRecognizer get longPressRecognizer =>
      _longPressRecognizer ??= LongPressGestureRecognizer()
        ..onLongPress = _scheduleShowTooltip;

  void _scheduleShowTooltip() {
    _overlayController.show();
  }

  void _scheduleDismissTooltip() {
    _overlayController.hide();
  }

  void _handlePointerDown(PointerDownEvent event) {
    assert(mounted);
    longPressRecognizer.addPointer(event);
  }

  Widget _buildCustomTooltipOverlay(BuildContext context) {
    final OverlayState overlayState = Overlay.of(
      context,
      debugRequiredFor: widget,
    );
    final RenderBox box = this.context.findRenderObject()! as RenderBox;
    final Offset target = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: overlayState.context.findRenderObject(),
    );

    final _CustomTooltipOverlay overlayChild = _CustomTooltipOverlay(
      verticalOffset: box.size.height / 2,
      horizontalOffset: box.size.width / 2,
      type: widget.type,
      target: target,
      onDismiss: _scheduleDismissTooltip,
      overlayWidget: widget.overlayWidget,
      indicator: widget.indicator,
    );

    return SelectionContainer.maybeOf(context) == null
        ? overlayChild
        : SelectionContainer.disabled(child: overlayChild);
  }

  @protected
  @override
  void dispose() {
    _longPressRecognizer
      ?..onLongPress = null
      ..dispose();
    _longPressRecognizer = null;
    super.dispose();
  }

  @protected
  @override
  Widget build(BuildContext context) {
    Widget result;
    if (PlatformUtils.isMobile) {
      result = Listener(
        onPointerDown: _handlePointerDown,
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      );
    } else {
      result = MouseRegion(
        cursor: MouseCursor.defer,
        onEnter: (_) => _scheduleShowTooltip(),
        onExit: (_) => _scheduleDismissTooltip(),
        child: widget.child,
      );
    }
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildCustomTooltipOverlay,
      child: result,
    );
  }
}

enum _ChildType { overlay, indicator }

class _CustomTooltipOverlay extends StatelessWidget {
  const _CustomTooltipOverlay({
    required this.verticalOffset,
    required this.horizontalOffset,
    required this.type,
    required this.target,
    required this.onDismiss,
    required this.overlayWidget,
    required this.indicator,
  });

  final double verticalOffset;
  final double horizontalOffset;
  final TooltipType type;
  final Offset target;
  final VoidCallback onDismiss;
  final ValueGetter<Widget> overlayWidget;
  final ValueGetter<Widget> indicator;

  @override
  Widget build(BuildContext context) {
    return _ToolTip(
      type: type,
      target: target,
      verticalOffset: verticalOffset,
      horizontalOffset: horizontalOffset,
      preferBelow: false,
      onTap: PlatformUtils.isMobile ? onDismiss : null,
      children: [
        LayoutId(
          id: _ChildType.indicator,
          child: indicator(),
        ),
        LayoutId(
          id: _ChildType.overlay,
          child: overlayWidget(),
        ),
      ],
    );
  }
}

class _ToolTip extends MultiChildRenderObjectWidget {
  const _ToolTip({
    super.children,
    this.onTap,
    required this.type,
    required this.target,
    required this.verticalOffset,
    required this.horizontalOffset,
    required this.preferBelow,
  });

  final VoidCallback? onTap;
  final TooltipType type;
  final Offset target;
  final double verticalOffset;
  final double horizontalOffset;
  final bool preferBelow;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderToolTip(
      onTap: onTap,
      type: type,
      target: target,
      verticalOffset: verticalOffset,
      horizontalOffset: horizontalOffset,
      preferBelow: preferBelow,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderToolTip renderObject) {
    renderObject
      ..onTap = onTap
      ..target = target
      ..verticalOffset = verticalOffset
      ..horizontalOffset = horizontalOffset
      ..preferBelow = preferBelow;
  }
}

class _RenderToolTip extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderToolTip({
    VoidCallback? onTap,
    required TooltipType type,
    required Offset target,
    required double verticalOffset,
    required double horizontalOffset,
    required bool preferBelow,
  }) : _type = type,
       _target = target,
       _verticalOffset = verticalOffset,
       _horizontalOffset = horizontalOffset,
       _preferBelow = preferBelow,
       _hitTestSelf = onTap != null {
    if (onTap != null) {
      _tapGestureRecognizer = TapGestureRecognizer()..onTap = onTap;
    }
  }

  TapGestureRecognizer? _tapGestureRecognizer;

  set onTap(VoidCallback? value) {
    _tapGestureRecognizer?.onTap = value;
  }

  @override
  void dispose() {
    _tapGestureRecognizer
      ?..onTap = null
      ..dispose();
    _tapGestureRecognizer = null;
    super.dispose();
  }

  final bool _hitTestSelf;
  @override
  bool hitTestSelf(Offset position) => _hitTestSelf;

  @override
  void handleEvent(PointerEvent event, HitTestEntry<HitTestTarget> entry) {
    if (event is PointerDownEvent) {
      _tapGestureRecognizer?.addPointer(event);
    }
  }

  final TooltipType _type;

  Offset _target;
  Offset get target => _target;
  set target(Offset value) {
    if (_target == value) return;
    _target = value;
    markNeedsPaint();
  }

  double _verticalOffset;
  double get verticalOffset => _verticalOffset;
  set verticalOffset(double value) {
    if (_verticalOffset == value) return;
    _verticalOffset = value;
    markNeedsPaint();
  }

  double _horizontalOffset;
  double get horizontalOffset => _horizontalOffset;
  set horizontalOffset(double value) {
    if (_horizontalOffset == value) return;
    _horizontalOffset = value;
    markNeedsPaint();
  }

  bool _preferBelow;
  bool get preferBelow => _preferBelow;
  set preferBelow(bool value) {
    if (_preferBelow == value) return;
    _preferBelow = value;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.constrain(constraints.biggest);

    final c = BoxConstraints.loose(size);
    RenderBox indicator = firstChild!..layout(c, parentUsesSize: true);
    RenderBox overlay = lastChild!..layout(c, parentUsesSize: true);

    final indicatorSize = indicator.size;
    final overlaySize = overlay.size;

    final indicatorParentData =
        indicator.parentData as MultiChildLayoutParentData;
    final overlayParentData = overlay.parentData as MultiChildLayoutParentData;

    switch (_type) {
      case TooltipType.top:
        Offset offset = _positionDependentBox(
          type: _type,
          size: size,
          childSize: overlaySize,
          target: target,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
          preferBelow: preferBelow,
        );
        offset = Offset(offset.dx, offset.dy - indicatorSize.height + 1);
        overlayParentData.offset = offset;
        indicatorParentData.offset = Offset(
          target.dx - indicatorSize.width / 2,
          offset.dy + overlaySize.height - 1,
        );
      case TooltipType.right:
        Offset offset = _positionDependentBox(
          type: _type,
          size: size,
          childSize: overlaySize,
          target: target,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
          preferBelow: preferBelow,
        );
        offset = Offset(offset.dx + indicatorSize.height - 1, offset.dy);
        overlayParentData.offset = offset;
        Offset(
          offset.dx - indicatorSize.width + 1,
          target.dy - indicatorSize.height / 2,
        );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as MultiChildLayoutParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool get isRepaintBoundary => true;
}

class Triangle extends LeafRenderObjectWidget {
  const Triangle({
    super.key,
    required this.color,
    required this.size,
    this.type = .top,
  });

  final Color color;
  final Size size;
  final TooltipType type;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTriangle(
      color: color,
      preferredSize: size,
      type: type,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTriangle renderObject,
  ) {
    renderObject
      ..color = color
      ..preferredSize = size;
  }
}

class RenderTriangle extends RenderBox {
  RenderTriangle({
    required Color color,
    required Size preferredSize,
    required TooltipType type,
  }) : _color = color,
       _preferredSize = preferredSize,
       _type = type;

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  Size _preferredSize;
  set preferredSize(Size value) {
    if (_preferredSize == value) return;
    _preferredSize = value;
    markNeedsLayout();
  }

  final TooltipType _type;

  @override
  void performLayout() {
    size = constraints.constrain(_preferredSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final size = this.size;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path;
    switch (_type) {
      case TooltipType.top:
        path = Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close();
      case TooltipType.right:
        path = Path()
          ..moveTo(0, size.height / 2)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..close();
    }

    context.canvas.drawPath(path, paint);
  }

  @override
  bool get isRepaintBoundary => true;
}

Offset _positionDependentBox({
  required TooltipType type,
  required Size size,
  required Size childSize,
  required Offset target,
  required bool preferBelow,
  double verticalOffset = 0.0,
  double horizontalOffset = 0.0,
  double margin = 10.0,
}) {
  switch (type) {
    case TooltipType.top:
      // VERTICAL DIRECTION
      final bool fitsBelow =
          target.dy + verticalOffset + childSize.height <= size.height - margin;
      final bool fitsAbove =
          target.dy - verticalOffset - childSize.height >= margin;
      final bool tooltipBelow = fitsAbove == fitsBelow
          ? preferBelow
          : fitsBelow;
      final double y;
      if (tooltipBelow) {
        y = math.min(target.dy + verticalOffset, size.height - margin);
      } else {
        y = math.max(target.dy - verticalOffset - childSize.height, margin);
      } // HORIZONTAL DIRECTION
      final double flexibleSpace = size.width - childSize.width;
      final double x = flexibleSpace <= 2 * margin
          // If there's not enough horizontal space for margin + child, center the
          // child.
          ? flexibleSpace / 2.0
          : clampDouble(
              target.dx - childSize.width / 2,
              margin,
              flexibleSpace - margin,
            );
      return Offset(x, y);
    case TooltipType.right:
      final double dy = math.max(margin, target.dy - childSize.height / 2);
      final double dx = math.min(
        target.dx + horizontalOffset,
        size.width - childSize.width - margin,
      );
      return Offset(dx, dy);
  }
}
