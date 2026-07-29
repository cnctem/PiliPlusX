class MsgFeedUnreadData {
  int at;
  int like;
  int reply;
  int sysMsg;

  MsgFeedUnreadData({
    required this.at,
    required this.like,
    required this.reply,
    required this.sysMsg,
  });

  factory MsgFeedUnreadData.fromJson(Map<String, dynamic> json) =>
      MsgFeedUnreadData(
        at: json['at'] ?? 0,
        like: json['like'] ?? 0,
        reply: json['reply'] ?? 0,
        sysMsg: json['sys_msg'] ?? 0,
      );
}
