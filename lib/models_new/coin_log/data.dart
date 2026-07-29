import 'package:PiliPlus/models_new/coin_log/list.dart';

class CoinLogData {
  CoinLogData({this.list});

  List<CoinLogItem>? list;

  factory CoinLogData.fromJson(Map<String, dynamic> json) => CoinLogData(
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => CoinLogItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
