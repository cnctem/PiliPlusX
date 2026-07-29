import 'package:PiliPlus/models_new/article/article_info/stats.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';

class ArticleInfoData {
  bool? favorite;
  Stats? stats;
  String? title;
  List<String>? originImageUrls;

  ArticleInfoData({
    this.favorite,
    this.stats,
    this.title,
    this.originImageUrls,
  });

  factory ArticleInfoData.fromJson(Map<String, dynamic> json) =>
      ArticleInfoData(
        favorite: json['favorite'] as bool?,
        stats: json['stats'] == null
            ? null
            : Stats.fromJson(json['stats'] as Map<String, dynamic>),
        title: json['title'] as String?,
        originImageUrls: (json['origin_image_urls'] as List?)?.fromCast(),
      );
}
