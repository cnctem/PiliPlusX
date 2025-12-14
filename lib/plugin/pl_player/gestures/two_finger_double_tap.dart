import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 双指双击手势识别器
/// 用于检测两个手指同时双击屏幕的手势
class TwoFingerDoubleTapGestureRecognizer extends OneSequenceGestureRecognizer {
  TwoFingerDoubleTapGestureRecognizer({
    super.debugOwner,
    PointerDeviceKind? kind,
    this.onTwoFingerDoubleTap,
  });

  /// 双指双击回调
  GestureTapCallback? onTwoFingerDoubleTap;

  // 记录手指按下信息
  final Map<int, _TapDetails> _taps = {};
  
  // 双击超时时间
  static const Duration _doubleTapTimeout = Duration(milliseconds: 300);
  
  // 记录上一次双指双击的时间，用于防止重复触发
  DateTime? _lastTwoFingerDoubleTapTime;
  static const Duration _minTimeBetweenTriggers = Duration(milliseconds: 500);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // 只允许触摸事件
    if (event.kind != PointerDeviceKind.touch) {
      return;
    }

    // 调用父类方法开始跟踪指针
    super.addAllowedPointer(event);
    
    // 记录点击详情
    _taps[event.pointer] = _TapDetails(
      pointer: event.pointer,
      position: event.position,
      time: DateTime.now(),
    );
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent) {
      final tapDetails = _taps[event.pointer];
      if (tapDetails == null) return;

      // 检查是否超时
      final now = DateTime.now();
      if (now.difference(tapDetails.time) > _doubleTapTimeout) {
        _taps.remove(event.pointer);
        stopTrackingIfPointerNoLongerDown(event);
        return;
      }

      // 检查是否有至少两个手指在合理时间内点击
      _checkForTwoFingerDoubleTap();
      
      // 清理当前指针
      _taps.remove(event.pointer);
      stopTrackingIfPointerNoLongerDown(event);
    } else if (event is PointerCancelEvent) {
      // 取消事件时清理数据
      _taps.remove(event.pointer);
      stopTrackingIfPointerNoLongerDown(event);
    }
  }

  void _checkForTwoFingerDoubleTap() {
    // 需要至少两个手指
    if (_taps.length < 2) return;

    final now = DateTime.now();
    
    // 检查距离上次触发的时间
    if (_lastTwoFingerDoubleTapTime != null &&
        now.difference(_lastTwoFingerDoubleTapTime!) < _minTimeBetweenTriggers) {
      return;
    }

    // 获取所有点击的时间
    final tapTimes = _taps.values.map((tap) => tap.time).toList();
    
    // 检查所有点击是否在合理的时间窗口内
    final oldestTime = tapTimes.reduce((a, b) => a.isBefore(b) ? a : b);
    final newestTime = tapTimes.reduce((a, b) => a.isAfter(b) ? a : b);
    
    if (newestTime.difference(oldestTime) > _doubleTapTimeout) {
      return;
    }

    // 检查点击位置是否合理（两个手指不应该太接近）
    final positions = _taps.values.map((tap) => tap.position).toList();
    const double minDistance = 50.0; // 最小距离50像素
    
    bool positionsValid = true;
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final distance = (positions[i] - positions[j]).distance;
        if (distance < minDistance) {
          positionsValid = false;
          break;
        }
      }
      if (!positionsValid) break;
    }
    
    if (!positionsValid) return;

    // 触发双指双击
    _lastTwoFingerDoubleTapTime = now;
    if (onTwoFingerDoubleTap != null) {
      invokeCallback<void>('onTwoFingerDoubleTap', onTwoFingerDoubleTap!);
    }
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    // 接受手势竞争
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    // 拒绝手势竞争时清理数据
    _taps.remove(pointer);
  }

  @override
  String get debugDescription => 'two finger double tap';

  @override
  void didStopTrackingLastPointer(int pointer) {
    // 清理所有数据
    _taps.clear();
  }

  @override
  void dispose() {
    _taps.clear();
    super.dispose();
  }
}

/// 点击详情类
class _TapDetails {
  final int pointer;
  final Offset position;
  final DateTime time;

  _TapDetails({
    required this.pointer,
    required this.position,
    required this.time,
  });
}