import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 让 [controller] 对应的滚动区域支持键盘滚动。
///
/// 点击（或桌面端鼠标悬停）进入该区域后，方向键 / PgUp / PgDn / Home / End
/// 滚动该区域并消费事件，不再冒泡给上层 PlayerFocus 的音量控制；当焦点归还
/// 给播放器（点/悬停视频区、切换 tab）后恢复音量控制。
///
/// 滚动机制本身复用各部件已有的 Scrollable（鼠标滚轮同理）——本组件只是把
/// 键盘事件接到同一个滚动目标上。
class KeyboardScrollable extends StatefulWidget {
  const KeyboardScrollable({
    super.key,
    required this.controller,
    required this.child,
  });

  /// 滚动目标；为空或无客户端时不响应按键
  final ScrollController? controller;

  final Widget child;

  @override
  State<KeyboardScrollable> createState() => _KeyboardScrollableState();
}

class _KeyboardScrollableState extends State<KeyboardScrollable> {
  final FocusNode _focusNode = FocusNode();

  static const double _arrowStep = 60;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    final ctr = widget.controller;
    if (ctr == null || !ctr.hasClients) return;
    final target = (ctr.offset + delta).clamp(
      ctr.position.minScrollExtent,
      ctr.position.maxScrollExtent,
    );
    ctr.animateTo(
      target,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.arrowUp &&
        key != LogicalKeyboardKey.arrowDown &&
        key != LogicalKeyboardKey.pageUp &&
        key != LogicalKeyboardKey.pageDown &&
        key != LogicalKeyboardKey.home &&
        key != LogicalKeyboardKey.end) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      final ctr = widget.controller;
      switch (key) {
        case LogicalKeyboardKey.arrowUp:
          _scrollBy(-_arrowStep);
          break;
        case LogicalKeyboardKey.arrowDown:
          _scrollBy(_arrowStep);
          break;
        case LogicalKeyboardKey.pageUp:
          if (ctr != null && ctr.hasClients) {
            _scrollBy(-ctr.position.viewportDimension * 0.9);
          }
          break;
        case LogicalKeyboardKey.pageDown:
          if (ctr != null && ctr.hasClients) {
            _scrollBy(ctr.position.viewportDimension * 0.9);
          }
          break;
        case LogicalKeyboardKey.home:
          if (ctr != null && ctr.hasClients) {
            ctr.jumpTo(ctr.position.minScrollExtent);
          }
          break;
        case LogicalKeyboardKey.end:
          if (ctr != null && ctr.hasClients) {
            ctr.jumpTo(ctr.position.maxScrollExtent);
          }
          break;
      }
    }
    // KeyUp 一并消费，避免冒泡到 PlayerFocus
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: MouseRegion(
        // 桌面端：悬停即认领，与"滚轮跟随指针"的既有交互一致
        onEnter: (_) => _focusNode.requestFocus(),
        child: Listener(
          onPointerDown: (_) => _focusNode.requestFocus(),
          child: widget.child,
        ),
      ),
    );
  }
}
