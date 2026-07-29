import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models_new/video/video_detail/dimension.dart';
import 'package:PiliPlus/models_new/video/video_detail/stat.dart';

class Arc {
  int? aid;
  String? pic;
  String? title;
  int? pubdate;
  int? duration;
  Owner? author;
  VideoStat? stat;
  Dimension? dimension;

  Arc({
    this.aid,
    this.pic,
    this.title,
    this.pubdate,
    this.duration,
    this.author,
    this.stat,
    this.dimension,
  });

  factory Arc.fromJson(Map<String, dynamic> json) => Arc(
    aid: json['aid'] as int?,
    pic: json['pic'] as String?,
    title: json['title'] as String?,
    pubdate: json['pubdate'] as int?,
    duration: json['duration'] as int?,
    author: json['author'] == null
        ? null
        : Owner.fromJson(json['author'] as Map<String, dynamic>),
    stat: json['stat'] == null
        ? null
        : VideoStat.fromJson(json['stat'] as Map<String, dynamic>),
    dimension: json['dimension'] == null
        ? null
        : Dimension.fromJson(json['dimension'] as Map<String, dynamic>),
  );
}
