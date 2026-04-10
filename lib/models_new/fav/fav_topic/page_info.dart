class PageInfo {
  int? total;

  PageInfo({this.total});

  factory PageInfo.fromJson(Map<String, dynamic> json) => PageInfo(
    total: json['total'] as int?,
  );
}
