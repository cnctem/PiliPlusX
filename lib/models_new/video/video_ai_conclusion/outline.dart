import 'package:PiliPlus/models_new/video/video_ai_conclusion/part_outline.dart';

class Outline {
  String? title;
  List<PartOutline>? partOutline;

  Outline({this.title, this.partOutline});

  factory Outline.fromJson(Map<String, dynamic> json) => Outline(
    title: json['title'] as String?,
    partOutline: (json['part_outline'] as List<dynamic>?)
        ?.map((e) => PartOutline.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
