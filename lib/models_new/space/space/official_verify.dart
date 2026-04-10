import 'package:PiliPlus/models/model_avatar.dart';

class OfficialVerify extends BaseOfficialVerify {
  String? spliceTitle;

  OfficialVerify.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    spliceTitle = json['splice_title'] as String?;
  }
}
