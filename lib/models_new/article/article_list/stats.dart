class Stats {
  int? view;
  int? like;
  int? reply;

  Stats({
    this.view,
    this.like,
    this.reply,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
    view: json['view'] as int?,
    like: json['like'] as int?,
    reply: json['reply'] as int?,
  );
}
