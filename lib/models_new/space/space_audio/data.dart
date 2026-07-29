import 'package:PiliPlus/models_new/space/space_audio/item.dart';

class SpaceAudioData {
  int? totalSize;
  List<SpaceAudioItem>? items;

  SpaceAudioData({
    this.totalSize,
    this.items,
  });

  factory SpaceAudioData.fromJson(Map<String, dynamic> json) => SpaceAudioData(
    totalSize: json['totalSize'] as int?,
    items: (json['data'] as List<dynamic>?)
        ?.map((e) => SpaceAudioItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
