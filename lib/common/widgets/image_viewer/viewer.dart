/*
 * This file is part of PiliPlus
 *
 * PiliPlus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * PiliPlus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with PiliPlus.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:math' as math;

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/gesture/image_horizontal_drag_gesture_recognizer.dart';
import 'package:PiliPlus/common/widgets/gesture/image_tap_gesture_recognizer.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' show FrictionSimulation;
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart'
    show GetNavigation;

///
/// created by dom on 2026/02/14
///

class Viewer extends StatefulWidget {
  const Viewer({
    super.key,
    required this.minScale,
    required this.maxScale,
    required this.containerSize,
    required this.childSize,
    required this.isAnimating,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.tapGestureRecognizer,
    required this.horizontalDragGestureRecognizer,
    required this.onChangePage,
    required this.child,
  });

  final double minScale;
  final double maxScale;
  final Size containerSize;
  final Size childSize;
  final Widget child;

  final ValueGetter<bool> isAnimating;
  final ValueChanged<ScaleStartDetails>? onDragStart;
  final ValueChanged<ScaleUpdateDetails>? onDragUpdate;
  final ValueChanged<ScaleEndDetails>? onDragEnd;
  final ValueChanged<int>? onChangePage;

  final ImageTapGestureRecognizer tapGestureRecognizer;
  final ImageHorizontalDragGestureRecognizer horizontalDragGestureRecognizer;

  @override
  State<StatefulWidget> createState() => _ViewerState();
}

class _ViewerState extends State<Viewer> with SingleTickerProviderStateMixin {
  static const double _interactionEndFrictionCoefficient = 0.0001; // 0.0000135
  static const double _scaleFactor = kDefaultMouseScrollToScaleFactor;

  _GestureType? _gestureType;

  late double _scale;
  double? _scaleStart;
  late Offset _position;
  Offset? _referenceFocalPoint;

  late Size _imageSize;

  late final ImageTapGestureRecognizer _tapGestureRecognizer;
  late final ImageHorizontalDragGestureRecognizer
  _horizontalDragGestureRecognizer;
  late final ScaleGestureRecognizer _scaleGestureRecognizer;
  late final DoubleTapGestureRecognizer _doubleTapGestureRecognizer;

  Offset? _downPos;
  AnimationController? _animationController;
  AnimationController get _effectiveAnimationController =>
      _animationController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      )..addListener(_listener);
  late final _tween = Matrix4Tween();
  late final _animatable = _tween.chain(CurveTween(curve: Curves.easeOut));

  void _listener() {
    final storage = _animatable.evaluate(_effectiveAnimationController);
    _scale = storage[0];
    _position = Offset(storage[12], storage[13]);
    setState(() {});
  }

  void _reset() {
    _scale = 1.0;
    _position = .zero;
  }

  void _initSize() {
    _reset();
    _imageSize = applyBoxFit(
      .scaleDown,
      widget.childSize,
      widget.containerSize,
    ).destination;
    // if (_imageSize.height / _imageSize.width > StyleString.imgMaxRatio) {
    //   _imageSize = applyBoxFit(
    //     .fitWidth,
    //     widget.childSize,
    //     widget.containerSize,
    //   ).destination;
    // final containerWidth = widget.containerSize.width;
    // final containerHeight = widget.containerSize.height;
    // _scale = containerWidth / _imageSize.width;
    // final imageHeight = _imageSize.height * _scale;
    // _position = Offset(
    //   (1 - _scale) * containerWidth / 2,
    //   (imageHeight - _scale * containerHeight) / 2,
    // );
    // }
  }

  @override
  void initState() {
    super.initState();
    _initSize();

    _tapGestureRecognizer = widget.tapGestureRecognizer;
    _horizontalDragGestureRecognizer = widget.horizontalDragGestureRecognizer;

    final gestureSettings = MediaQuery.maybeGestureSettingsOf(Get.context!);
    _scaleGestureRecognizer = ScaleGestureRecognizer(debugOwner: this)
      ..dragStartBehavior = .start
      ..onStart = _onScaleStart
      ..onUpdate = _onScaleUpdate
      ..onEnd = _onScaleEnd
      ..gestureSettings = gestureSettings;
    _doubleTapGestureRecognizer = DoubleTapGestureRecognizer(debugOwner: this)
      ..onDoubleTapDown = _onDoubleTapDown
      ..onDoubleTap = _onDoubleTap
      ..gestureSettings = gestureSettings;
  }

  @override
  void didUpdateWidget(Viewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.containerSize != widget.containerSize ||
        oldWidget.childSize != widget.childSize) {
      _initSize();
    }
  }

  @override
  void dispose() {
    _animationController
      ?..removeListener(_listener)
      ..dispose();
    _animationController = null;
    _scaleGestureRecognizer.dispose();
    _doubleTapGestureRecognizer.dispose();
    super.dispose();
  }

  Offset _toScene(Offset localFocalPoint) {
    return (localFocalPoint - _position) / _scale;
  }

  Offset _clampPosition(Offset offset, double scale) {
    final containerSize = widget.containerSize;
    final containerWidth = containerSize.width;
    final containerHeight = containerSize.height;
    final imageWidth = _imageSize.width * scale;
    final imageHeight = _imageSize.height * scale;

    final dx = (1 - scale) * containerWidth / 2;
    final dxOffset = (imageWidth - containerWidth) / 2;

    final dy = (1 - scale) * containerHeight / 2;
    final dyOffset = (imageHeight - containerHeight) / 2;

    return Offset(
      imageWidth > containerWidth
          ? clampDouble(offset.dx, dx - dxOffset, dx + dxOffset)
          : dx,
      imageHeight > containerHeight
          ? clampDouble(offset.dy, dy - dyOffset, dy + dyOffset)
          : dy,
    );
  }

  Offset _matrixTranslate(Offset translation) {
    if (translation == .zero) {
      return _position;
    }
    return _clampPosition(_position + translation * _scale, _scale);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _downPos = details.localPosition;
  }

  void _onDoubleTap() {
    EasyThrottle.throttle(
      'VIEWER_TAP',
      const Duration(milliseconds: 555),
      _handleDoubleTap,
    );
  }

  void _handleDoubleTap() {
    final Matrix4 begin;
    final Matrix4 end;
    if (_scale == 1.0) {
      final imageWidth = _imageSize.width;
      final imageHeight = _imageSize.height;
      final isLongPic = imageHeight / imageWidth >= StyleString.imgMaxRatio;
      double scale = widget.maxScale * 0.6;
      if (isLongPic) {
        scale = widget.containerSize.width / _imageSize.width;
      } else {
        scale = widget.maxScale * 0.6;
      }
      if (scale <= widget.minScale) {
        scale = widget.maxScale;
      }
      begin = Matrix4.identity();
      final position = _clampPosition(_downPos! * (1 - scale), scale);
      end = Matrix4.identity()
        ..translateByDouble(position.dx, position.dy, 0.0, 1.0)
        ..scaleByDouble(scale, scale, scale, 1.0);
    } else {
      begin = Matrix4.identity()
        ..translateByDouble(_position.dx, _position.dy, 0.0, 1.0)
        ..scaleByDouble(_scale, _scale, _scale, 1.0);
      end = Matrix4.identity();
    }
    _tween
      ..begin = begin
      ..end = end;
    _effectiveAnimationController
      ..duration = const Duration(milliseconds: 300)
      ..forward(from: 0);
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (widget.isAnimating() || (details.pointerCount < 2 && _scale == 1.0)) {
      widget.onDragStart?.call(details);
      return;
    }

    _scaleStart = _scale;
    _referenceFocalPoint = _toScene(details.localFocalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (widget.isAnimating() || (details.pointerCount < 2 && _scale == 1.0)) {
      widget.onDragUpdate?.call(details);
      return;
    }

    if (details.scale != 1.0) {
      _gestureType = .scale;
      _scale = clampDouble(
        _scaleStart! * details.scale,
        widget.minScale,
        widget.maxScale,
      );

      final Offset focalPointSceneScaled = _toScene(details.localFocalPoint);
      _position = _matrixTranslate(
        focalPointSceneScaled - _referenceFocalPoint!,
      );
      setState(() {});
    } else {
      _gestureType = .pan;
      final Offset focalPointScene = _toScene(details.localFocalPoint);
      final Offset translationChange = focalPointScene - _referenceFocalPoint!;
      _position = _matrixTranslate(translationChange);
      _referenceFocalPoint = _toScene(details.localFocalPoint);
      setState(() {});
    }
  }

  /// ref [InteractiveViewer]
  void _onScaleEnd(ScaleEndDetails details) {
    if (widget.isAnimating() || (details.pointerCount < 2 && _scale == 1.0)) {
      widget.onDragEnd?.call(details);
      return;
    }

    switch (_gestureType) {
      case _GestureType.pan:
        if (details.velocity.pixelsPerSecond.distance < kMinFlingVelocity) {
          return;
        }
        final FrictionSimulation frictionSimulationX = FrictionSimulation(
          _interactionEndFrictionCoefficient,
          _position.dx,
          details.velocity.pixelsPerSecond.dx,
        );
        final FrictionSimulation frictionSimulationY = FrictionSimulation(
          _interactionEndFrictionCoefficient,
          _position.dy,
          details.velocity.pixelsPerSecond.dy,
        );
        final double tFinal = _getFinalTime(
          details.velocity.pixelsPerSecond.distance,
          _interactionEndFrictionCoefficient,
        );
        final position = _clampPosition(
          Offset(frictionSimulationX.finalX, frictionSimulationY.finalX),
          _scale,
        );
        _tween
          ..begin = (Matrix4.identity()
            ..translateByDouble(_position.dx, _position.dy, 0.0, 1.0)
            ..scaleByDouble(_scale, _scale, _scale, 1.0))
          ..end = (Matrix4.identity()
            ..translateByDouble(position.dx, position.dy, 0.0, 1.0)
            ..scaleByDouble(_scale, _scale, _scale, 1.0));
        _effectiveAnimationController
          ..duration = Duration(milliseconds: (tFinal * 1000).round())
          ..forward(from: 0);
      case _GestureType.scale:
      // if (details.scaleVelocity.abs() < 0.1) {
      //   return;
      // }
      // final double scale = _scale;
      // final FrictionSimulation frictionSimulation = FrictionSimulation(
      //   _interactionEndFrictionCoefficient * _scaleFactor,
      //   scale,
      //   details.scaleVelocity / 10,
      // );
      // final double tFinal = _getFinalTime(
      //   details.scaleVelocity.abs(),
      //   _interactionEndFrictionCoefficient,
      //   effectivelyMotionless: 0.1,
      // );
      // _scaleAnimation = _scaleController.drive(
      //   Tween<double>(
      //     begin: scale,
      //     end: frictionSimulation.x(tFinal),
      //   ).chain(CurveTween(curve: Curves.decelerate)),
      // )..addListener(_handleScaleAnimation);
      // _effectiveAnimationController
      //   ..duration = Duration(milliseconds: (tFinal * 1000).round())
      //   ..forward(from: 0);
      case null:
    }
    _gestureType = null;
  }

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..translateByDouble(_position.dx, _position.dy, 0.0, 1.0)
      ..scaleByDouble(_scale, _scale, _scale, 1.0);
    return Listener(
      behavior: .opaque,
      onPointerDown: _onPointerDown,
      onPointerPanZoomStart: _onPointerPanZoomStart,
      onPointerSignal: _onPointerSignal,
      child: ClipRRect(
        child: Transform(
          transform: matrix,
          child: widget.child,
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _tapGestureRecognizer.addPointer(event);
    _doubleTapGestureRecognizer.addPointer(event);
    _horizontalDragGestureRecognizer
      ..isBoundaryAllowed = _isBoundaryAllowed
      ..addPointer(event);
    _scaleGestureRecognizer.addPointer(event);
  }

  void _onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    _scaleGestureRecognizer.addPointerPanZoom(event);
  }

  bool _isBoundaryAllowed(Offset? initialPosition, OffsetPair lastPosition) {
    if (initialPosition == null) {
      return true;
    }
    if (_scale <= 1.0) {
      return true;
    }
    final containerWidth = widget.containerSize.width;
    final imageWidth = _imageSize.width * _scale;
    if (imageWidth <= containerWidth) {
      return true;
    }
    final dx = (1 - _scale) * containerWidth / 2;
    final dxOffset = (imageWidth - containerWidth) / 2;
    if (initialPosition.dx < lastPosition.global.dx) {
      return _position.dx == dx + dxOffset;
    } else {
      return _position.dx == dx - dxOffset;
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (widget.onChangePage != null &&
          !HardwareKeyboard.instance.isControlPressed) {
        widget.onChangePage!.call(event.scrollDelta.dy < 0 ? -1 : 1);
        return;
      }
      final double scaleChange = math.exp(-event.scrollDelta.dy / _scaleFactor);
      final Offset local = event.localPosition;
      final Offset focalPointScene = _toScene(local);
      _scale = clampDouble(
        _scale * scaleChange,
        widget.minScale,
        widget.maxScale,
      );
      final Offset focalPointSceneScaled = _toScene(local);
      _position = _matrixTranslate(focalPointSceneScaled - focalPointScene);
      setState(() {});
    }
  }
}

enum _GestureType { pan, scale }

double _getFinalTime(
  double velocity,
  double drag, {
  double effectivelyMotionless = 10,
}) {
  return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
}
