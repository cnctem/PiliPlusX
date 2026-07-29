import 'package:PiliPlus/models_new/space/space_fav/media_list_response.dart';

class SpaceFavData {
  int? id;
  String? name;
  MediaListResponse? mediaListResponse;

  SpaceFavData({this.id, this.name, this.mediaListResponse});

  factory SpaceFavData.fromJson(Map<String, dynamic> json) => SpaceFavData(
    id: json['id'] as int?,
    name: json['name'] as String?,
    mediaListResponse: json['mediaListResponse'] == null
        ? null
        : MediaListResponse.fromJson(
            json['mediaListResponse'] as Map<String, dynamic>,
          ),
  );
}
