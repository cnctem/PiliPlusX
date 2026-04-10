import 'package:PiliPlus/models_new/dynamic/dyn_topic_feed/all_sort_by.dart';

class TopicSortByConf {
  List<AllSortBy>? allSortBy;
  int? showSortBy;

  TopicSortByConf({this.allSortBy, this.showSortBy});

  factory TopicSortByConf.fromJson(Map<String, dynamic> json) {
    return TopicSortByConf(
      allSortBy: (json['all_sort_by'] as List<dynamic>?)
          ?.map((e) => AllSortBy.fromJson(e as Map<String, dynamic>))
          .toList(),
      showSortBy: json['show_sort_by'] as int?,
    );
  }
}
