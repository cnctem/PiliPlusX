class Stat {
  int? follow;
  int? view;

  Stat({this.follow, this.view});

  factory Stat.fromJson(Map<String, dynamic> json) => Stat(
    follow: (json['follow'] as int?) ?? 0,
    view: (json['view'] as int?) ?? 0,
  );
}
