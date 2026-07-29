import 'package:PiliPlus/models_new/live/live_search/room.dart';
import 'package:PiliPlus/models_new/live/live_search/user.dart';

class LiveSearchData {
  Room? room;
  User? user;

  LiveSearchData({
    this.room,
    this.user,
  });

  factory LiveSearchData.fromJson(Map<String, dynamic> json) => LiveSearchData(
    room: json['room'] == null
        ? null
        : Room.fromJson(json['room'] as Map<String, dynamic>),
    user: json['user'] == null
        ? null
        : User.fromJson(json['user'] as Map<String, dynamic>),
  );
}
