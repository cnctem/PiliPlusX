import 'package:PiliPlus/models_new/live/live_search/room_item.dart';

class Room {
  List<LiveSearchRoomItemModel>? list;
  int? totalRoom;

  Room({this.list, this.totalRoom});

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    list: (json['list'] as List<dynamic>?)
        ?.map(
          (e) => LiveSearchRoomItemModel.fromJson(e as Map<String, dynamic>),
        )
        .toList(),
    totalRoom: json['total_room'] as int?,
  );
}
