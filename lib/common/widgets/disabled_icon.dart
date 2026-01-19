import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DisabledIcon<T extends Widget> extends SingleChildRenderObjectWidget {
  const DisabledIcon({
    super.key,
    required T child,
    this.color,
    double? lineLengthScale,
    StrokeCap? strokeCap,
  }) : lineLengthScale = lineLengthScale ?? 0.9,
       strokeCap = strokeCap ?? StrokeCap.butt,
       super(child: child);

  final Color? color;
  final StrokeCap strokeCap;
  final double lineLengthScale;

  T enable() => child as T;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMaskedIcon(
      color:
          color ??
          (child is Icon
              ? (child as Icon).color ?? IconTheme.of(context).color!
              : IconTheme.of(context).color!),
      strokeCap: strokeCap,
      lineLengthScale: lineLengthScale,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMaskedIcon renderObject) {
    renderObject
      ..color =
          color ??
          (child is Icon
              ? (child as Icon).color ?? IconTheme.of(context).color!
              : IconTheme.of(context).color!)
      ..strokeCap = strokeCap
      ..lineLengthScale = lineLengthScale;
  }
}

class RenderMaskedIcon extends RenderProxyBox {
  RenderMaskedIcon({
    required Color color,
    required StrokeCap strokeCap,
    required double lineLengthScale,
  }) : _color = color,
       _strokeCap = strokeCap,
       _lineLengthScale = lineLengthScale;

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  StrokeCap _strokeCap;
  StrokeCap get strokeCap => _strokeCap;
  set strokeCap(StrokeCap value) {
    if (_strokeCap == value) return;
    _strokeCap = value;
    markNeedsPaint();
  }

  double _lineLengthScale;
  double get lineLengthScale => _lineLengthScale;
  set lineLengthScale(double value) {
    if (_lineLengthScale == value) return;
    _lineLengthScale = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final strokeWidth = size.width / 12;

    final canvas = context.canvas;
    var rect = offset & size;

    final sqrt2Width = strokeWidth * sqrt2; // rotate pi / 4

    // final path = Path.combine(
    //   PathOperation.difference,
    //   Path()..addRect(rect),
    //   Path()..moveTo(rect.left, rect.top)
    //   ..relativeLineTo(sqrt2Width, 0)
    //   ..lineTo(rect.right, rect.bottom - sqrt2Width)
    //   ..lineTo(rect.right, rect.bottom)
    //   ..close(),
    // );

    final path = Path.combine(
      PathOperation.union,
      Path() // bottom
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + sqrt2Width)
        ..lineTo(rect.right - sqrt2Width, rect.bottom)
        ..close(),
      Path() // top
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom - sqrt2Width)
        ..lineTo(rect.left + sqrt2Width, rect.top),
    );

    canvas
      ..save()
      ..clipPath(path, doAntiAlias: false);
    super.paint(context, offset);

    canvas.restore();

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;

    final strokeOffset = strokeWidth * sqrt1_2 / 2;
    rect = rect
        .translate(-strokeOffset, strokeOffset)
        .deflate(size.width * lineLengthScale);
    canvas.drawLine(
      rect.topLeft,
      rect.bottomRight,
      linePaint,
    );
  }

  @override
  bool get isRepaintBoundary => true;
}

extension DisabledIconExt on Icon {
  DisabledIcon<Icon> disable([double? lineLengthScale]) =>
      DisabledIcon(lineLengthScale: lineLengthScale, child: this);
}
