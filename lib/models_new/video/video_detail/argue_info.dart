class ArgueInfo {
  String? argueMsg;

  ArgueInfo({this.argueMsg});

  factory ArgueInfo.fromJson(Map<String, dynamic> json) => ArgueInfo(
    argueMsg: json['argue_msg'] as String?,
  );
}
