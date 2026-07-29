class DanmakuPost {
  DanmakuPost({
    required this.dmid,
  });

  final int? dmid;

  factory DanmakuPost.fromJson(Map<String, dynamic> json) {
    return DanmakuPost(
      dmid: json["dmid"],
    );
  }
}
