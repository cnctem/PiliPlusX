class ArticleListInfo {
  int? id;
  String? name;
  String? imageUrl;
  int? updateTime;
  int? words;
  int? read;
  int? articlesCount;

  ArticleListInfo({
    this.id,
    this.name,
    this.imageUrl,
    this.updateTime,
    this.words,
    this.read,
    this.articlesCount,
  });

  factory ArticleListInfo.fromJson(Map<String, dynamic> json) =>
      ArticleListInfo(
        id: json['id'] as int?,
        name: json['name'] as String?,
        imageUrl: json['image_url'] as String?,
        updateTime: json['update_time'] as int?,
        words: json['words'] as int?,
        read: json['read'] as int?,
        articlesCount: json['articles_count'] as int?,
      );
}
