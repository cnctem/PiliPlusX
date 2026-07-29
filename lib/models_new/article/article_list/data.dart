import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models_new/article/article_list/article.dart';
import 'package:PiliPlus/models_new/article/article_list/list.dart';

class ArticleListData {
  ArticleListInfo? list;
  List<ArticleListItemModel>? articles;
  Owner? author;

  ArticleListData({
    this.list,
    this.articles,
    this.author,
  });

  factory ArticleListData.fromJson(Map<String, dynamic> json) =>
      ArticleListData(
        list: json['list'] == null
            ? null
            : ArticleListInfo.fromJson(json['list'] as Map<String, dynamic>),
        articles: (json['articles'] as List<dynamic>?)
            ?.map(
              (e) => ArticleListItemModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        author: json['author'] == null
            ? null
            : Owner.fromJson(json['author'] as Map<String, dynamic>),
      );
}
