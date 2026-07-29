class UpInfo {
  String? avatar;
  int? mid;
  String? uname;

  UpInfo({
    this.avatar,
    this.mid,
    this.uname,
  });

  factory UpInfo.fromJson(Map<String, dynamic> json) => UpInfo(
    avatar: json['avatar'] as String?,
    mid: json['mid'] as int?,
    uname: json['uname'] as String?,
  );
}
