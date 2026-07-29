import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract final class ConnectivityUtils {
  static Future<bool> get isWiFi async {
    try {
      // connectivity_plus 5.x 返回单值（鸿蒙适配版本），非上游 7.x 的 List
      // 鸿蒙上 checkConnectivity 可能抛异常，catch 后按 wifi 处理
      return PlatformUtils.isMobile &&
          (await Connectivity().checkConnectivity()) == ConnectivityResult.wifi;
    } catch (_) {
      return true;
    }
  }
}
