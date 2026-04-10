class Stat {
  int? view;
  int? danmaku;

  Stat({
    this.view,
    this.danmaku,
  });

  factory Stat.fromJson(Map<String, dynamic> json) => Stat(
    view: json['view'] as int?,
    danmaku: json['danmaku'] as int?,
  );
}
