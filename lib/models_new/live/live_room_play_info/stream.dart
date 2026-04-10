import 'package:PiliPlus/models_new/live/live_room_play_info/format.dart';

class Stream {
  List<Format>? format;

  Stream({this.format});

  factory Stream.fromJson(Map<String, dynamic> json) => Stream(
    format: (json['format'] as List<dynamic>?)
        ?.map((e) => Format.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
