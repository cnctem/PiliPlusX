import 'package:PiliPlus/models_new/fav/fav_detail/cnt_info.dart';

class SubDetailItemModel {
  int? id;
  String? title;
  String? cover;
  int? duration;
  int? pubtime;
  String? bvid;
  CntInfo? cntInfo;

  SubDetailItemModel({
    this.id,
    this.title,
    this.cover,
    this.duration,
    this.pubtime,
    this.bvid,
    this.cntInfo,
  });

  factory SubDetailItemModel.fromJson(Map<String, dynamic> json) =>
      SubDetailItemModel(
        id: json['id'] as int?,
        title: json['title'] as String?,
        cover: json['cover'] as String?,
        duration: json['duration'] as int?,
        pubtime: json['pubtime'] as int?,
        bvid: json['bvid'] as String?,
        cntInfo: json['cnt_info'] == null
            ? null
            : CntInfo.fromJson(json['cnt_info'] as Map<String, dynamic>),
      );
}
