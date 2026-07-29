class ListItem {
  int? payMid;
  int? rank;
  int? trendType;
  String? message;
  int? mid;
  String? uname;
  String? avatar;

  ListItem({
    this.payMid,
    this.rank,
    this.trendType,
    this.message,
    this.mid,
    this.uname,
    this.avatar,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
    payMid: json['pay_mid'] as int?,
    rank: json['rank'] as int?,
    trendType: json['trend_type'] as int?,
    message: json['message'] as String?,
    mid: json['mid'] as int?,
    uname: json['uname'] as String?,
    avatar: json['avatar'] as String?,
  );
}
