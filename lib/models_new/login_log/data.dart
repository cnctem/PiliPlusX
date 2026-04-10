import 'package:PiliPlus/models_new/login_log/list.dart';

class LoginLogData {
  List<LoginLogItem>? list;

  LoginLogData({this.list});

  factory LoginLogData.fromJson(Map<String, dynamic> json) => LoginLogData(
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => LoginLogItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
