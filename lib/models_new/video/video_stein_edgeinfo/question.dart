import 'package:PiliPlus/models_new/video/video_stein_edgeinfo/choice.dart';

class Question {
  List<Choice>? choices;

  Question({
    this.choices,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    choices: (json['choices'] as List<dynamic>?)
        ?.map((e) => Choice.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
