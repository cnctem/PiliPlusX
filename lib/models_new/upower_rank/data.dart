import 'package:PiliPlus/models_new/upower_rank/level_info.dart';
import 'package:PiliPlus/models_new/upower_rank/rank_info.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';

class UpowerRankData {
  List<UpowerRankInfo>? rankInfo;
  int? privilegeType;
  List<int>? tabs;
  List<LevelInfo>? levelInfo;

  UpowerRankData({
    this.rankInfo,
    this.privilegeType,
    this.tabs,
    this.levelInfo,
  });

  factory UpowerRankData.fromJson(Map<String, dynamic> json) => UpowerRankData(
    rankInfo: (json['rank_info'] as List<dynamic>?)
        ?.map((e) => UpowerRankInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
    privilegeType: json['privilege_type'] as int?,
    tabs: (json['tabs'] as List?)?.fromCast(),
    levelInfo: (json['level_info'] as List<dynamic>?)
        ?.map((e) => LevelInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
