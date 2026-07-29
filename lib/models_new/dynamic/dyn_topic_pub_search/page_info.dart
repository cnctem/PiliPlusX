class PageInfo {
  bool? hasMore;

  PageInfo({this.hasMore});

  factory PageInfo.fromJson(Map<String, dynamic> json) => PageInfo(
    hasMore: json['has_more'] as bool?,
  );
}
