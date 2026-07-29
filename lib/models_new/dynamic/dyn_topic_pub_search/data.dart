import 'package:PiliPlus/models_new/dynamic/dyn_topic_pub_search/page_info.dart';
import 'package:PiliPlus/models_new/dynamic/dyn_topic_top/topic_item.dart';

class TopicPubSearchData {
  List<TopicItem>? topicItems;
  PageInfo? pageInfo;

  TopicPubSearchData({
    this.topicItems,
    this.pageInfo,
  });

  factory TopicPubSearchData.fromJson(Map<String, dynamic> json) =>
      TopicPubSearchData(
        topicItems: (json['topic_items'] as List<dynamic>?)
            ?.map((e) => TopicItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        pageInfo: json['page_info'] == null
            ? null
            : PageInfo.fromJson(json['page_info'] as Map<String, dynamic>),
      );
}
