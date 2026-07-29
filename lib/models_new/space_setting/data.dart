import 'package:PiliPlus/models_new/space_setting/privacy.dart';

class SpaceSettingData {
  Privacy? privacy;

  SpaceSettingData({this.privacy});

  factory SpaceSettingData.fromJson(Map<String, dynamic> json) =>
      SpaceSettingData(
        privacy: json['privacy'] == null
            ? null
            : Privacy.fromJson(json['privacy'] as Map<String, dynamic>),
      );
}
