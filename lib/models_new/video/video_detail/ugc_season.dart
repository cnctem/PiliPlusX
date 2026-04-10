import 'package:PiliPlus/models_new/video/video_detail/section.dart';

class UgcSeason {
  int? id;
  String? title;
  String? cover;
  int? mid;
  List<SectionItem>? sections;

  UgcSeason({
    this.id,
    this.title,
    this.cover,
    this.mid,
    this.sections,
  });

  factory UgcSeason.fromJson(Map<String, dynamic> json) => UgcSeason(
    id: json['id'] as int?,
    title: json['title'] as String?,
    cover: json['cover'] as String?,
    mid: json['mid'] as int?,
    sections: (json['sections'] as List<dynamic>?)
        ?.map((e) => SectionItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
