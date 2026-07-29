class Stats {
  int? favorite;
  int? like;
  int? reply;
  int? share;

  Stats({
    this.favorite,
    this.like,
    this.reply,
    this.share,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
    favorite: json['favorite'] as int?,
    like: json['like'] as int?,
    reply: json['reply'] as int?,
    share: json['share'] as int?,
  );
}
