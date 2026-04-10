import 'package:PiliPlus/models/model_avatar.dart';

class Card {
  String? mid;
  String? name;
  String? face;
  BaseOfficialVerify? official;
  Vip? vip;

  Card({
    this.mid,
    this.name,
    this.face,
    this.official,
    this.vip,
  });

  factory Card.fromJson(Map<String, dynamic> json) => Card(
    mid: json['mid'] as String?,
    name: json['name'] as String?,
    face: json['face'] as String?,
    official: json['Official'] == null
        ? null
        : BaseOfficialVerify.fromJson(
            json['Official'] as Map<String, dynamic>,
          ),
    vip: json['vip'] == null
        ? null
        : Vip.fromJson(json['vip'] as Map<String, dynamic>),
  );
}
