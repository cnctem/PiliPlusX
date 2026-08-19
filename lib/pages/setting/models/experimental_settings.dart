import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/widgets/multi_select_dialog.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

const Map<String, String> pageName = {
  "/": "首页",
  "/videoV": "视频播放",
  "/home": "首页(推荐)",
  "/hot": "热门",
  "/search": "搜索",
  "/searchResult": "搜索结果",
  "/fav": "收藏夹",
  "/favDetail": "收藏内容",
  "/favSearch": "收藏搜索",
  "/dynamics": "动态",
  "/dynamicDetail": "动态详情",
  "/history": "历史记录",
  "/historySearch": "历史搜索",
  "/later": "稍后再看",
  "/laterSearch": "稍后再看搜索",
  "/member": "用户中心",
  "/follow": "关注列表",
  "/followSearch": "关注搜索",
  "/fan": "粉丝列表",
  "/whisper": "私信",
  "/whisperDetail": "私信详情",
  "/replyMe": "回复我的",
  "/atMe": "提到的我",
  "/likeMe": "收到的赞",
  "/msgLikeDetail": "点赞详情",
  "/sysMsg": "系统消息",
  "/loginPage": "登录",
  "/liveRoom": "直播间",
  "/webview": "网页浏览",
  "/articlePage": "专栏阅读",
  "/articleList": "专栏列表",
  "/download": "下载管理",
  "/subscription": "订阅",
  "/subDetail": "订阅详情",
  "/myReply": "我的回复",
  "/blackListPage": "黑名单",
  "/editProfile": "资料编辑",
  "/logs": "运行日志",
  "/memberDynamics": "用户动态",
  "/followed": "共同关注",
  "/memberSearch": "用户搜索",
  "/dynTopic": "动态话题",
  "/musicDetail": "音乐详情",
  "/audio": "音频播放",
  "/mainReply": "评论详情",
  "/popularSeries": "入站必刷",
};

Future<void> _showAntiPeepDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<Set<String>>(
    context: context,
    builder: (context) => MultiSelectDialog<String>(
      title: '防窥页面选择',
      initValues: Pref.antiPeep.split(","),
      values: pageName,
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.antiPeep,
      res.join(','),
    );
    setState();
  }
}

List<SettingsModel> experimentalSettings = [
  SwitchModel(
    title: '鸿蒙沉浸光感导航栏',
    subtitle: '使用鸿蒙的悬浮页签栏与沉浸光感\n仅在鸿蒙6.1及以上支持，不支持的平台会回退到传统底栏\n开启平板适配后在横屏模式下不显示',
    leading: const Icon(Icons.water_drop_outlined),
    setKey: SettingBoxKey.enableHdsBar,
    defaultVal: false,
    onChanged: (_) => SmartDialog.showToast("重启生效"),
  ),
  SwitchModel(
    title: '鸿蒙沉浸光感顶栏',
    subtitle: '使用鸿蒙沉浸光感顶栏\n仅鸿蒙7及以上支持，不支持则自动回退',
    leading: const Icon(Icons.blur_on_outlined),
    setKey: SettingBoxKey.enableHdsTopBar,
    defaultVal: false,
    onChanged: (_) => SmartDialog.showToast("重启生效"),
  ),
  const SwitchModel(
    title: '显示实际百分比音量',
    subtitle:
        '某些系统(鸿蒙)或设备只支持整数音量级别，如0~15，对应的百分比音量只有0%、7%、···、93%和100%，不存在1%、2%和50%等实际百分比音量',
    leading: Icon(Icons.science_outlined),
    setKey: SettingBoxKey.showActualVolume,
    defaultVal: false,
  ),
  const SwitchModel(
    title: '点击系统状态栏快速返回顶部',
    subtitle: '开启后在鸿蒙/iOS设备上，绝大部分列表点击状态栏可以快速回顶。\n关闭后除了部分原生支持的界面，均不再响应状态栏点击。',
    leading: Icon(Icons.vertical_align_top_outlined),
    setKey: SettingBoxKey.enableStatusBarTapToTop,
    defaultVal: false,
  ),
  NormalModel(
    title: '系统防窥页面',
    leading: const Icon(Icons.remove_red_eye_outlined),
    getSubtitle: () => '当前防窥页面：${Pref.antiPeep.split(',').map((item)=>pageName[item]).join('、')}',
    onTap: _showAntiPeepDialog,
  ),
  SwitchModel(
    title: '使用内置字体',
    subtitle: '使用内置HarmonyOS Sans字体，与系统默认字体相同\n关闭后用系统字体，可能卡顿，未修改系统字体不建议关闭',
    leading: const Icon(Icons.font_download_outlined),
    setKey: SettingBoxKey.useBuiltInFont,
    defaultVal: true,
    onChanged: (_) => Get.updateMyAppTheme(),
  ),
  SwitchModel(
    title: '视频封面一镜到底动画',
    subtitle: '点击视频卡片时封面平滑展开，返回时飞回原位\n仅支持首页的部分视频卡片和番剧/影视卡片',
    leading: const Icon(Icons.motion_photos_on_outlined),
    setKey: SettingBoxKey.enableHeroCoverAnimation,
    defaultVal: false,
    onChanged: (_) => SmartDialog.showToast("建议重启以应用更改"),
  ),
  NormalModel(
    title: '应用接续',
    subtitle: '相同华为用户播放视频时可在另一个设备的Dock栏中快速流转，无缝衔接上一个设备的视频。（始终开启）',
    leading: const Icon(Icons.devices_other),
    getTrailing: (theme) => IgnorePointer(
      child: Transform.scale(
        scale: 0.8,
        alignment: Alignment.centerRight,
        child: Switch(
          value: true,
          onChanged: (_) {},
          thumbIcon: WidgetStateProperty.all(
            const Icon(Icons.lock_outline_rounded),
          ),
        ),
      ),
    ),
  ),
    NormalModel(
    title: '后台下载离线缓存视频',
    subtitle: '接入鸿蒙后台任务，切换至后台不中断离线缓存视频下载（始终开启）',
    leading: const Icon(Icons.downloading),
    getTrailing: (theme) => IgnorePointer(
      child: Transform.scale(
        scale: 0.8,
        alignment: Alignment.centerRight,
        child: Switch(
          value: true,
          onChanged: (_) {},
          thumbIcon: WidgetStateProperty.all(
            const Icon(Icons.lock_outline_rounded),
          ),
        ),
      ),
    ),
  ),
];