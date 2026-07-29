import 'package:PiliPlus/models_new/dynamic/dyn_mention/item.dart';

class MentionGroup {
  String? groupName;
  List<MentionItem>? items;

  MentionGroup({this.groupName, this.items});

  factory MentionGroup.fromJson(Map<String, dynamic> json) => MentionGroup(
    groupName: json['group_name'] as String?,
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => MentionItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
