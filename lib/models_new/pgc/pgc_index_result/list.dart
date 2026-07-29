class PgcIndexItem {
  String? badge;
  String? cover;
  String? indexShow;
  String? order;
  int? seasonId;
  String? title;

  PgcIndexItem({
    this.badge,
    this.cover,
    this.indexShow,
    this.order,
    this.seasonId,
    this.title,
  });

  factory PgcIndexItem.fromJson(Map<String, dynamic> json) => PgcIndexItem(
    badge: json['badge'] as String?,
    cover: json['cover'] as String?,
    indexShow: json['index_show'] as String?,
    order: json['order'] as String?,
    seasonId: json['season_id'] as int?,
    title: json['title'] as String?,
  );
}
