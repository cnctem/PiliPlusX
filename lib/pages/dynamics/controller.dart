import 'dart:async';

import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models/dynamics/up.dart';
import 'package:PiliPlus/models/member/tags.dart';
import 'package:PiliPlus/pages/common/common_data_controller.dart';
import 'package:PiliPlus/pages/dynamics_tab/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' show TabController;

class DynamicsController
    extends CommonDataController<FollowUpModel, FollowUpModel>
    with GetTickerProviderStateMixin, AccountMixin {
  late final TabController tabController;

  final Set<int> tempBannedList = <int>{};

  String? _offset;
  late int _page = 1;
  late bool _isEnd = false;
  Set<UpItem>? _cacheUpList;
  late int hostMid = -1, currentMid = -1;
  late bool showLiveUp = Pref.expandDynLivePanel;
  late final _showAllUp = Pref.dynamicsShowAllFollowedUp;

  final upPanelPosition = Pref.upPanelPosition;

  /// 分组动态开关（设置-外观），关闭时动态页与原始版本完全一致
  late final bool groupEnabled = Pref.dynamicsGroupEnabled;
  final RxList<MemberTagItemModel> followGroups = <MemberTagItemModel>[].obs;
  final RxBool isGroupMembersLoading = false.obs;
  final RxnInt selectedGroupTagId = RxnInt();
  final Rxn<List<UpItem>> selectedGroupUps = Rxn<List<UpItem>>();
  Set<int>? _selectedGroupMids;
  int _groupRequestId = 0;

  /// Tab controller backing the follow-group tab row; recreated whenever the
  /// group list changes, mirroring the follow page's implementation.
  final Rxn<TabController> groupTabController = Rxn<TabController>();
  Worker? _navRefreshWorker;

  /// 各 UP 最近一条动态的发布时间(pub_ts)：随动态流加载顺带记录，
  /// 用于 UP 面板按"最近发动态时间"排序（无需为每个 UP 单独请求）。
  final RxMap<int, int> upLastPostTs = <int, int>{}.obs;

  @override
  final AccountService accountService = Get.find<AccountService>();

  DynamicsTabController? get controller {
    try {
      return Get.find<DynamicsTabController>(
        tag: DynamicsTabType.values[tabController.index].name,
      );
    } catch (_) {
      return null;
    }
  }

  /// `null` means all followed UPs; a non-null set limits the dynamic feed to
  /// the members of the currently selected follow group.
  Set<int>? get selectedGroupMids => _selectedGroupMids;

  bool get hasSelectedGroup => selectedGroupTagId.value != null;

  List<MemberTagItemModel> get groups => <MemberTagItemModel>[
    MemberTagItemModel(name: '全部分组'),
    ...followGroups,
  ];

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(
      vsync: this,
      length: DynamicsTabType.values.length,
      initialIndex: Pref.defaultDynamicTypeIndex,
    );
    if (groupEnabled) {
      onInitGroupTab();
      tabController.addListener(_onMainTabChanged);
      // 从其它主页面切回动态页时重新拉取分组，保证与"我的关注"页的分组顺序一致
      final mainController = Get.find<MainController>();
      _navRefreshWorker = ever<int>(mainController.selectedIndex, (index) {
        if (index >= 0 &&
            index < mainController.navigationBars.length &&
            mainController.navigationBars[index] ==
                NavigationBarType.dynamics) {
          queryFollowGroups();
        }
      });
    }
    queryData();
    if (groupEnabled) queryFollowGroups();
  }

  void onInitGroupTab() {
    // 选中状态按 tagid 记录：分组顺序变化后，索引要重新按 tagid 反查，
    // 否则同一 index 会指向别的分组，导致高亮与内容对不上。
    int initialIndex = 0;
    final selectedTagId = selectedGroupTagId.value;
    if (selectedTagId != null) {
      final index = groups.indexWhere((e) => e.tagid == selectedTagId);
      if (index >= 0) {
        initialIndex = index;
      } else {
        // 选中的分组已被删除：重置为全部分组
        selectedGroupTagId.value = null;
        selectedGroupUps.value = null;
        _selectedGroupMids = null;
        _showGroupDynamics();
      }
    }
    final previous = groupTabController.value;
    previous?.dispose();
    groupTabController.value = TabController(
      initialIndex: initialIndex,
      length: groups.length,
      vsync: this,
    );
  }

  void _onMainTabChanged() {
    if (tabController.indexIsChanging) return;
    final index = tabController.index;
    if (index < 0 || index >= DynamicsTabType.values.length) return;
    // 进入的分区为空时自动重新从网络加载，无需手动下拉刷新
    try {
      final tabController = Get.find<DynamicsTabController>(
        tag: DynamicsTabType.values[index].name,
      );
      if (tabController.loadingState.value case Success(:final response)) {
        if (response == null || response.isEmpty) {
          tabController.onReload();
        }
      }
    } catch (_) {}
  }

  void onTapGroupTab(int index) {
    final list = groups;
    if (index < 0 || index >= list.length) return;
    onSelectGroup(list[index]);
  }

  /// 动态流每加载一页就更新各 UP 的最近发布时间
  void recordDynamicsPubTs(List<DynamicItemModel>? items) {
    if (!groupEnabled || items == null || items.isEmpty) return;
    for (final item in items) {
      final author = item.modules.moduleAuthor;
      final ts = author?.pubTs;
      if (author == null || ts == null) continue;
      final mid = author.mid;
      if (mid == null || mid <= 0) continue;
      final old = upLastPostTs[mid];
      if (old == null || ts > old) {
        upLastPostTs[mid] = ts;
      }
    }
  }

  /// 按"最近发动态时间"倒序排序 UP 列表；没有记录的 UP 保持服务端原顺序排在后面
  List<UpItem>? sortUpListByLastPost(List<UpItem>? list) {
    if (!groupEnabled ||
        list == null ||
        list.length < 2 ||
        upLastPostTs.isEmpty) {
      return list;
    }
    final order = <int, int>{};
    for (int i = 0; i < list.length; i++) {
      order[list[i].mid] = i;
    }
    final sorted = List<UpItem>.of(list)
      ..sort((a, b) {
        final ta = upLastPostTs[a.mid];
        final tb = upLastPostTs[b.mid];
        if (ta == null && tb == null) {
          return order[a.mid]!.compareTo(order[b.mid]!);
        }
        if (ta == null) return 1;
        if (tb == null) return -1;
        final diff = tb.compareTo(ta);
        return diff != 0 ? diff : order[a.mid]!.compareTo(order[b.mid]!);
      });
    return sorted;
  }

  Future<void> queryFollowGroups() async {
    final res = await MemberHttp.followUpTags();
    if (res case Success(:final response)) {
      followGroups.assignAll(response);
      onInitGroupTab();
    }
  }

  Future<void> onSelectGroup(MemberTagItemModel group) async {
    final tagid = group.tagid;
    if (tagid == null) {
      _groupRequestId++;
      isGroupMembersLoading.value = false;
      selectedGroupTagId.value = null;
      selectedGroupUps.value = null;
      _selectedGroupMids = null;
      groupTabController.value?.index = 0;
      _showGroupDynamics();
      return;
    }

    if (selectedGroupTagId.value == tagid && !isGroupMembersLoading.value) {
      return;
    }

    final requestId = ++_groupRequestId;
    final previousTagId = selectedGroupTagId.value;
    final previousUps = selectedGroupUps.value;
    final previousMids = _selectedGroupMids;
    selectedGroupTagId.value = tagid;
    isGroupMembersLoading.value = true;
    try {
      final members = <UpItem>[];
      int page = 1;
      const pageSize = 50;
      while (true) {
        final res = await MemberHttp.followUpGroup(
          mid: Accounts.main.mid,
          tagid: tagid,
          pn: page,
          ps: pageSize,
        );
        if (res case Success(:final response)) {
          final list = response.list ?? <UpItem>[];
          members.addAll(list);
          if (list.length < pageSize ||
              (group.count != null && members.length >= group.count!)) {
            break;
          }
          page++;
        } else {
          if (requestId == _groupRequestId) {
            selectedGroupTagId.value = previousTagId;
            selectedGroupUps.value = previousUps;
            _selectedGroupMids = previousMids;
            final tabController = groupTabController.value;
            if (tabController != null) {
              final previousIndex = previousTagId == null
                  ? 0
                  : groups.indexWhere((e) => e.tagid == previousTagId);
              tabController.index = previousIndex >= 0 ? previousIndex : 0;
            }
          }
          return;
        }
      }
      if (requestId != _groupRequestId) return;
      // 分组接口不返回未读标记(has_update)：从全部关注的 UP 列表按 mid 合并过来
      if (loadingState.value case Success(:final response)) {
        final upList = response.upList;
        if (upList != null && upList.isNotEmpty) {
          final updateMids = <int>{
            for (final e in upList)
              if (e.hasUpdate ?? false) e.mid,
          };
          if (updateMids.isNotEmpty) {
            for (final item in members) {
              if (updateMids.contains(item.mid)) {
                item.hasUpdate = true;
              }
            }
          }
        }
      }
      selectedGroupUps.value = members;
      _selectedGroupMids = members.map((item) => item.mid).toSet();
      _showGroupDynamics();
    } finally {
      if (requestId == _groupRequestId) {
        isGroupMembersLoading.value = false;
      }
    }
  }

  void _showGroupDynamics() {
    currentMid = -1;
    _jumpToTab(-1);
    for (final type in DynamicsTabType.values) {
      try {
        Get.find<DynamicsTabController>(tag: type.name).onReload();
      } catch (_) {}
    }
  }

  void _jumpToTab(int mid) {
    tabController.index = mid == -1 ? 0 : 4;
  }

  void onSelectUp(int mid) {
    if (currentMid == mid) {
      _jumpToTab(mid);
      if (mid == -1) {
        singleRefresh();
      }
      controller?.onReload();
      return;
    }

    if (mid != -1) {
      hostMid = mid;
      try {
        Get.find<DynamicsTabController>(tag: DynamicsTabType.up.name)
            .onReload();
      } catch (_) {}
    }

    currentMid = mid;
    _jumpToTab(mid);
  }

  Future<void> singleRefresh() {
    if (_showAllUp) {
      _page = 1;
      _cacheUpList = null;
    }
    _offset = null;
    _isEnd = false;
    return super.onRefresh();
  }

  @override
  Future<void> onRefresh() {
    final controller = this.controller;
    if (controller != null) {
      singleRefresh();
      return controller.onRefresh();
    }
    return singleRefresh();
  }

  @override
  void animateToTop() {
    controller?.animateToTop();
    scrollController.animToTop();
  }

  @override
  void toTopOrRefresh() {
    final ctr = controller;
    if (ctr?.scrollController.hasClients == true) {
      if (ctr!.scrollController.position.pixels == 0) {
        if (scrollController.hasClients &&
            scrollController.position.pixels != 0) {
          scrollController.animToTop();
        }
        EasyThrottle.throttle(
          'topOrRefresh',
          const Duration(milliseconds: 500),
          onRefresh,
        );
      } else {
        animateToTop();
      }
    } else {
      super.toTopOrRefresh();
    }
  }

  @override
  void onClose() {
    _navRefreshWorker?.dispose();
    groupTabController.value?.dispose();
    tabController.dispose();
    super.onClose();
  }

  @override
  void onChangeAccount(bool isLogin) {
    selectedGroupTagId.value = null;
    selectedGroupUps.value = null;
    _selectedGroupMids = null;
    groupTabController.value?.index = 0;
    if (groupEnabled) queryFollowGroups();
    onReload();
  }

  @override
  Future<LoadingState<FollowUpModel>> customGetData() {
    if (_offset == null) {
      return DynamicsHttp.followUp();
    }
    if (_showAllUp) {
      return DynamicsHttp.followings(
        vmid: Accounts.main.mid,
        pn: _page,
        orderType: 'attention',
        ps: 50,
      );
    } else {
      return DynamicsHttp.dynUpList(_offset);
    }
  }

  @override
  Future<void> queryData([bool isRefresh = true]) {
    if (!isRefresh && _isEnd) return Future.value();
    return super.queryData(isRefresh);
  }

  @override
  bool customHandleResponse(bool isRefresh, Success<FollowUpModel> response) {
    final res = response.response;

    if (_showAllUp) {
      if (res.upList?.isNotEmpty != true) {
        _isEnd = true;
      }
    } else {
      _offset = res.offset;
      if (res.hasMore != true || _offset.isNullOrEmpty) {
        _isEnd = true;
      }
    }

    if (isRefresh) {
      if (_showAllUp) {
        _offset = '';
        _cacheUpList = res.upList?.toSet();
      }
      loadingState.value = response;
    } else {
      if (_showAllUp) {
        _page++;
      }

      if (res.upList case final upList? when upList.isNotEmpty) {
        if (_showAllUp && _cacheUpList != null) {
          upList.removeWhere(_cacheUpList!.contains);
        }
        loadingState
          ..value.data.addAllUpList(upList)
          ..refresh();
      }
    }

    return true;
  }
}
