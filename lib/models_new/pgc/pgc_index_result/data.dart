import 'package:PiliPlus/models_new/pgc/pgc_index_result/list.dart';

class PgcIndexResult {
  int? hasNext;
  List<PgcIndexItem>? list;

  PgcIndexResult({this.hasNext, this.list});

  factory PgcIndexResult.fromJson(Map<String, dynamic> json) => PgcIndexResult(
    hasNext: json['has_next'] as int?,
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => PgcIndexItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
