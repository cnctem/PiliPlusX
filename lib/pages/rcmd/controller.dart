import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class RcmdController extends CommonListController {
  late bool enableSaveLastData = Pref.enableSaveLastData;
  final bool appRcmd = Pref.appRcmd;

  int? lastRefreshAt;
  late bool savedRcmdTip = Pref.savedRcmdTip;

  @override
  void onInit() {
    super.onInit();
    page = 0;
    queryData();
  }

  @override
  Future<LoadingState> customGetData() {
    return appRcmd
        ? VideoHttp.rcmdVideoListApp(freshIdx: page)
        : VideoHttp.rcmdVideoList(freshIdx: page, ps: 20);
  }

  @override
  void handleListResponse(List dataList) {
    if (enableSaveLastData && page == 0 && loadingState.value.isSuccess) {
      List? currentList = loadingState.value.data;
      if (currentList?.isNotEmpty == true) {
        if (savedRcmdTip) {
          lastRefreshAt = dataList.length;
        }
        if (currentList!.length > 500) {
          currentList.removeRange(50, currentList.length);
        }
        dataList.addAll(currentList);
      }
    }
  }

  @override
  Future<void> onRefresh() async {
    page = 0;
    isEnd = false;
    await queryData();
    // 显示自定义刷新消息
    SmartDialog.showToast('推荐已刷新');
  }
}
