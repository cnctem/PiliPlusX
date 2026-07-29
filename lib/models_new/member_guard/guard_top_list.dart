class GuardItem {
  int uid;
  String username;
  String face;
  int guardLevel;

  GuardItem({
    required this.uid,
    required this.username,
    required this.face,
    required this.guardLevel,
  });

  factory GuardItem.fromJson(Map<String, dynamic> json) => GuardItem(
    uid: json['uid'],
    username: json['username'],
    face: json['face'],
    guardLevel: json['guard_level'],
  );
}
