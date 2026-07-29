import 'package:PiliPlus/models_new/fav/fav_article/item.dart';

class FavArticleData {
  List<FavArticleItemModel>? items;
  bool? hasMore;

  FavArticleData({
    this.items,
    this.hasMore,
  });

  factory FavArticleData.fromJson(Map<String, dynamic> json) => FavArticleData(
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => FavArticleItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    hasMore: json['has_more'] as bool?,
  );
}
