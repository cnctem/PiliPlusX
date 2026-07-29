import 'package:PiliPlus/models_new/space/space_audio/statistic.dart';

class SpaceAudioItem {
  int? id;
  int? uid;
  String? title;
  String? cover;
  int? aid;
  String? bvid;
  int? cid;
  int? ctime;
  Statistic? statistic;

  SpaceAudioItem({
    this.id,
    this.uid,
    this.title,
    this.cover,
    this.aid,
    this.bvid,
    this.cid,
    this.ctime,
    this.statistic,
  });

  factory SpaceAudioItem.fromJson(Map<String, dynamic> json) => SpaceAudioItem(
    id: json['id'] as int?,
    uid: json['uid'] as int?,
    title: json['title'] as String?,
    cover: json['cover'] as String?,
    aid: json['aid'] as int?,
    bvid: json['bvid'] as String?,
    cid: json['cid'] as int?,
    ctime: json['ctime'] as int?,
    statistic: json['statistic'] == null
        ? null
        : Statistic.fromJson(json['statistic'] as Map<String, dynamic>),
  );
}
