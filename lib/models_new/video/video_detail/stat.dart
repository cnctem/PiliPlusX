import 'package:PiliPlus/models_new/video/video_detail/stat_detail.dart';

class VideoStat extends StatDetail {
  VideoStat.fromJson(Map<String, dynamic> json) {
    view = json['view'] as int?;
    danmaku = json['danmaku'] as int?;
    reply = json['reply'] as int?;
    favorite = json['favorite'] as int? ?? 0;
    coin = json['coin'] as num? ?? 0;
    share = json['share'] as int?;
    like = json['like'] as int? ?? 0;
  }
}
