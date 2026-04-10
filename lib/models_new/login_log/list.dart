class LoginLogItem {
  final String ip;
  final String timeAt;
  final String geo;

  const LoginLogItem({
    required this.ip,
    required this.timeAt,
    required this.geo,
  });

  factory LoginLogItem.fromJson(Map<String, dynamic> json) => LoginLogItem(
    ip: json['ip'] ?? '',
    timeAt: json['time_at'] ?? '',
    geo: json['geo'] ?? '',
  );
}
