class BlackListItem {
  int? mid;
  int? mtime;
  String? uname;
  String? face;

  BlackListItem({
    this.mid,
    this.mtime,
    this.uname,
    this.face,
  });

  factory BlackListItem.fromJson(Map<String, dynamic> json) => BlackListItem(
    mid: json['mid'] as int?,
    mtime: json['mtime'] as int?,
    uname: json['uname'] as String?,
    face: json['face'] as String?,
  );
}
