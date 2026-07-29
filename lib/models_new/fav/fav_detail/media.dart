import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/cnt_info.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/ogv.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/ugc.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';

class FavDetailItemModel with MultiSelectData {
  int? id;
  int? type;
  String? title;
  String? cover;
  String? intro;
  int? duration;
  Owner? upper;
  int? attr;
  CntInfo? cntInfo;
  int? favTime;
  String? bvid;
  Ogv? ogv;
  Ugc? ugc;

  FavDetailItemModel({
    this.id,
    this.type,
    this.title,
    this.cover,
    this.intro,
    this.duration,
    this.upper,
    this.attr,
    this.cntInfo,
    this.favTime,
    this.bvid,
    this.ogv,
    this.ugc,
  });

  factory FavDetailItemModel.fromJson(Map<String, dynamic> json) =>
      FavDetailItemModel(
        id: json['id'] as int?,
        type: json['type'] as int?,
        title: json['title'] as String?,
        cover: json['cover'] as String?,
        intro: json['intro'] as String?,
        duration: json['duration'] as int?,
        upper: json['upper'] == null
            ? null
            : Owner.fromJson(json['upper'] as Map<String, dynamic>),
        attr: json['attr'] as int?,
        cntInfo: json['cnt_info'] == null
            ? null
            : CntInfo.fromJson(json['cnt_info'] as Map<String, dynamic>),
        favTime: json['fav_time'] as int?,
        bvid: json['bvid'] ?? json['bv_id'],
        ogv: json['ogv'] == null ? null : Ogv.fromJson(json['ogv']),
        ugc: json['ugc'] == null
            ? null
            : Ugc.fromJson(json['ugc'] as Map<String, dynamic>),
      );
}
