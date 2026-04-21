import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

List<SettingsModel> experimentalSettings = [
  SwitchModel(
    title: '液态玻璃导航栏',
    subtitle: '启用液态玻璃底部导航栏\n没空适配鸿蒙导航栏\n可能有bug，将就用',
    leading: const Icon(Icons.waterfall_chart),
    setKey: SettingBoxKey.enableLGBar,
    defaultVal: false,
    onChanged: (_) => Get.find<MainController>().updateEnableLGBar(),
    // needReboot: true,
  ),
];
