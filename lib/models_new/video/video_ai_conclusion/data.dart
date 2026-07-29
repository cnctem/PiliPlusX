import 'package:PiliPlus/models_new/video/video_ai_conclusion/model_result.dart';

class AiConclusionData {
  AiConclusionResult? modelResult;

  AiConclusionData({
    this.modelResult,
  });

  factory AiConclusionData.fromJson(Map<String, dynamic> json) =>
      AiConclusionData(
        modelResult: json['model_result'] == null
            ? null
            : AiConclusionResult.fromJson(
                json['model_result'] as Map<String, dynamic>,
              ),
      );
}
