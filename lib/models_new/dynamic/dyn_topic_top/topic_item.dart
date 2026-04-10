class TopicItem {
  int id;
  String name;
  int view;
  int discuss;
  int fav;
  int like;
  String? description;
  bool? isFav;
  bool? isLike;

  TopicItem({
    required this.id,
    required this.name,
    required this.view,
    required this.discuss,
    required this.fav,
    required this.like,
    this.description,
    this.isFav,
    this.isLike,
  });

  factory TopicItem.fromJson(Map<String, dynamic> json) => TopicItem(
    id: json['id'],
    name: json['name'],
    view: json['view'] ?? 0,
    discuss: json['discuss'] ?? 0,
    fav: json['fav'] ?? 0,
    like: json['like'] ?? 0,
    description: json['description'] as String?,
    isFav: json['is_fav'] as bool?,
    isLike: json['is_like'] as bool?,
  );
}
