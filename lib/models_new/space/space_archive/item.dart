import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models_new/space/space_archive/badge.dart';
import 'package:PiliPlus/models_new/space/space_archive/history.dart';
import 'package:PiliPlus/models_new/space/space_archive/season.dart';

class SpaceArchiveItem extends BaseSimpleVideoItemModel {
  String? uri;
  String? param;
  String? goto;
  String? length;
  bool? isSteins;
  bool? isCooperation;
  bool? isPgc;
  bool? isPugv;
  String? publishTimeText;
  List<Badge>? badges;
  SpaceArchiveSeason? season;
  History? history;
  String? styles;
  String? label;

  SpaceArchiveItem.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    cover = json['cover'];
    uri = json['uri'];
    param = json['param'];
    goto = json['goto'];
    length = json['length'];
    duration = json['duration'] ?? -1;
    isSteins = json['is_steins'];
    isCooperation = json['is_cooperation'];
    isPgc = json['is_pgc'];
    isPugv = json['is_pugv'];
    bvid = json['bvid'];
    cid = json['first_cid'];
    publishTimeText = json['publish_time_text'];
    badges = (json['badges'] as List<dynamic>?)
        ?.map((e) => Badge.fromJson(e as Map<String, dynamic>))
        .toList();
    history = json['history'] == null
        ? null
        : History.fromJson(json['history'] as Map<String, dynamic>);
    season = json['season'] == null
        ? null
        : SpaceArchiveSeason.fromJson(json['season'] as Map<String, dynamic>);
    stat = PlayStat.fromJson(json);
    owner = Owner(mid: 0, name: json['author']);
    styles = json['styles'];
    label = json['label'];
  }
}
