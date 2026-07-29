import 'package:PiliPlus/utils/extension/iterable_ext.dart';

class RelationData {
  int? attribute;
  int? mtime;
  List<int>? tag;
  int? special;

  RelationData({
    this.attribute,
    this.mtime,
    this.tag,
    this.special,
  });

  factory RelationData.fromJson(Map<String, dynamic> json) => RelationData(
    attribute: json['attribute'] as int?,
    mtime: json['mtime'] as int?,
    tag: (json['tag'] as List<dynamic>?)?.fromCast(),
    special: json['special'] as int?,
  );
}
