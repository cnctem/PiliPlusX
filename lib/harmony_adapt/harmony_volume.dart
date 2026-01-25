import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class HarmonyVolumeView extends StatefulWidget {
  static HarmonyVolumeCntlr? _cntlr;

  static HarmonyVolumeCntlr get cntlr {
    if (_cntlr == null) {
      throw '需要在更根部的位置插入HarmonyVolumeView来创建控制器';
    }
    return _cntlr!;
  }

  const HarmonyVolumeView({super.key});

  @override
  State<HarmonyVolumeView> createState() => _HarmonyVolumeViewState();
}

class _HarmonyVolumeViewState extends State<HarmonyVolumeView> {
  @override
  Widget build(BuildContext context) {
    return OhosView(
      viewType: 'AVVolumePanel',
      onPlatformViewCreated: (id) {
        if (HarmonyVolumeView._cntlr != null) {
          throw '请勿重复创建HarmonyVolumeView';
        }
        HarmonyVolumeView._cntlr = HarmonyVolumeCntlr(
          MethodChannel('AVVolumePanel_$id'),
        );
      },
    );
  }
}

class HarmonyVolumeCntlr {
  final MethodChannel _channel;

  HarmonyVolumeCntlr(this._channel);

  void addListener(void Function(double value) listener) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onVolumeChange') {
        final volumeNum = call.arguments['volume'] as num;
        listener(volumeNum.toDouble());
      }
    });
  }

  /// 获取系统音量，范围[0, 1]
  Future<double?> getVolume() async {
    final volume = await _channel.invokeMethod<num>('getVolume');
    return volume?.toDouble();
  }

  /// 设置系统音量，范围[0, 1]，会自动截取
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0, 1);
    setPanleVisible(false); // 隐藏面板
    try {
      await _channel.invokeMethod('setVolume', {'volume': volume});
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  void setPanleVisible(bool visible) {
    _channel.invokeMethod('setPanelVisible', {'visible': visible});
  }
}
