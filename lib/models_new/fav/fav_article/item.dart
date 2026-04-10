import 'package:PiliPlus/models_new/fav/fav_article/author.dart';
import 'package:PiliPlus/models_new/fav/fav_article/cover.dart';
import 'package:PiliPlus/models_new/fav/fav_article/stat.dart';

class FavArticleItemModel {
  String? opusId;
  String? content;
  Author? author;
  Cover? cover;
  Stat? stat;
  String? pubTime;

  FavArticleItemModel({
    this.opusId,
    this.content,
    this.author,
    this.cover,
    this.stat,
    this.pubTime,
  });

  factory FavArticleItemModel.fromJson(Map<String, dynamic> json) =>
      FavArticleItemModel(
        opusId: json['opus_id'] as String?,
        content: json['content'] as String?,
        author: json['author'] == null
            ? null
            : Author.fromJson(json['author'] as Map<String, dynamic>),
        cover: json['cover'] == null
            ? null
            : Cover.fromJson(json['cover'] as Map<String, dynamic>),
        stat: json['stat'] == null
            ? null
            : Stat.fromJson(json['stat'] as Map<String, dynamic>),
        pubTime: json['pub_time'] as String?,
      );
}
