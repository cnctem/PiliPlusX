class CoinLikeArcItem {
  String? title;
  String? cover;
  String? uri;
  String? param;
  int? duration;
  bool? isSteins;
  bool? isCooperation;
  bool? isPgc;
  int? play;
  int? danmaku;
  int? ctime;

  CoinLikeArcItem({
    this.title,
    this.cover,
    this.uri,
    this.param,
    this.duration,
    this.isSteins,
    this.isCooperation,
    this.isPgc,
    this.play,
    this.danmaku,
    this.ctime,
  });

  factory CoinLikeArcItem.fromJson(Map<String, dynamic> json) =>
      CoinLikeArcItem(
        title: json['title'] as String?,
        cover: json['cover'] as String?,
        uri: json['uri'] as String?,
        param: json['param'] as String?,
        duration: json['duration'] as int?,
        isSteins: json['is_steins'] as bool?,
        isCooperation: json['is_cooperation'] as bool?,
        isPgc: json['is_pgc'] as bool?,
        play: json['play'] as int?,
        danmaku: json['danmaku'] as int?,
        ctime: json['ctime'] as int?,
      );
}
