import 'package:PiliPlus/models_new/video/video_detail/stat_detail.dart';

class PgcStat extends StatDetail {
  PgcStat.fromJson(Map<String, dynamic> json) {
    coin = json["coins"] ?? 0;
    danmaku = json["danmakus"];
    favorite = json["favorite"] ?? 0;
    like = json["likes"] ?? 0;
    reply = json["reply"];
    share = json["share"];
    view = json["views"];
  }
}
