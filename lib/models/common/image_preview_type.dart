import 'package:PiliPlus/common/constants.dart';

enum SourceType { fileImage, networkImage, livePhoto }

class SourceModel {
  final SourceType sourceType;
  final String url;
  final String? liveUrl;
  final int? width;
  final int? height;

  const SourceModel({
    this.sourceType = SourceType.networkImage,
    required this.url,
    this.liveUrl,
    this.width,
    this.height,
  });

  bool get isLongPic {
    if (width != null && height != null) {
      return height! / width! > StyleString.imgMaxRatio;
    }
    return false;
  }
}
