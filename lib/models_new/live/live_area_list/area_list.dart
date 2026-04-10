import 'package:PiliPlus/models_new/live/live_area_list/area_item.dart';

class AreaList {
  String? name;
  List<AreaItem>? areaList;

  AreaList({this.name, this.areaList});

  factory AreaList.fromJson(Map<String, dynamic> json) => AreaList(
    name: json['name'] ?? '',
    areaList: (json['area_list'] as List<dynamic>?)
        ?.map((e) => AreaItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
