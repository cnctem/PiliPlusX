class SpaceSsMeta {
  String? cover;
  String? name;
  int? ptime;
  int? total;
  dynamic seasonId;
  dynamic seriesId;

  SpaceSsMeta({
    this.cover,
    this.name,
    this.ptime,
    this.total,
    this.seasonId,
    this.seriesId,
  });

  factory SpaceSsMeta.fromJson(Map<String, dynamic> json) => SpaceSsMeta(
    cover: json["cover"],
    name: json["name"],
    ptime: json["ptime"],
    total: json["total"],
    seasonId: json["season_id"],
    seriesId: json["series_id"],
  );
}
