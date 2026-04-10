import 'package:PiliPlus/models_new/live/live_room_play_info/url_info.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';

class CodecItem {
  int? currentQn;
  List<int>? acceptQn;
  String? baseUrl;
  List<UrlInfo>? urlInfo;

  CodecItem({
    this.currentQn,
    this.acceptQn,
    this.baseUrl,
    this.urlInfo,
  });

  factory CodecItem.fromJson(Map<String, dynamic> json) => CodecItem(
    currentQn: json['current_qn'] as int?,
    acceptQn: (json['accept_qn'] as List?)?.fromCast(),
    baseUrl: json['base_url'] as String?,
    urlInfo: (json['url_info'] as List<dynamic>?)
        ?.map((e) => UrlInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
