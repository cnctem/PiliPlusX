import 'package:PiliPlus/models_new/blacklist/list.dart';

class BlackListData {
  List<BlackListItem>? list;
  int? total;

  BlackListData({this.list, this.total});

  factory BlackListData.fromJson(Map<String, dynamic> json) => BlackListData(
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => BlackListItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int?,
  );
}
