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

  // 记录当前轮次的手指按下信息
  final Map<int, _TapDetails> _currentTaps = {};
  
  // 记录上一轮次的双指点击信息
  List<_TapDetails>? _previousTaps;
  
  // 双击超时时间（两次点击之间的最大间隔）
  static const Duration _doubleTapTimeout = Duration(milliseconds: 300);
  
  // 单轮点击的超时时间
  static const Duration _tapTimeout = Duration(milliseconds: 200);
  
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
    
    // 清理超时的上一轮点击
    final now = DateTime.now();
    if (_previousTaps != null && 
        now.difference(_previousTaps!.first.time) > _doubleTapTimeout) {
      _previousTaps = null;
    }
    
    // 记录当前点击详情
    _currentTaps[event.pointer] = _TapDetails(
      pointer: event.pointer,
      position: event.position,
      time: now,
    );
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent) {
      final tapDetails = _currentTaps[event.pointer];
      if (tapDetails == null) return;

      // 检查当前轮次是否超时
      final now = DateTime.now();
      if (now.difference(tapDetails.time) > _tapTimeout) {
        // 超时，清理当前轮次
        _currentTaps.clear();
        _previousTaps = null;
        stopTrackingIfPointerNoLongerDown(event);
        return;
      }

      // 检查是否所有手指都已抬起
      if (_currentTaps.length >= 2) {
        // 延迟检查，确保所有手指都完成点击
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_currentTaps.isEmpty) {
            // 所有手指都已抬起，检查双指双击条件
            _checkForTwoFingerDoubleTap();
          }
        });
      }
      
      // 清理当前指针
      _currentTaps.remove(event.pointer);
      stopTrackingIfPointerNoLongerDown(event);
    } else if (event is PointerCancelEvent) {
      // 取消事件时清理数据
      _currentTaps.remove(event.pointer);
      if (_currentTaps.isEmpty) {
        _previousTaps = null;
      }
      stopTrackingIfPointerNoLongerDown(event);
    }
  }

  void _checkForTwoFingerDoubleTap() {
    // 检查是否有上一轮的双指点击
    if (_previousTaps == null) {
      // 没有上一轮点击，将当前轮次保存为上一轮
      _previousTaps = List.from(_currentTaps.values);
      return;
    }

    final now = DateTime.now();
    
    // 检查距离上次触发的时间
    if (_lastTwoFingerDoubleTapTime != null &&
        now.difference(_lastTwoFingerDoubleTapTime!) < _minTimeBetweenTriggers) {
      return;
    }

    // 检查当前轮次和上一轮次是否都满足双指条件
    if (_currentTaps.length < 2 || _previousTaps!.length < 2) {
      return;
    }

    // 检查两轮点击之间的时间间隔（双击检测）
    final lastTapTime = _previousTaps!.first.time;
    final currentTapTime = _currentTaps.values.first.time;
    
    if (currentTapTime.difference(lastTapTime) > _doubleTapTimeout) {
      // 超时，重置状态
      _previousTaps = List.from(_currentTaps.values);
      return;
    }

    // 检查点击位置是否合理（两个手指不应该太接近）
    final allPositions = [
      ..._previousTaps!.map((tap) => tap.position),
      ..._currentTaps.values.map((tap) => tap.position),
    ];
    
    const double minDistance = 30.0; // 最小距离30像素
    
    bool positionsValid = true;
    for (int i = 0; i < allPositions.length; i++) {
      for (int j = i + 1; j < allPositions.length; j++) {
        final distance = (allPositions[i] - allPositions[j]).distance;
        if (distance < minDistance) {
          positionsValid = false;
          break;
        }
      }
      if (!positionsValid) break;
    }
    
    if (!positionsValid) {
      // 位置不合理，重置状态
      _previousTaps = List.from(_currentTaps.values);
      return;
    }

    // 触发双指双击
    _lastTwoFingerDoubleTapTime = now;
    _previousTaps = null; // 重置状态，等待新的双指点击
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
    _currentTaps.remove(pointer);
    if (_currentTaps.isEmpty) {
      _previousTaps = null;
    }
  }

  @override
  String get debugDescription => 'two finger double tap';

  @override
  void didStopTrackingLastPointer(int pointer) {
    // 清理所有数据
    _currentTaps.clear();
    _previousTaps = null;
  }

  @override
  void dispose() {
    _currentTaps.clear();
    _previousTaps = null;
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