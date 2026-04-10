class Page {
  int? total;

  Page({this.total});

  factory Page.fromJson(Map<String, dynamic> json) => Page(
    total: json['total'] as int?,
  );
}
