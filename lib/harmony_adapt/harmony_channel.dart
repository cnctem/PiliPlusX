import 'package:PiliPlus/common/widgets/scale_app.dart';
import 'package:PiliPlus/harmony_adapt/continuation.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:os_type/os_type.dart';

abstract class HarmonyChannel {
  static double? _systemFontWeightScale;

  static double? get systemFontWeightScale => _systemFontWeightScale;

  static final MethodChannel _channel = const MethodChannel('harmonyChannel')
    ..setMethodCallHandler(handler);

  static Future<dynamic> handler(MethodCall call) async {
    switch (call.method) {
      case 'onFloatingWindowChange':
        onLandscapeOrMiniWindowChange(null, call.arguments['isFloatingWindow']);
        break;
      case 'onFontWeightScaleChange':
        final fontWeightScale = call.arguments['fontWeightScale'] as double?;
        _systemFontWeightScale = fontWeightScale;
        if (Pref.appFontWeight == -1) {
          Get.updateMyAppTheme();
        }
        break;
      // 源端 onContinue 拉取当前播放状态
      case 'getContinuationState':
        return HarmonyContinuation.currentState();
      // 对端应用已在运行时被接续唤醒
      case 'onContinuationRestore':
        checkPendingContinuation();
        break;
      // 原生底栏切换页签
      case 'showHome':
        _onShellTabSwitch?.call(0);
        break;
      case 'showDynamics':
        _onShellTabSwitch?.call(1);
        break;
      case 'showMine':
        _onShellTabSwitch?.call(2);
        break;
      // ArkTS 顶栏搜索框点击 → Flutter 跳转搜索页
      case 'onTopSearchTap':
        _onTopSearchTap?.call();
        break;
      // ArkTS 顶栏私信点击 → Flutter 跳转私信页
      case 'onTopMsgTap':
        _onTopMsgTap?.call();
        break;
      // ArkTS 顶栏头像点击 → Flutter 跳个人页
      case 'onTopMineTap':
        _onTopMineTap?.call();
        break;
      // ArkTS 分类栏切换 → Flutter 切换首页 TabController
      case 'onHomeTabChange':
        _onHomeTabChange?.call(call.arguments['index'] as int? ?? 0);
        break;
      default:
        break;
    }
  }

  /// 顶栏搜索点击回调：由 HomePage 注册
  static void Function()? _onTopSearchTap;
  static set onTopSearchTap(void Function()? callback) =>
      _onTopSearchTap = callback;

  /// 顶栏私信点击回调
  static void Function()? _onTopMsgTap;
  static set onTopMsgTap(void Function()? callback) => _onTopMsgTap = callback;

  /// 顶栏头像点击回调
  static void Function()? _onTopMineTap;
  static set onTopMineTap(void Function()? callback) =>
      _onTopMineTap = callback;

  /// 分类切换回调：由 HomeController 注册
  static void Function(int index)? _onHomeTabChange;
  static set onHomeTabChange(void Function(int)? callback) =>
      _onHomeTabChange = callback;

  /// Shell 页签切换回调：由 MainController 注册
  static void Function(int index)? _onShellTabSwitch;

  static set onShellTabSwitch(void Function(int)? callback) =>
      _onShellTabSwitch = callback;

  /// 系统「自动旋转」开关是否关闭（用户锁定了屏幕旋转）。
  ///
  /// 决定播放器全屏时是否强制转屏：
  /// - 已锁定：系统不会跟着设备转，全屏需按视频方向锁定横/竖轴（轴内仍按重力
  ///   180° 翻转，用的是不受锁定影响的 AUTO_ROTATION_LANDSCAPE/PORTRAIT）
  /// - 未锁定：方向交给系统跟随设备，全屏不再强制
  ///
  /// 非鸿蒙或读取失败一律按「已锁定」处理（保守，等价旧行为）。
  static Future<bool> isRotationLocked() async {
    if (!OS.isHarmony) return true;
    try {
      return await _channel.invokeMethod<bool>('isRotationLocked') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// 向原生发送壳配置的公共辅助：非鸿蒙直接跳过，静默失败。
  static Future<void> _invoke(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    if (!OS.isHarmony) return;
    try {
      await _channel.invokeMethod(method, args);
    } on PlatformException catch (_) {}
  }

  /// 向原生发送 shell 配置（Flutter 侧计算后通知 ArkTS）
  static Future<void> setShellBars({required bool useNativeTabs}) =>
      _invoke('setShellBars', {'useNativeTabs': useNativeTabs});

  /// HDS 底栏当前是否为显示状态
  static bool _hiddenByPage = false;
  static bool get hdsBarVisible => !_hiddenByPage;

  /// 控制原生 HDS 底栏/顶栏的显隐（弹窗、全屏页等场景）
  static Future<void> setShellBarsHidden(
    bool hidden, {
    bool retry = false,
  }) async {
    if (!OS.isHarmony) return;
    _hiddenByPage = hidden;
    final int total = retry ? 8 : 1;
    for (int i = 0; i < total; i++) {
      try {
        _channel.invokeMethod('setShellBarsHidden', {'hidden': hidden});
        return;
      } catch (_) {
        if (i == total - 1) return;
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }
  }

  /// 同步主题色到 ArkTS HdsTabs 底栏
  static Future<void> setTabSelectedColor(String hexColor) =>
      _invoke('setTabSelectedColor', {'color': hexColor});

  /// 向原生发送顶栏配置（Flutter 侧计算后通知 ArkTS）
  static Future<void> setShellTopBar({required bool useNativeTopBar}) =>
      _invoke('setShellTopBar', {'useNativeTopBar': useNativeTopBar});

  /// 批量同步首页顶部数据到 ArkTS 原生顶栏
  static Future<void> setHomeTopBarData({
    required List<String> tabs,
    required bool hideTopBar,
    required int activeIndex,
  }) => _invoke('setHomeTopBarData', {
    'tabs': tabs,
    'hideTopBar': hideTopBar,
    'activeIndex': activeIndex,
  });

  /// 同步搜索默认词到 ArkTS Search 组件
  static Future<void> setHomeSearchText(String text) =>
      _invoke('setHomeSearchText', {'text': text});

  /// 同步私信未读数到 ArkTS 红点
  static Future<void> setHomeUnreadCount(String count) =>
      _invoke('setHomeUnreadCount', {'count': count});

  /// 同步头像到 ArkTS
  static Future<void> setHomeFaceUrl(String url) =>
      _invoke('setHomeFaceUrl', {'url': url});

  /// Flutter 切分类时同步高亮到 ArkTS Tabs
  static Future<void> setHomeTabIndex(int index) =>
      _invoke('setHomeTabIndex', {'index': index});

  /// 下滑收起/展开顶部大搜索栏
  static Future<void> setTopBarCollapsed(bool collapsed) =>
      _invoke('setTopBarCollapsed', {'collapsed': collapsed});

  /// 同步当前底部页签是否为首页到 ArkTS（顶栏 dialog 分流判断用）
  static Future<void> setTopBarIsHome(bool isHome) =>
      _invoke('setTopBarIsHome', {'isHome': isHome});

  /// 顶栏隐藏状态合并：路由/横屏 or 非首页页签
  static bool _topBarHiddenByRoute = false;
  static bool _topBarHiddenByTab = false;

  /// 路由/横屏切换时整体隐藏顶栏（与底栏联动）
  static Future<void> setTopBarHidden(bool hidden) async {
    if (!OS.isHarmony) return;
    _topBarHiddenByRoute = hidden;
    try {
      _channel.invokeMethod('setTopBarHidden', {
        'hidden': _topBarHiddenByRoute || _topBarHiddenByTab,
      });
    } on PlatformException catch (_) {}
  }

  /// 非首页页签（动态/我的）时隐藏顶栏（仅首页显示）
  static Future<void> setTopBarTabHidden(bool hidden) async {
    if (!OS.isHarmony) return;
    _topBarHiddenByTab = hidden;
    try {
      _channel.invokeMethod('setTopBarHidden', {
        'hidden': _topBarHiddenByRoute || _topBarHiddenByTab,
      });
    } on PlatformException catch (_) {}
  }

  /// 同步 Flutter 页签切换到 ArkTS HdsTabs
  static Future<void> changeTabIndex(int index) =>
      _invoke('changeTabIndex', {'index': index});

  /// 控制原生 HDS 底栏的滚动显隐（带动画）
  static Future<void> setShellBarsScrollHidden(bool hidden) =>
      _invoke('setShellBarsScrollHidden', {'hidden': hidden});

  /// 启动长时任务，用于下载
  static Future<void> startBackgroundTask() => _invoke('startBackgroundTask');

  /// 停止长时任务
  static Future<void> stopBackgroundTask() => _invoke('stopBackgroundTask');

  /// 取走 ETS 侧暂存的接续数据并跳转视频页。冷启动在首帧后调用，
  /// 热启动由 onContinuationRestore 推送触发；数据取走即清除，不会重复跳转。
  static Future<void> checkPendingContinuation() async {
    try {
      final data = await _channel.invokeMethod<String>(
        'getPendingContinuation',
      );
      HarmonyContinuation.restore(data);
    } on PlatformException catch (_) {}
  }

  /// “可接续”状态按持有者管理：视频播放器/直播间/音频页/专栏页在存续期间
  /// 持有，任一持有者存在时系统显示接续入口，全部释放后置为不可接续。
  /// 列表保持持有顺序（最新在尾部），接续时从最近的持有者生成快照。
  static final List<Object> _continuationOwners = [];

  static List<Object> get continuationOwners => _continuationOwners;

  static void holdContinuation(Object owner) {
    if (!OS.isHarmony) return;
    final wasEmpty = _continuationOwners.isEmpty;
    _continuationOwners
      ..remove(owner)
      ..add(owner);
    if (wasEmpty) {
      _setContinuationActive(true);
    }
  }

  static void releaseContinuation(Object owner) {
    if (!OS.isHarmony) return;
    if (_continuationOwners.remove(owner) && _continuationOwners.isEmpty) {
      _setContinuationActive(false);
    }
  }

  static void _setContinuationActive(bool active) {
    _channel.invokeMethod('setContinuationActive', {'active': active});
  }

  /// 测试用，ai生成信息请忽略这部分更改
  static Future csy(value) {
    return _channel.invokeMethod('csy', {'value': value});
  }

  /// 仅控制状态栏显隐，不影响 Flutter 布局 padding。
  /// 用于大图查看等需要隐藏状态栏但不希望 MediaQuery padding 变化的场景。
  static Future<void> setStatusBarVisible(bool visible) =>
      _invoke('csy', {'value': visible});

  /// 全屏/退出全屏时仅切换系统栏（状态栏+导航栏）显隐，不改窗口布局，
  /// 避免 setWindowLayoutFullScreen 改变 surface 尺寸导致画面跳动。
  static Future<void> setFullScreenBars(bool fullscreen) =>
      _invoke('setFullScreenBars', {'fullscreen': fullscreen});

  /// 获取系统当前字重设置（仅 Harmony 平台）
  static Future<void> initSystemFontWeight() =>
      _invoke('getSystemFontWeightScale');

  /// 将应用内设定的主题颜色传递给原生层，用于原生层的深浅色模式感知
  static Future<void> setSystemColorMode(String colorMode) =>
      _invoke('setSystemColorMode', {'colorMode': colorMode});

  /// 横屏小窗的缩放比例固定值
  static const _miniWindowLandscapeScale = 0.75;
  static bool _landscape = false;
  static bool _miniWindow = false;

  /// 当前是否处于系统自由小窗（悬浮窗/全景多窗）。小窗内窗口宽高比不代表
  /// 设备方向，基于方向的自动全屏等逻辑应据此跳过。
  static bool get isMiniWindow => _miniWindow;

  /// 当方向或小窗变化
  static Future<void> onLandscapeOrMiniWindowChange(
    bool? landscape,
    bool? miniWindow,
  ) async {
    landscape ??= _landscape;
    miniWindow ??= _miniWindow;
    if (_landscape == landscape && _miniWindow == miniWindow) return;
    _landscape = landscape;
    _miniWindow = miniWindow;
    if (_miniWindow && _landscape) {
      _setMiniWindowLandscape(true);
      ScaledWidgetsFlutterBinding.instance.scaleFactor =
          _miniWindowLandscapeScale;
    } else {
      ScaledWidgetsFlutterBinding.instance.scaleFactor = Pref.uiScale;
      _setMiniWindowLandscape(false);
    }
  }

  static void _setMiniWindowLandscape(bool landscape) {
    _channel.invokeMethod('setMiniWindowLandscape', {'landscape': landscape});
  }

  static void autoRotateLandscape() {
    _channel.invokeMethod('autoRotateLandscape');
  }

  /// 鸿蒙：忽略系统旋转锁定，放开四个方向强制按重力自动旋转
  /// （原生 window.Orientation.AUTO_ROTATION，不受控制中心旋转开关控制）。
  /// 全屏「重力」模式用：即使系统锁定旋转，屏幕仍跟随设备重力转动。
  static Future<void> fullAutoRotate() => _invoke('fullAutoRotate');

  /// 先把窗口转到指定方向，之后继续跟随传感器（USER_ROTATION_*）。
  /// 用于系统未锁定旋转时进入全屏：点全屏按钮该转到视频方向，转完仍要能
  /// 跟着设备转回去（转回去会触发页面自动退出全屏）。
  static void userRotate({required bool landscape}) {
    _channel.invokeMethod('userRotate', {'landscape': landscape});
  }

  /// 自由多窗装饰栏按钮（全屏/最小化/关闭）的颜色跟随应用颜色模式而非
  /// 下方内容：浅色模式下深色按钮叠在播放页黑色顶部上视觉不可见。顶部为
  /// 深色内容的页面（视频/直播播放页）在可见期间持有此状态，使按钮切为
  /// 浅色风格；无人持有时恢复跟随系统。用持有者集合而非开关，规避
  /// 路由切换（如视频页跳视频页）中生命周期回调顺序的不确定性。
  static final Set<Object> _darkDecorOwners = <Object>{};

  static void holdDecorDark(Object owner) {
    if (!OS.isHarmony) return;
    final wasEmpty = _darkDecorOwners.isEmpty;
    _darkDecorOwners.add(owner);
    if (wasEmpty) {
      _setDecorButtonDark(true);
    }
  }

  static void releaseDecorDark(Object owner) {
    if (!OS.isHarmony) return;
    if (_darkDecorOwners.remove(owner) && _darkDecorOwners.isEmpty) {
      _setDecorButtonDark(false);
    }
  }

  static void _setDecorButtonDark(bool dark) {
    _channel.invokeMethod('setDecorButtonDark', {'dark': dark});
  }
}
