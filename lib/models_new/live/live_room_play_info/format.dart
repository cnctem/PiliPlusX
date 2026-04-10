import 'package:PiliPlus/models_new/live/live_room_play_info/codec.dart';

class Format {
  List<CodecItem>? codec;

  Format({this.codec});

  factory Format.fromJson(Map<String, dynamic> json) => Format(
    codec: (json['codec'] as List<dynamic>?)
        ?.map((e) => CodecItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
