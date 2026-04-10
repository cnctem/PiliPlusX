import 'package:PiliPlus/models_new/space/space/collection_top_simple.dart';

class SpaceImages {
  String? imgUrl;
  String? nightImgurl;
  CollectionTopSimple? collectionTopSimple;

  SpaceImages({
    this.imgUrl,
    this.nightImgurl,
    this.collectionTopSimple,
  });

  factory SpaceImages.fromJson(Map<String, dynamic> json) => SpaceImages(
    imgUrl: json['imgUrl'] as String?,
    nightImgurl: json['night_imgurl'] as String?,
    collectionTopSimple: json['collection_top_simple'] == null
        ? null
        : CollectionTopSimple.fromJson(
            json['collection_top_simple'] as Map<String, dynamic>,
          ),
  );
}
