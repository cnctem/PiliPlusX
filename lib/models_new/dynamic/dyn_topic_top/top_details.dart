import 'package:PiliPlus/models_new/dynamic/dyn_topic_top/topic_creator.dart';
import 'package:PiliPlus/models_new/dynamic/dyn_topic_top/topic_item.dart';

class TopDetails {
  TopicItem? topicItem;
  TopicCreator? topicCreator;

  TopDetails({
    this.topicItem,
    this.topicCreator,
  });

  factory TopDetails.fromJson(Map<String, dynamic> json) => TopDetails(
    topicItem: json['topic_item'] == null
        ? null
        : TopicItem.fromJson(json['topic_item'] as Map<String, dynamic>),
    topicCreator: json['topic_creator'] == null
        ? null
        : TopicCreator.fromJson(json['topic_creator'] as Map<String, dynamic>),
  );
}
