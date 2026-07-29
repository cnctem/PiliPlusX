import 'package:PiliPlus/models_new/sub/sub/list.dart';

class SubData {
  List<SubItemModel>? list;
  bool? hasMore;

  SubData({this.list, this.hasMore});

  factory SubData.fromJson(Map<String, dynamic> json) => SubData(
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => SubItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    hasMore: json['has_more'] as bool?,
  );
}
