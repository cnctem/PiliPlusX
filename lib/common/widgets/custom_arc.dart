import 'dart:math' show pi;

import 'package:flutter/widgets.dart';

class Arc extends LeafRenderObjectWidget {
  const Arc({
    super.key,
    required this.size,
    required this.color,
    required this.sweepAngle,
    this.strokeWidth = 2,
  });

  final double size;
  final Color color;
  final double sweepAngle;
  final double strokeWidth;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderArc(
      size: size,
      color: color,
      sweepAngle: sweepAngle,
      strokeWidth: strokeWidth,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderArc renderObject,
  ) {
    renderObject
      ..color = color
      ..sweepAngle = sweepAngle
      ..strokeWidth = strokeWidth;
  }
}

class RenderArc extends RenderBox {
  RenderArc({
    required double size,
    required Color color,
    required double sweepAngle,
    required double strokeWidth,
  }) : _preferredSize = Size.square(size),
       _color = color,
       _sweepAngle = sweepAngle,
       _strokeWidth = strokeWidth;

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  double _sweepAngle;
  double get sweepAngle => _sweepAngle;
  set sweepAngle(double value) {
    if (_sweepAngle == value) return;
    _sweepAngle = value;
    markNeedsPaint();
  }

  double _strokeWidth;
  double get strokeWidth => _strokeWidth;
  set strokeWidth(double value) {
    if (_strokeWidth == value) return;
    _strokeWidth = value;
    markNeedsPaint();
  }

  Size _preferredSize;
  set preferredSize(Size value) {
    if (_preferredSize == value) return;
    _preferredSize = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.constrain(_preferredSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (sweepAngle == 0) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final size = this.size;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    const startAngle = -pi / 2;

    context.canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool get isRepaintBoundary => true;
}
