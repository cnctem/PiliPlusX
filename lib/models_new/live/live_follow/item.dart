class LiveFollowItem {
  int? roomid;
  String? uname;
  String? title;
  String? areaName;
  String? textSmall;
  String? roomCover;

  LiveFollowItem({
    this.roomid,
    this.uname,
    this.title,
    this.areaName,
    this.textSmall,
    this.roomCover,
  });

  factory LiveFollowItem.fromJson(Map<String, dynamic> json) => LiveFollowItem(
    roomid: json['roomid'] as int?,
    uname: json['uname'] as String?,
    title: json['title'] as String?,
    areaName: json['area_name'] as String?,
    textSmall: json['text_small'] as String?,
    roomCover: json['room_cover'] as String?,
  );
}
