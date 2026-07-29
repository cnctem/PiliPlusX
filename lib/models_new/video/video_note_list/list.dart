import 'package:PiliPlus/models_new/video/video_note_list/author.dart';

class VideoNoteItemModel {
  int? cvid;
  String? summary;
  String? pubtime;
  Author? author;

  VideoNoteItemModel({
    this.cvid,
    this.summary,
    this.pubtime,
    this.author,
  });

  factory VideoNoteItemModel.fromJson(Map<String, dynamic> json) =>
      VideoNoteItemModel(
        cvid: json['cvid'] as int?,
        summary: json['summary'] as String?,
        pubtime: json['pubtime'] as String?,
        author: json['author'] == null
            ? null
            : Author.fromJson(json['author'] as Map<String, dynamic>),
      );
}
