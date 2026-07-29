import 'package:PiliPlus/models_new/live/live_search/user_item.dart';

class User {
  List<LiveSearchUserItemModel>? list;
  int? totalUser;

  User({this.list, this.totalUser});

  factory User.fromJson(Map<String, dynamic> json) => User(
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => LiveSearchUserItemModel.fromJson(e))
        .toList(),
    totalUser: json['total_user'] as int?,
  );
}
