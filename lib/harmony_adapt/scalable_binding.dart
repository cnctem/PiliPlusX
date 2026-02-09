import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ScalableWidgetsFlutterBinding extends BindingBase
    with
        GestureBinding,
        SchedulerBinding,
        ServicesBinding,
        PaintingBinding,
        SemanticsBinding,
        RendererBinding,
        WidgetsBinding {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
  }

  // 1. 静态初始化方法
  static ScalableWidgetsFlutterBinding ensureInitialized() {
    _instance ??= ScalableWidgetsFlutterBinding();
    return _instance!;
  }

  static ScalableWidgetsFlutterBinding? _instance;

  // 2. 设置想要缩放的倍数
  double _scale = 1;

  double get scale => _scale;

  /// 真实dpr
  late double _devicePixelRatio;

  double getLogicaPixelRatio() => _scale * _devicePixelRatio;

  Size toLogicaSize(Size size) => size / _scale;

  // 3. 核心：重写 ViewConfiguration
  @override
  ViewConfiguration createViewConfigurationFor(RenderView renderView) {
    final flutterView = renderView.flutterView;
    final physicalConstraints = BoxConstraints.fromViewConstraints(
      flutterView.physicalConstraints,
    );
    _devicePixelRatio = flutterView.devicePixelRatio;
    // print('设备真实dpr改变：$_devicePixelRatio');
    final logicaPixelRatio = getLogicaPixelRatio();
    return ViewConfiguration(
      physicalConstraints: physicalConstraints,
      logicalConstraints: physicalConstraints / logicaPixelRatio,
      devicePixelRatio: logicaPixelRatio,
    );
  }

  @override
  void handlePointerEvent(PointerEvent event) {
    // 强制覆盖坐标
    final PointerEvent transformedEvent = event.copyWith(
      position: event.position / _scale,
      delta: event.delta / _scale,
    );
    // 将修正后的事件发送给 GestureBinding
    super.handlePointerEvent(transformedEvent);
  }

  void setScale(double newScale) {
    if (newScale == _scale) return;
    _scale = newScale;

    // 关键：强制更新所有渲染视图的配置
    for (final RenderView renderView in renderViews) {
      renderView.configuration = createViewConfigurationFor(renderView);
    }

    // 触发重绘和布局
    handleMetricsChanged();
  }
}
