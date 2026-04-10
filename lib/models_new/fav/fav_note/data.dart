import 'package:PiliPlus/models_new/fav/fav_note/list.dart';

class FavNoteData {
  List<FavNoteItemModel>? list;

  FavNoteData({this.list});

  factory FavNoteData.fromJson(Map<String, dynamic> json) => FavNoteData(
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => FavNoteItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
