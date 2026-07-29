import 'package:PiliPlus/models_new/article/article_list/stats.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';

class ArticleListItemModel {
  int? id;
  String? title;
  List<String>? imageUrls;
  String? summary;
  String? dynIdStr;
  Stats? stats;

  ArticleListItemModel({
    this.id,
    this.title,
    this.imageUrls,
    this.summary,
    this.dynIdStr,
    this.stats,
  });

  factory ArticleListItemModel.fromJson(Map<String, dynamic> json) =>
      ArticleListItemModel(
        id: json['id'] as int?,
        title: json['title'] as String?,
        imageUrls: (json['image_urls'] as List?)?.fromCast(),
        summary: json['summary'] as String?,
        dynIdStr: json['dyn_id_str'] as String?,
        stats: json['stats'] == null
            ? null
            : Stats.fromJson(json['stats'] as Map<String, dynamic>),
      );
}
