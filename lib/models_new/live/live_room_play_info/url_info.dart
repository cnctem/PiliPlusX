class UrlInfo {
  String? host;
  String? extra;

  UrlInfo({this.host, this.extra});

  factory UrlInfo.fromJson(Map<String, dynamic> json) => UrlInfo(
    host: json['host'] as String?,
    extra: json['extra'] as String?,
  );
}
