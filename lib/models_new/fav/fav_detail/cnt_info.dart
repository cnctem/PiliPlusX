class CntInfo {
  int? play;
  int? danmaku;

  CntInfo({
    this.play,

    this.danmaku,
  });

  factory CntInfo.fromJson(Map<String, dynamic> json) => CntInfo(
    play: json['play'] as int?,
    danmaku: json['danmaku'] as int?,
  );
}
