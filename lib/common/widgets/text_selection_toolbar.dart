import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/share_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:get/get.dart';

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

final _schemeRegex = RegExp(r'[\w\-]+://\S');

/// 在选中工具栏「分享」后追加「打开 / 站内搜索」项。
///
/// 选中的是带 scheme 的链接 → 「打开」，交给 [PageUtils.handleWebview] 分流；
/// 否则 → 「站内搜索」，跳搜索结果页。
///
/// 对齐上游 bggRGjQaUbCoE/PiliPlus#2474。上游的实现放在
/// `lib/utils/extension/selectable_region_ext.dart`，靠 SDK 补丁把
/// [SelectableRegionState] 的私有成员放出来才能读到选中文本；鸿蒙分支不打 SDK
/// 补丁，所以沿用本文件既有的做法，由调用方经 [selectedTextOf] 注入。
List<ContextMenuButtonItem> ensureSearchButton(
  List<ContextMenuButtonItem> buttonItems, {
  required String? Function() selectedTextOf,
  required VoidCallback hideToolbar,
}) {
  final String? text = selectedTextOf()?.trim();
  if (text == null || text.isEmpty) return buttonItems;
  final bool isScheme = text.startsWith(_schemeRegex);
  // 紧跟在「分享」之后；没有分享项（桌面端）时跟在「复制」之后。
  final int anchor = buttonItems.lastIndexWhere(
    (item) =>
        item.type == ContextMenuButtonType.share ||
        item.type == ContextMenuButtonType.copy,
  );
  buttonItems.insertOrAdd(
    anchor == -1 ? buttonItems.length : anchor + 1,
    ContextMenuButtonItem(
      label: isScheme ? '打开' : '站内搜索',
      onPressed: () {
        hideToolbar();
        if (isScheme) {
          PageUtils.handleWebview(text);
        } else {
          Get.offOrToNamed(
            '/searchResult',
            parameters: {'keyword': text},
            // 选区常出现在对话框/底部面板里，这类路由不是 PageRoute，
            // 直接 off 掉，避免搜索结果压在浮层上面。
            off: Get.routing.route is! PageRoute,
          );
        }
      },
    ),
  );
  return buttonItems;
}

/// 选中工具栏的统一加工：默认按钮 + [ensureShareButton] + [ensureSearchButton]。
List<ContextMenuButtonItem> ensureExtraButtons(
  List<ContextMenuButtonItem> buttonItems, {
  required String? Function() selectedTextOf,
  required VoidCallback hideToolbar,
}) {
  ensureShareButton(
    buttonItems,
    selectedTextOf: selectedTextOf,
    hideToolbar: hideToolbar,
  );
  return ensureSearchButton(
    buttonItems,
    selectedTextOf: selectedTextOf,
    hideToolbar: hideToolbar,
  );
}

/// [SelectionArea]/[SelectionText] 上下文菜单：默认按钮 + 统一分享 + 打开/站内搜索。
/// 选中文本由使用方经 [selectedTextOf] 注入（OHOS 引擎未暴露选中文本）。
Widget selectionAreaContextMenuBuilder(
  BuildContext context,
  SelectableRegionState selectableRegionState, {
  String? Function()? selectedTextOf,
}) {
  final buttonItems = ensureExtraButtons(
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
  final buttonItems = ensureExtraButtons(
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