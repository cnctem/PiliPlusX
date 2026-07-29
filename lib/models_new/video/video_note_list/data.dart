import 'package:PiliPlus/models_new/video/video_note_list/list.dart';
import 'package:PiliPlus/models_new/video/video_note_list/page.dart';

class VideoNoteData {
  List<VideoNoteItemModel>? list;
  Page? page;

  VideoNoteData({this.list, this.page});

  factory VideoNoteData.fromJson(Map<String, dynamic> json) => VideoNoteData(
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => VideoNoteItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: json['page'] == null
        ? null
        : Page.fromJson(json['page'] as Map<String, dynamic>),
  );
}
