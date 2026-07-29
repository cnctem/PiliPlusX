import 'package:PiliPlus/models/model_owner.dart';

class Guard {
  String? uri;
  Object? count;
  List<Owner>? item;

  Guard.fromJson(Map<String, dynamic> json) {
    uri = json['uri'] as String?;
    item = (json['item'] as List<dynamic>?)
        ?.map((e) => Owner.fromJson(e as Map<String, dynamic>))
        .toList();
    final String? desc = json['desc'];
    if (desc != null) {
      count = RegExp(r'^(\d+)').firstMatch(desc)?.group(1);
    }
  }
}
