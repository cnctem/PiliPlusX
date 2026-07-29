import 'package:PiliPlus/models_new/live/live_medal_wall/item.dart';

class MedalWallData {
  List<MedalWallItem>? list;
  int? count;
  String? name;
  String? icon;

  MedalWallData({
    this.list,
    this.count,
    this.name,
    this.icon,
  });

  factory MedalWallData.fromJson(Map<String, dynamic> json) => MedalWallData(
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => MedalWallItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    count: json['count'] as int?,
    name: json['name'] as String?,
    icon: json['icon'] as String?,
  );
}
