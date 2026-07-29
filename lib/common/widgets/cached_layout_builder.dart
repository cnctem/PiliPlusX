import 'package:flutter/widgets.dart';

/// 带缓存的 LayoutBuilder，避免父组件 rebuild 时产生不必要的子树重建。
///
/// 优化点：
/// 1. 缓存 builder 闭包，避免每次 rebuild 产生新实例触发 scheduleLayoutCallback
/// 2. 约束未变时直接返回缓存的子组件，跳过子树构建
class CachedLayoutBuilder extends StatefulWidget {
  const CachedLayoutBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, BoxConstraints constraints)
  builder;

  @override
  State<CachedLayoutBuilder> createState() => _CachedLayoutBuilderState();
}

class _CachedLayoutBuilderState extends State<CachedLayoutBuilder> {
  BoxConstraints? _previousConstraints;
  Widget? _cachedChild;

  // 稳定的闭包实例，不会因父 rebuild 而改变
  late final Widget Function(BuildContext, BoxConstraints) _builder = _build;

  Widget _build(BuildContext context, BoxConstraints constraints) {
    // 约束未变时直接返回缓存，跳过子树重建
    if (_cachedChild != null && constraints == _previousConstraints) {
      return _cachedChild!;
    }
    _previousConstraints = constraints;
    _cachedChild = widget.builder(context, constraints);
    return _cachedChild!;
  }

  @override
  void didUpdateWidget(CachedLayoutBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // builder 引用变化时清除缓存，强制下次重建
    if (oldWidget.builder != widget.builder) {
      _cachedChild = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _builder);
  }
}
