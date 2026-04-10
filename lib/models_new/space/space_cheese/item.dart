import 'package:PiliPlus/utils/extension/iterable_ext.dart';

class SpaceCheeseItem {
  String? cover;
  List<String>? marks;
  int? seasonId;
  String? status;
  String? title;
  String? ctime;

  SpaceCheeseItem({
    this.cover,
    this.marks,
    this.seasonId,
    this.status,
    this.title,
    this.ctime,
  });

  factory SpaceCheeseItem.fromJson(Map<String, dynamic> json) =>
      SpaceCheeseItem(
        cover: json['cover'] as String?,
        marks: (json['marks'] as List?)?.fromCast(),
        seasonId: json['season_id'] as int?,
        status: json['status'] as String?,
        title: json['title'] as String?,
        ctime: json['ctime'] as String?,
      );
}
