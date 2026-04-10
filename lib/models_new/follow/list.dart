import 'package:PiliPlus/models/dynamics/up.dart';
import 'package:PiliPlus/models/model_avatar.dart';

class FollowItemModel extends UpItem {
  int? attribute;
  String? sign;
  BaseOfficialVerify? officialVerify;

  FollowItemModel({
    required super.mid,
    this.attribute,
    super.uname,
    super.face,
    this.sign,
    this.officialVerify,
  });

  factory FollowItemModel.fromJson(Map<String, dynamic> json) =>
      FollowItemModel(
        mid: json['mid'] as int? ?? 0,
        attribute: json['attribute'] as int?,
        uname: json['uname'] as String?,
        face: json['face'] as String?,
        sign: json['sign'] as String?,
        officialVerify: json['official_verify'] == null
            ? null
            : BaseOfficialVerify.fromJson(
                json['official_verify'] as Map<String, dynamic>,
              ),
      );
}
