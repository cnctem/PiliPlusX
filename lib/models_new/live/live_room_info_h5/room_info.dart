class RoomInfo {
  int? uid;
  String? title;
  String? cover;
  String? appBackground;

  RoomInfo({
    this.uid,
    this.title,
    this.cover,
    this.appBackground,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) => RoomInfo(
    uid: json['uid'] as int?,
    title: json['title'] as String?,
    cover: json['cover'] as String?,
    appBackground: json['app_background'] as String?,
  );
}
