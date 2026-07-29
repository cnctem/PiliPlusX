class UpowerRankInfo {
  int? mid;
  String? nickname;
  String? avatar;
  int? day;

  UpowerRankInfo({
    this.mid,
    this.nickname,
    this.avatar,
    this.day,
  });

  factory UpowerRankInfo.fromJson(Map<String, dynamic> json) => UpowerRankInfo(
    mid: json['mid'] as int?,
    nickname: json['nickname'] as String?,
    avatar: json['avatar'] as String?,
    day: json['day'] as int?,
  );
}
