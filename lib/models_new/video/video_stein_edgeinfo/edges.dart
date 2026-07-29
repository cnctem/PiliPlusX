import 'package:PiliPlus/models_new/video/video_stein_edgeinfo/question.dart';

class Edges {
  List<Question>? questions;

  Edges({this.questions});

  factory Edges.fromJson(Map<String, dynamic> json) => Edges(
    questions: (json['questions'] as List<dynamic>?)
        ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
