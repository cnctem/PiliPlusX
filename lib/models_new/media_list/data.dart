import 'package:PiliPlus/models_new/media_list/media_list.dart';

class MediaListData {
  List<MediaListItemModel> mediaList;

  MediaListData({
    required this.mediaList,
  });

  factory MediaListData.fromJson(Map<String, dynamic> json) => MediaListData(
    mediaList:
        (json['media_list'] as List<dynamic>?)
            ?.map((e) => MediaListItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <MediaListItemModel>[],
  );
}
