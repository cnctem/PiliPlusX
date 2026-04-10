import 'package:PiliPlus/models_new/space/space_article/item.dart';

class SpaceArticleData {
  int? count;
  List<SpaceArticleItem>? item;
  int? listsCount;

  SpaceArticleData({this.count, this.item, this.listsCount});

  factory SpaceArticleData.fromJson(Map<String, dynamic> json) =>
      SpaceArticleData(
        count: json['count'] as int?,
        item: (json['item'] as List<dynamic>?)
            ?.map((e) => SpaceArticleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        listsCount: json['lists_count'] as int?,
      );
}
