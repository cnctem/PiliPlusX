class Page {
  int? count;

  Page({this.count});

  factory Page.fromJson(Map<String, dynamic> json) => Page(
    count: json['count'] as int?,
  );
}
