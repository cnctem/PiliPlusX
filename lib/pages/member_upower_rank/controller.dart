import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/models_new/upower_rank/data.dart';
import 'package:PiliPlus/models_new/upower_rank/level_info.dart';
import 'package:PiliPlus/models_new/upower_rank/rank_info.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:get/get.dart';

class UpowerRankController
    extends CommonListController<UpowerRankData, UpowerRankInfo> {
  UpowerRankController({
    this.privilegeType,
    required this.upMid,
  });

  final String upMid;
  final int? privilegeType;

  late final Rx<List<LevelInfo>?> tabs = Rx<List<LevelInfo>?>(null);

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<UpowerRankInfo>? getDataList(UpowerRankData response) {
    isEnd = true;
    if (privilegeType == null &&
        response.levelInfo != null &&
        response.levelInfo!.length > 1) {
      tabs.value = response.levelInfo;
    }
    return response.rankInfo;
  }

  @override
  Future<LoadingState<UpowerRankData>> customGetData() => MemberHttp.upowerRank(
    upMid: upMid,
    page: page,
    privilegeType: privilegeType,
  );
}
