class LevelInfo {
  int? privilegeType;
  String? name;
  int? memberTotal;

  LevelInfo({this.privilegeType, this.name, this.memberTotal});

  factory LevelInfo.fromJson(Map<String, dynamic> json) => LevelInfo(
    privilegeType: json['privilege_type'] as int?,
    name: json['name'] as String?,
    memberTotal: json['member_total'] as int?,
  );
}
