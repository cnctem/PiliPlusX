import 'package:PiliPlus/models_new/member_guard/guard_top_list.dart';

class MemberGuardData {
  List<GuardItem> guardTopList;
  int? hasMore;

  MemberGuardData({
    required this.guardTopList,
    this.hasMore,
  });

  factory MemberGuardData.fromJson(Map<String, dynamic> json) =>
      MemberGuardData(
        guardTopList: (json['guard_top_list'] as List<dynamic>)
            .map((e) => GuardItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: json['has_more'] as int?,
      );
}
