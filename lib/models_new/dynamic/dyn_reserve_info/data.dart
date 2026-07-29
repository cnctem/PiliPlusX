class ReserveInfoData {
  int? id;
  String? title;
  int? livePlanStartTime;

  ReserveInfoData({
    this.id,
    this.title,
    this.livePlanStartTime,
  });

  factory ReserveInfoData.fromJson(Map<String, dynamic> json) =>
      ReserveInfoData(
        id: json['id'] as int?,
        title: json['title'] as String?,
        livePlanStartTime: json['live_plan_start_time'] as int?,
      );
}
