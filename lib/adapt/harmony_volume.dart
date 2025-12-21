import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HarmonyVolumeView extends StatefulWidget {
  static HarmonyVolumeCntlr? cntlr;
  final ValueChanged<HarmonyVolumeCntlr> onCreated;

  const HarmonyVolumeView({required this.onCreated, super.key});

  @override
  State<HarmonyVolumeView> createState() => _HarmonyVolumeViewState();
}

class _HarmonyVolumeViewState extends State<HarmonyVolumeView> {
  @override
  Widget build(BuildContext context) {
    return OhosView(
      viewType: 'AVVolumePanel',
      onPlatformViewCreated: (id) {
        widget.onCreated(
          HarmonyVolumeCntlr(MethodChannel('AVVolumePanel_$id')),
        );
      },
    );
  }
}

class HarmonyVolumeCntlr {
  final MethodChannel _channel;
  // Timer _restorePanelTimer = Timer(Duration.zero, () {});

  HarmonyVolumeCntlr(this._channel);

  /// 获取系统音量，范围[0, 1]
  Future<double> getVolume() async {
    return await _channel.invokeMethod('getVolume');
  }

  /// 设置系统音量，范围[0, 1]，会自动截取
  void setVolume(double volume) {
    volume = volume.clamp(0, 1);
    _channel.invokeMethod('setVolume', {'volume': volume});
    // 1秒后取消隐藏音量条
    // _restorePanelTimer.cancel();
    // restorePanelTimer = Timer(Duration(seconds: 1), () {
    //   channel.invokeMethod('restorePanel');
    // });
  }
}
