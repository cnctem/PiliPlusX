class PopularSeriesConfig {
  String? name;
  String? label;
  int? mediaId;

  PopularSeriesConfig({
    this.name,
    this.label,
    this.mediaId,
  });

  factory PopularSeriesConfig.fromJson(Map<String, dynamic> json) =>
      PopularSeriesConfig(
        name: json['name'] as String?,
        label: json['label'] as String?,
        mediaId: json['media_id'] as int?,
      );
}
