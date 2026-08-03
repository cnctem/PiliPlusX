import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:os_type/os_type.dart';

/// 原生顶栏启用时，首页各 Tab 列表顶部注入的可滚动留白。
///
/// 以 Sliver 形式放在 CustomScrollView 顶部：初始时留出空白不与 ArkTS 顶栏
/// 重叠；用户上滑时空白随列表一起卷走，内容自然滑入 ArkTS 顶栏下方形成
/// 沉浸重合，而非固定遮罩。
///
/// 高度随顶栏显隐联动，并按分类标签数量区分：
/// - 仅一个分类（无分类条）：展开 55vp / 收起 0vp
/// - 多个分类（含分类条）：展开 85vp / 收起 30vp
/// 收起信号来自 HomeController.topBarCollapsed（由滚动偏移同步），
/// 与 ArkTS 顶栏的收起状态保持同时变化。
class NativeTopSpacer extends StatelessWidget {
  const NativeTopSpacer({super.key});

  /// 多个分类标签时：顶栏展开/收起对应的留白高度
  static const double expandedHeight = 85;
  static const double collapsedHeight = 30;

  /// 仅一个分类标签时：顶栏展开/收起对应的留白高度。
  /// 单分类不显示分类条，收起后顶栏完全隐藏，故收起留白为 0。
  static const double singleExpandedHeight = 55;
  static const double singleCollapsedHeight = 0;

  /// 首页其他非滚动容器（如分区左侧标签栏）的静态留白高度。
  /// 禁用原生顶栏时返回 0。
  /// 按分类标签数量区分：
  /// - 仅一个分类：展开 55vp / 收起 0vp
  /// - 多个分类：展开 85vp / 收起 30vp
  static double staticHeight(BuildContext context) {
    final useNativeTopBar =
        OS.isHarmony && Get.find<MainController>().useNativeTopBar.value;
    if (!useNativeTopBar) return 0;
    HomeController? homeController;
    try {
      homeController = Get.find<HomeController>();
    } catch (_) {}
    final collapsed = homeController?.topBarCollapsed.value ?? false;
    final single = (homeController?.tabs.length ?? 0) <= 1;
    if (single) {
      return collapsed ? singleCollapsedHeight : singleExpandedHeight;
    }
    return collapsed ? collapsedHeight : expandedHeight;
  }

  @override
  Widget build(BuildContext context) {
    // 各 Tab 页处于 keepAlive 状态，不随 HomePage 重建，需用 Obx
    // 确保 useNativeTopBar 异步就绪/顶栏收起状态变化后高度自动更新。
    // 高度变化应用线性动画 0.220s，与 ArkTS 顶栏收起/展开的
    // TransitionEffect（220ms）节奏一致。
    return SliverToBoxAdapter(
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.linear,
          height: staticHeight(context),
        ),
      ),
    );
  }
}
