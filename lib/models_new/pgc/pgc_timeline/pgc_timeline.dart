import 'package:PiliPlus/models_new/pgc/pgc_timeline/result.dart';

class PgcTimeline {
  List<TimelineResult>? result;

  PgcTimeline({this.result});

  factory PgcTimeline.fromJson(Map<String, dynamic> json) => PgcTimeline(
    result: (json['result'] as List<dynamic>?)
        ?.map((e) => TimelineResult.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
