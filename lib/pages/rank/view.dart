import 'package:PiliPlus/common/widgets/flutter/vertical_tabs.dart';
import 'package:PiliPlus/common/widgets/native_top_spacer.dart';
import 'package:PiliPlus/models/common/rank_type.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/rank/controller.dart';
import 'package:PiliPlus/pages/rank/zone/view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:os_type/os_type.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage>
    with AutomaticKeepAliveClientMixin {
  final RankController _rankController = Get.put(RankController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    // 两列内容各自独立应用顶栏留白：
    // - 左侧 VerticalTabBar（非滚动避让）→ 顶部 padding
    // - 右侧 ZonePage 列表 → 内部 slivers 注入 NativeTopSpacer（随滚动卷走）
    return Row(
      children: [
        _buildTab(theme),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _rankController.tabController,
            children: RankType.values
                .map(
                  (item) => ZonePage(
                    rid: item.rid,
                    seasonType: item.seasonType,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(ThemeData theme) {
    // 顶部留白需 Obx 包裹：useNativeTopBar 异步就绪 / topBarCollapsed 收起
    // 变化后自动重建。高度直接复用 NativeTopSpacer.staticHeight，与右侧
    // ZonePage 列表顶部的 Sliver 留白语义对齐——两者都按「首页分类数 + 
    // 顶栏收起状态」计算，避免硬编码 magic number 导致左右不对称。
    return Obx(() {
      final useNativeTopBar =
          OS.isHarmony && Get.find<MainController>().useNativeTopBar.value;
      return VerticalTabBar(
        dividerWidth: 0,
        isScrollable: true,
        indicatorWeight: 3,
        indicatorSize: .tab,
        controller: _rankController.tabController,
        padding: .only(
          top: useNativeTopBar ? NativeTopSpacer.staticHeight(context) : 0,
          bottom: MediaQuery.paddingOf(context).bottom + 105,
        ),
        tabs: RankType.values.map((e) => VerticalTab(text: e.label)).toList(),
        onTap: (index) {
          if (!_rankController.tabController.indexIsChanging) {
            _rankController.animateToTop();
          } else {
            _rankController
              ..tabIndex.value = index
              ..tabController.animateTo(index);
          }
        },
      );
    });
  }
}
