class Statistic {
  int? play;
  int? comment;

  Statistic({this.play, this.comment});

  factory Statistic.fromJson(Map<String, dynamic> json) => Statistic(
    play: json['play'] as int?,
    comment: json['comment'] as int?,
  );
}
