import 'package:PiliPlus/models_new/user_real_name/reject_page.dart';

class UserRealNameData {
  String? name;
  RejectPage? rejectPage;

  UserRealNameData({this.name, this.rejectPage});

  factory UserRealNameData.fromJson(Map<String, dynamic> json) =>
      UserRealNameData(
        name: json['name'] as String?,
        rejectPage: json['reject_page'] == null
            ? null
            : RejectPage.fromJson(json['reject_page'] as Map<String, dynamic>),
      );
}
