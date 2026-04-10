class Ogv {
  String? typeName;
  int? seasonId;

  Ogv({
    this.typeName,
    this.seasonId,
  });

  factory Ogv.fromJson(Map<String, dynamic> json) => Ogv(
    typeName: json['type_name'],
    seasonId: json['season_id'],
  );
}
