class SessionSsData {
  int? followStatus;
  int? pushSetting;
  int? showPushSetting;

  SessionSsData({
    this.followStatus,
    this.pushSetting,
    this.showPushSetting,
  });

  factory SessionSsData.fromJson(Map<String, dynamic> json) => SessionSsData(
    followStatus: json['follow_status'] as int?,
    pushSetting: json['push_setting'] as int?,
    showPushSetting: json['show_push_setting'] as int?,
  );
}
