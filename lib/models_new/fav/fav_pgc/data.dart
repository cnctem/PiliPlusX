import 'package:PiliPlus/models_new/fav/fav_pgc/list.dart';

class FavPgcData {
  List<FavPgcItemModel>? list;
  int? total;

  FavPgcData({this.list, this.total});

  factory FavPgcData.fromJson(Map<String, dynamic> json) => FavPgcData(
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => FavPgcItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int?,
  );
}
