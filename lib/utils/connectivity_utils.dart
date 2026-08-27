import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract final class ConnectivityUtils {
  /// 已知的档位：true = 蜂窝档，false = 宽带档，null = 尚未确定过
  static bool? _scope;
  // 应用级观察者，与进程同生命周期
  // ignore: cancel_subscriptions
  static StreamSubscription? _subscription;
  static Timer? _debounce;
  static final _controller = StreamController<bool>.broadcast();

  /// 档位翻转事件，携带新的 [useCellularPrefs] 值。
  ///
  /// 只在「宽带档 ↔ 蜂窝档」真正翻转时才发：Wi-Fi 与有线之间互切不发；断网
  /// （[ConnectivityResult.none]）与插件取值失败不发，保持最后一次已知档位，
  /// 避免网络抖动把播放器反复重建。
  static Stream<bool> get onScopeChanged => _controller.stream;

  /// 当前链路是否应当套用「蜂窝」这一档偏好（画质 / 音质 / 编码 / 直播清晰度）。
  ///
  /// 只看链路类型，不做任何弱网判断：Wi-Fi、有线、VPN 一律归入宽带档，只有
  /// [ConnectivityResult.mobile] 才是蜂窝档。
  ///
  /// 注意不能像上游那样用 `PlatformUtils.isMobile` 做前置守卫：`os_type` 把鸿蒙
  /// 2in1 判定为 PC（`isPCOS == (_harmonyDeviceType == '2in1')`），带上该守卫会让
  /// 2in1 设备恒落在蜂窝档，导致画质 / 音质设置写入 Cellular 键却从非 Cellular 键
  /// 读回（退出重进即丢失），听视频页也会永远使用蜂窝音质。
  static Future<bool> get useCellularPrefs async {
    _ensureWatching();
    try {
      // connectivity_plus 5.x 返回单值（鸿蒙适配版本），非上游 7.x 的 List
      // 鸿蒙上 checkConnectivity 可能抛异常
      final result = await Connectivity().checkConnectivity();
      if (result == ConnectivityResult.none) {
        // 断网：保持已知档位；从未确定过则保守取蜂窝档，避免「无网时进入播放页、
        // 随后连上蜂窝」在收到翻转事件之前先按宽带档拉一段
        _scope ??= true;
      } else {
        _scope = result == ConnectivityResult.mobile;
      }
    } catch (_) {
      // 插件取值失败：保持已知档位；从未确定过则维持既有行为（宽带档），
      // 不因通道异常而让全体用户降质
      _scope ??= false;
    }
    return _scope!;
  }

  /// 按当前链路在「宽带档 / 蜂窝档」两个设置键之间取一个。
  static Future<String> prefKey(String broadband, String cellular) async =>
      await useCellularPrefs ? cellular : broadband;

  static void _ensureWatching() {
    if (_subscription != null) return;
    try {
      // 不读事件负载，只把它当作「该重新采样了」的信号：一来上游 7.x 的负载是
      // List、本地 fork 是单值，二来重新采样比信任负载更稳
      _subscription = Connectivity().onConnectivityChanged.listen(
        (_) {
          _debounce?.cancel();
          _debounce = Timer(
            const Duration(milliseconds: 800),
            _resolveAndNotify,
          );
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      // 鸿蒙上事件通道可能不可用，退化为「仅在进入播放页时判定一次」
    }
  }

  static Future<void> _resolveAndNotify() async {
    final previous = _scope;
    final current = await useCellularPrefs;
    // previous 为 null 说明此前从未确定过档位，不存在「翻转」
    if (previous != null && current != previous) {
      _controller.add(current);
    }
  }
}
