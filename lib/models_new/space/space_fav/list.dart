import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models_new/sub/sub/list.dart';

class SpaceFavItemModel extends SubItemModel {
  int? mediaId;
  int? count;
  int? isPublic;

  SpaceFavItemModel({
    super.id,
    this.mediaId,
    this.count,
    this.isPublic,
    super.fid,
    super.mid,
    super.attr,
    super.title,
    super.cover,
    super.upper,
    super.coverType,
    super.intro,
    super.ctime,
    super.mtime,
    super.state,
    super.favState,
    super.mediaCount,
    super.viewCount,
    super.type,
  });

  factory SpaceFavItemModel.fromJson(Map<String, dynamic> json) =>
      SpaceFavItemModel(
        id: json['id'] as int?,
        mediaId: json['media_id'] as int?,
        count: json['count'] as int?,
        isPublic: json['is_public'] as int?,
        fid: json['fid'] as int?,
        mid: json['mid'] as int?,
        attr: json['attr'] as int?,
        title: json['title'] as String?,
        cover: json['cover'] as String?,
        upper: json['upper'] == null
            ? null
            : Owner.fromJson(json['upper'] as Map<String, dynamic>),
        coverType: json['cover_type'] as int?,
        intro: json['intro'] as String?,
        ctime: json['ctime'] as int?,
        mtime: json['mtime'] as int?,
        state: json['state'] as int?,
        favState: json['fav_state'] as int?,
        mediaCount: json['media_count'] as int?,
        viewCount: json['view_count'] as int?,
        type: json['type'] as int?,
      );
}
