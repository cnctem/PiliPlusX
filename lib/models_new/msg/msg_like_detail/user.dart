class MsgLikeDetailUser {
  int? mid;
  String? nickname;
  String? avatar;

  MsgLikeDetailUser({
    this.mid,
    this.nickname,
    this.avatar,
  });

  factory MsgLikeDetailUser.fromJson(Map<String, dynamic> json) =>
      MsgLikeDetailUser(
        mid: json['mid'] as int?,
        nickname: json['nickname'] as String?,
        avatar: json['avatar'] as String?,
      );
}
