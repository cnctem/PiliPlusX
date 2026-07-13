import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/gestures.dart';

class CustomHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  CustomHorizontalDragGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
  });

  Offset? _initialPosition;
  Offset? get initialPosition => _initialPosition;

  @override
  DeviceGestureSettings get gestureSettings => _gestureSettings;
  final _gestureSettings = DeviceGestureSettings(touchSlop: touchSlopH);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _initialPosition = event.position;
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    return _computeHitSlop(
      globalDistanceMoved.abs(),
      gestureSettings,
      pointerDeviceKind,
      _initialPosition,
      lastPosition.global,
    );
  }
}

double touchSlopH = Pref.touchSlopH;

bool _computeHitSlop(
  double globalDistanceMoved,
  DeviceGestureSettings? settings,
  PointerDeviceKind kind,
  Offset? initialPosition,
  Offset lastPosition,
) {
  switch (kind) {
    case PointerDeviceKind.mouse:
      return globalDistanceMoved > kPrecisePointerHitSlop;
    case PointerDeviceKind.stylus:
    case PointerDeviceKind.invertedStylus:
    case PointerDeviceKind.unknown:
    case PointerDeviceKind.touch:
      return globalDistanceMoved > touchSlopH &&
          _calc(initialPosition!, lastPosition);
    case PointerDeviceKind.trackpad:
      return globalDistanceMoved > (settings?.touchSlop ?? kTouchSlop);
  }
}

bool _calc(Offset initialPosition, Offset lastPosition) {
  final offset = lastPosition - initialPosition;
  // 判定：只要水平位移 > 垂直位移即算横滑（原为 dx > 3·dy，过于苛刻）。
  // 约 45° 以内的滑动都会被判定为横向，让简介/评论区左右切换更容易触发。
  return offset.dx.abs() > offset.dy.abs();
}
