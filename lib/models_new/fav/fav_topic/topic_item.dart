class FavTopicItem {
  int? id;
  String? name;

  FavTopicItem({
    this.id,
    this.name,
  });

  factory FavTopicItem.fromJson(Map<String, dynamic> json) => FavTopicItem(
    id: json['id'] as int?,
    name: json['name'] as String?,
  );
}
