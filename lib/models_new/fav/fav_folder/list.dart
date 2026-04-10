import 'package:PiliPlus/models/model_owner.dart';

class FavFolderInfo {
  int id;
  int? fid;
  int mid;
  int attr;
  String title;
  String cover;
  Owner? upper;
  String? intro;
  int? favState;
  int mediaCount;

  FavFolderInfo({
    this.id = 0,
    this.fid,
    this.mid = 0,
    this.attr = -1,
    this.title = '',
    this.cover = '',
    this.upper,
    this.intro,
    this.favState,
    this.mediaCount = 0,
  });

  factory FavFolderInfo.fromJson(Map<String, dynamic> json) => FavFolderInfo(
    id: json['id'] as int? ?? 0,
    fid: json['fid'] as int?,
    mid: json['mid'] as int? ?? 0,
    attr: json['attr'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    cover: json['cover'] as String? ?? '',
    upper: json['upper'] == null
        ? null
        : Owner.fromJson(json['upper'] as Map<String, dynamic>),
    intro: json['intro'] as String?,
    favState: json['fav_state'] as int?,
    mediaCount: json['media_count'] as int? ?? 0,
  );
}
