import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/cnt_info.dart';
import 'package:PiliPlus/models_new/media_list/page.dart';
import 'package:PiliPlus/models_new/video/video_detail/episode.dart';

class MediaListItemModel extends BaseEpisodeItem {
  @override
  int? get id => aid;
  String? intro;
  CntInfo? cntInfo;
  int? duration;
  List<Page>? pages;
  int? type;
  Owner? upper;
  @override
  int? get cid => pages?.firstOrNull?.id;

  MediaListItemModel({
    super.aid,
    this.intro,
    this.cntInfo,
    super.cover,
    this.duration,
    this.pages,
    super.title,
    this.type,
    this.upper,
    super.bvid,
    super.badge,
    super.cid,
  });

  MediaListItemModel.fromJson(Map<String, dynamic> json) {
    aid = json['id'] as int?;
    intro = json['intro'] as String?;
    cntInfo = json['cnt_info'] == null
        ? null
        : CntInfo.fromJson(json['cnt_info']);
    cover = json['cover'] as String?;
    duration = json['duration'] as int?;
    pages = (json['pages'] as List?)?.map((e) => Page.fromJson(e)).toList();
    title = json['title'] as String?;
    type = json['type'] as int?;
    upper = json['upper'] == null ? null : Owner.fromJson(json['upper']);
    bvid = json['bv_id'] as String?;
    badge = json['badge']?['text'];
  }
}
