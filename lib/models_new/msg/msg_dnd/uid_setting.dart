class UidSetting {
  int? setting;

  UidSetting({this.setting});

  factory UidSetting.fromJson(Map<String, dynamic> json) => UidSetting(
    setting: json['setting'] as int?,
  );
}
