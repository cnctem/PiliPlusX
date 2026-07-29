import 'package:PiliPlus/models_new/video/video_stein_edgeinfo/edges.dart';

class EdgeInfoData {
  Edges? edges;

  EdgeInfoData({
    this.edges,
  });

  factory EdgeInfoData.fromJson(Map<String, dynamic> json) => EdgeInfoData(
    edges: json['edges'] == null
        ? null
        : Edges.fromJson(json['edges'] as Map<String, dynamic>),
  );
}
