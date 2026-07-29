class Stats {
  int? view;
  int? reply;

  Stats({
    this.view,
    this.reply,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
    view: json['view'] as int?,
    reply: json['reply'] as int?,
  );
}
