import 'package:PiliPlus/models_new/later/season.dart';

class Bangumi {
  int? epId;
  Season? season;

  Bangumi({
    this.epId,
    this.season,
  });

  factory Bangumi.fromJson(Map<String, dynamic> json) => Bangumi(
    epId: json['ep_id'] as int?,
    season: json['season'] == null
        ? null
        : Season.fromJson(json['season'] as Map<String, dynamic>),
  );
}
