class LoginDevice {
  String? deviceName;
  bool? isCurrentDevice;
  String? latestLoginAt;
  String? source;

  LoginDevice({
    this.deviceName,
    this.isCurrentDevice,
    this.latestLoginAt,
    this.source,
  });

  factory LoginDevice.fromJson(Map<String, dynamic> json) => LoginDevice(
    deviceName: json['device_name'] as String?,
    isCurrentDevice: json['is_current_device'] as bool?,
    latestLoginAt: json['latest_login_at'] as String?,
    source: json['source'] as String?,
  );
}
