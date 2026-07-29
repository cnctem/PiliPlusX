import 'package:PiliPlus/models_new/video/video_ai_conclusion/outline.dart';

class AiConclusionResult {
  String? summary;
  List<Outline>? outline;

  AiConclusionResult({
    this.summary,
    this.outline,
  });

  factory AiConclusionResult.fromJson(Map<String, dynamic> json) =>
      AiConclusionResult(
        summary: json['summary'] as String?,
        outline: (json['outline'] as List<dynamic>?)
            ?.map((e) => Outline.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
