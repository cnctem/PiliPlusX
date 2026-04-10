import 'package:PiliPlus/models_new/space/space_article/stats.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';

class SpaceArticleItem {
  String? title;
  Stats? stats;
  List<String>? originImageUrls;
  String? uri;
  String? publishTimeText;

  SpaceArticleItem({
    this.title,
    this.stats,
    this.originImageUrls,
    this.uri,
    this.publishTimeText,
  });

  factory SpaceArticleItem.fromJson(Map<String, dynamic> json) =>
      SpaceArticleItem(
        title: json['title'] as String?,
        stats: json['stats'] == null
            ? null
            : Stats.fromJson(json['stats'] as Map<String, dynamic>),
        originImageUrls: (json['origin_image_urls'] as List?)?.fromCast(),
        uri: json['uri'] as String?,
        publishTimeText: json['publish_time_text'] as String?,
      );
}
