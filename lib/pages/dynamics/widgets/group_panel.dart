import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// The second, horizontally-scrollable tab row on the dynamics page.
///
/// Mirrors the follow page's group tab bar: it is a real [TabBar] backed by
/// [DynamicsController.groupTabController], so the selection highlight and
/// the scroll-into-view behaviour update immediately on tap.
class DynamicsGroupPanel extends StatelessWidget {
  const DynamicsGroupPanel({super.key, required this.controller});

  final DynamicsController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Obx(() {
      final tabController = controller.groupTabController.value;
      if (tabController == null) {
        return const SizedBox(height: 46);
      }
      return TabBar(
        controller: tabController,
        dividerHeight: 0,
        isScrollable: true,
        tabAlignment: .start,
        dividerColor: Colors.transparent,
        labelColor: colorScheme.primary,
        indicatorColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelStyle:
            TabBarTheme.of(context).labelStyle?.copyWith(fontSize: 13) ??
            const TextStyle(fontSize: 13),
        tabs: controller.groups.map((e) => Tab(text: e.name)).toList(),
        onTap: controller.onTapGroupTab,
      );
    });
  }
}
