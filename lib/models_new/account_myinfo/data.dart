class AccountMyInfoData {
  int? mid;
  String? name;
  String? sign;
  num? coins;
  String? birthday;
  String? face;
  int? sex;

  AccountMyInfoData({
    this.mid,
    this.name,
    this.sign,
    this.coins,
    this.birthday,
    this.face,
    this.sex,
  });

  factory AccountMyInfoData.fromJson(Map<String, dynamic> json) =>
      AccountMyInfoData(
        mid: json['mid'] as int?,
        name: json['name'] as String?,
        sign: json['sign'] as String?,
        coins: json['coins'] as num?,
        birthday: json['birthday'] as String?,
        face: json['face'] as String?,
        sex: json['sex'] as int?,
      );
}
