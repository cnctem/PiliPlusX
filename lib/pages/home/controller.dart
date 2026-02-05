import 'dart:async';
import 'dart:math';

import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/models/common/home_tab_type.dart';
import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/wbi_sign.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController
    with GetTickerProviderStateMixin, ScrollOrRefreshMixin {
  late List<HomeTabType> tabs;
  late TabController tabController;

  RxBool? showSearchBar;

  bool enableSearchWord = Pref.enableSearchWord;
  late final RxString defaultSearch = ''.obs;
  late int lateCheckSearchAt = 0;

  ScrollOrRefreshMixin get controller => tabs[tabController.index].ctr();

  @override
  ScrollController get scrollController => controller.scrollController;

  AccountService accountService = Get.find<AccountService>();

  bool _isFabVisible = true;
  AnimationController? _fabAnimationCtr;
  Animation<Offset>? _fabAnimation;

  Animation<Offset> get fabAnimation {
    if (_fabAnimation != null) return _fabAnimation!;
    _fabAnimationCtr = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
    _fabAnimation = _fabAnimationCtr!.drive(
      Tween<Offset>(
        begin: const Offset(0.0, 2.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeInOut)),
    );
    return _fabAnimation!;
  }

  @override
  void onInit() {
    super.onInit();

    if (!Pref.useSideBar && Pref.hideTopBar) {
      showSearchBar = true.obs;
    }

    if (enableSearchWord) {
      lateCheckSearchAt = DateTime.now().millisecondsSinceEpoch;
      querySearchDefault();
    }

    setTabConfig();
  }

  @override
  Future<void> onRefresh() {
    return controller.onRefresh().catchError((e) {
      if (kDebugMode) debugPrint(e.toString());
    });
  }

  void setTabConfig() {
    final tabs = GStorage.setting.get(SettingBoxKey.tabBarSort) as List?;
    if (tabs != null) {
      this.tabs = tabs.map((i) => HomeTabType.values[i]).toList();
    } else {
      this.tabs = HomeTabType.values;
    }

    tabController = TabController(
      initialIndex: max(0, this.tabs.indexOf(HomeTabType.rcmd)),
      length: this.tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    _fabAnimationCtr?.dispose();
    super.dispose();
  }

  void showFab() {
    if (!_isFabVisible) {
      _isFabVisible = true;
      _fabAnimationCtr?.forward();
    }
  }

  void hideFab() {
    if (_isFabVisible) {
      _isFabVisible = false;
      _fabAnimationCtr?.reverse();
    }
  }

  Future<void> querySearchDefault() async {
    try {
      final res = await Request().get(
        Api.searchDefault,
        queryParameters: await WbiSign.makSign({'web_location': 333.1365}),
      );
      if (res.data['code'] == 0) {
        defaultSearch.value = res.data['data']?['name'] ?? '';
        // defaultSearch.value = res.data['data']?['show_name'] ?? '';
      }
    } catch (_) {}
  }
}
