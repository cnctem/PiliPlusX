class CoinLogItem {
  const CoinLogItem({
    required this.time,
    required this.delta,
    required this.reason,
  });

  final String time;
  final String delta;
  final String reason;

  factory CoinLogItem.fromJson(Map<String, dynamic> json) => CoinLogItem(
    time: json['time'],
    delta: (json['delta'] as num).toString(),
    reason: json['reason'],
  );
}
