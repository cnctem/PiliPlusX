import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/share_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;

/// 在选中工具栏「复制」后追加统一「分享」项（Android/iOS/OHOS，桌面端除外）。
///
/// 移除 framework 默认分享项（引擎 `Share.invoke`），统一走
/// [ShareUtils.shareText]（share_plus → 系统分享面板），保证多端一致。
List<ContextMenuButtonItem> ensureShareButton(
  List<ContextMenuButtonItem> buttonItems, {
  required String? Function() selectedTextOf,
  required VoidCallback hideToolbar,
}) {
  // 桌面端 ShareUtils 仅复制文本，不提供分享按钮。
  if (PlatformUtils.isDesktop) return buttonItems;
  buttonItems.removeWhere((item) => item.type == ContextMenuButtonType.share);
  // 插到「复制」之后，与 Android 原生工具栏顺序一致；无复制项时放末尾。
  final int copyIndex =
      buttonItems.indexWhere((item) => item.type == ContextMenuButtonType.copy);
  buttonItems.insert(
    copyIndex == -1 ? buttonItems.length : copyIndex + 1,
    ContextMenuButtonItem(
      type: ContextMenuButtonType.share,
      onPressed: () {
        final String? text = selectedTextOf();
        hideToolbar();
        if (text != null && text.trim().isNotEmpty) {
          ShareUtils.shareText(text);
        }
      },
    ),
  );
  return buttonItems;
}

/// [SelectionArea]/[SelectionText] 上下文菜单：默认按钮 + 统一分享。
/// 选中文本由使用方经 [selectedTextOf] 注入（OHOS 引擎未暴露选中文本）。
Widget selectionAreaContextMenuBuilder(
  BuildContext context,
  SelectableRegionState selectableRegionState, {
  String? Function()? selectedTextOf,
}) {
  final buttonItems = ensureShareButton(
    selectableRegionState.contextMenuButtonItems,
    selectedTextOf: selectedTextOf ?? () => null,
    hideToolbar: () => selectableRegionState.hideToolbar(),
  );
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: selectableRegionState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}

/// 标准 [SelectableText] 上下文菜单（内部为只读 [EditableText]）。
Widget selectableTextContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  final buttonItems = ensureShareButton(
    editableTextState.contextMenuButtonItems,
    selectedTextOf: () => _selectedTextOf(editableTextState),
    hideToolbar: () => editableTextState.hideToolbar(),
  );
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}

/// 读取 [EditableTextState] 当前选中文本，无选中返回 null。
String? _selectedTextOf(EditableTextState state) {
  final TextSelection selection = state.textEditingValue.selection;
  if (!selection.isValid || selection.isCollapsed) return null;
  return selection.textInside(state.textEditingValue.text);
}

/// 捕获当前选中文本，供自定义上下文菜单使用。
class SelectedContentCapture {
  SelectedContent? _content;

  String? get selectedText => _content?.plainText;

  /// 挂到 [SelectionArea]/[SelectionText] 的 `onSelectionChanged`。
  void onSelectionChanged(SelectedContent? content) => _content = content;
}