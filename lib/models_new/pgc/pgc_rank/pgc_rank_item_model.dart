import 'package:PiliPlus/models_new/pgc/pgc_rank/new_ep.dart';
import 'package:PiliPlus/models_new/pgc/pgc_rank/stat.dart';

class PgcRankItemModel {
  String? cover;
  NewEp? newEp;
  Stat? stat;
  String? title;
  String? url;

  PgcRankItemModel({
    this.cover,
    this.newEp,
    this.stat,
    this.title,
    this.url,
  });

  factory PgcRankItemModel.fromJson(Map<String, dynamic> json) =>
      PgcRankItemModel(
        cover: json['cover'] as String?,
        newEp: json['new_ep'] == null
            ? null
            : NewEp.fromJson(json['new_ep'] as Map<String, dynamic>),
        stat: json['stat'] == null
            ? null
            : Stat.fromJson(json['stat'] as Map<String, dynamic>),
        title: json['title'] as String?,
        url: json['url'] as String?,
      );
}
