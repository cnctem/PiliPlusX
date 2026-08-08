import 'package:PiliPlus/common/widgets/text_selection_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;

class SelectionText extends StatefulWidget {
  const SelectionText(
    String this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.onSelectionChanged,
    this.contextMenuBuilder,
  }) : textSpan = null;

  const SelectionText.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.textAlign,
    this.onSelectionChanged,
    this.contextMenuBuilder,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// 选中内容变化回调，可用于在自定义工具栏里获取当前选中文本。
  final ValueChanged<SelectedContent?>? onSelectionChanged;
  final SelectableRegionContextMenuBuilder? contextMenuBuilder;

  @override
  State<SelectionText> createState() => _SelectionTextState();
}

class _SelectionTextState extends State<SelectionText> {
  SelectedContent? _lastContent;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      onSelectionChanged: (content) {
        _lastContent = content;
        widget.onSelectionChanged?.call(content);
      },
      contextMenuBuilder: widget.contextMenuBuilder ?? _defaultContextMenuBuilder,
      child: Text.rich(
        style: widget.style,
        textAlign: widget.textAlign,
        TextSpan(
          text: widget.data,
          children: widget.textSpan != null
              ? <InlineSpan>[widget.textSpan!]
              : null,
        ),
      ),
    );
  }

  Widget _defaultContextMenuBuilder(
    BuildContext context,
    SelectableRegionState selectableRegionState,
  ) {
    return selectionAreaContextMenuBuilder(
      context,
      selectableRegionState,
      selectedTextOf: () => _lastContent?.plainText,
    );
  }
}
