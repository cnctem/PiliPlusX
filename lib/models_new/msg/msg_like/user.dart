class User {
  String? nickname;
  String? avatar;

  User({
    this.nickname,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    nickname: json['nickname'] as String?,
    avatar: json['avatar'] as String?,
  );
}
