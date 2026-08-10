import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:convert' show ascii;
import 'dart:io' show Platform;
import 'dart:math' show max, min;
import 'dart:ui' as ui;

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/harmony_adapt/harmony_channel.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/media_kit_adapt/media_kit_adapt.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models/common/audio_normalization.dart';
import 'package:PiliPlus/models/common/super_resolution_type.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/models/user/danmaku_rule.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/models_new/video/video_shot/data.dart';
import 'package:PiliPlus/pages/danmaku/danmaku_model.dart';
import 'package:PiliPlus/pages/setting/models/play_settings.dart'
    show kMaxVolume;
import 'package:PiliPlus/pages/sponsor_block/block_mixin.dart';
import 'package:PiliPlus/plugin/pl_player/models/data_source.dart';
import 'package:PiliPlus/plugin/pl_player/models/data_status.dart';
import 'package:PiliPlus/plugin/pl_player/models/double_tap_type.dart';
import 'package:PiliPlus/plugin/pl_player/models/duration.dart';
import 'package:PiliPlus/plugin/pl_player/models/fullscreen_mode.dart';
import 'package:PiliPlus/plugin/pl_player/models/heart_beat_type.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliPlus/plugin/pl_player/utils/fullscreen.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/android/bindings.g.dart';
import 'package:PiliPlus/utils/asset_utils.dart';
import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/extension/box_ext.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/path_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:archive/archive.dart' show getCrc32;
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:floating/floating.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, DeviceOrientation;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:os_type/os_type.dart';
import 'package:path/path.dart' as path;
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

typedef PlayCallback = Future<void>? Function();

class PlPlayerController with BlockConfigMixin {
  Player? _videoPlayerController;
  VideoController? _videoController;

  static PlPlayerController? _instance;

  final playerStatus = PlPlayerStatus(.playing);

  final Rx<DataStatus> dataStatus = Rx(.none);

  Duration? seekToPos;
  bool hasToasted = false;
  final RxBool isSeeking = false.obs;

  final RxInt position = RxInt(0);

  int get positionInMilliseconds =>
      videoPlayerController?.state.position.inMilliseconds ?? 0;

  final RxInt buffered = RxInt(0);

  final RxInt duration = RxInt(0);

  int durationInMilliseconds = 0;

  void updateDuration(Duration value) {
    duration.value = value.inSeconds;
    durationInMilliseconds = value.inMilliseconds;
  }

  int _playerCount = 0;

  late double lastPlaybackSpeed = 1.0;
  final RxDouble _playbackSpeed = Pref.playSpeedDefault.obs;
  late final RxDouble _longPressSpeed = Pref.longPressSpeedDefault.obs;

  final RxDouble volume = RxDouble(
    PlatformUtils.isDesktop ? Pref.desktopVolume : 1.0,
  );

  /// 实际音量
  final actualVolume = 0.0.obs;
  final setSystemBrightness = Pref.setSystemBrightness;

  final RxDouble brightness = (-1.0).obs;

  final RxBool showControls = false.obs;

  final RxBool showBrightnessStatus = false.obs;

  final RxBool longPressStatus = false.obs;

  final RxBool controlsLock = false.obs;

  final RxBool isFullScreen = false.obs;
  bool isLive = false;

  bool _isVertical = false;

  final Rx<VideoFitType> videoFit = Rx(.contain);

  late final RxBool continuePlayInBackground =
      Pref.continuePlayInBackground.obs;

  bool _autoPlay = false;

  // 记录历史记录
  int? _aid;
  String? _bvid;
  int? cid;
  int? _epid;
  int? _seasonId;
  int? _pgcType;
  VideoType _videoType = VideoType.ugc;
  int _heartDuration = 0;
  int? width;
  int? height;

  late final tryLook = !Accounts.get(AccountType.video).isLogin && Pref.p1080;

  late DataSource dataSource;

  Timer? _timer;
  StreamSubscription? _subForSeek;

  // 鸿蒙：mpv 的 ohaudio 音频输出感知不到系统音频打断（如其他 app 抢占焦点），
  // 被打断后 mpv 仍自认为在播放，进度停滞、UI 按钮状态错误且无法点击恢复。
  // 用位置停滞检测兜底：播放中且非缓冲时位置连续数秒不前进，视为被系统打断。
  Timer? _stallWatchdog;
  int? _stallLastPosition;
  int _stallTicks = 0;
  bool _audioInterrupted = false;

  Box setting = GStorage.setting;

  // final Durations durations;

  String get bvid => _bvid!;

  /// 当前播放视频的标识、进度与播放状态快照，用于鸿蒙跨设备接续；
  /// 直播（由 LiveRoomController 提供快照）或无视频时为 null
  Map<String, dynamic>? get playSnapshot {
    if (isLive || _bvid == null || cid == null) {
      return null;
    }
    return {
      'type': 'video',
      'aid': _aid,
      'bvid': _bvid,
      'cid': cid,
      'epid': _epid,
      'seasonId': _seasonId,
      'pgcType': _pgcType,
      'videoType': _videoType.name,
      'progress': positionInMilliseconds,
      'playing': playerStatus.isPlaying,
      'onlyPlayAudio': onlyPlayAudio.value,
    };
  }

  /// 视频播放速度
  double get playbackSpeed => _playbackSpeed.value;

  // 长按倍速
  double get longPressSpeed => _longPressSpeed.value;

  /// [videoPlayerController] instance of Player
  Player? get videoPlayerController => _videoPlayerController;

  /// [videoController] instance of Player
  VideoController? get videoController => _videoController;

  bool isMuted = false;

  /// 听视频
  late final RxBool onlyPlayAudio = false.obs;

  /// 镜像
  late final RxBool flipX = false.obs;

  late final RxBool flipY = false.obs;

  final RxBool isBuffering = true.obs;

  /// 全屏方向
  // ignore: unnecessary_getters_setters
  bool get isVertical => _isVertical;

  set isVertical(bool value) {
    _isVertical = value;
  }

  /// 弹幕开关
  late final RxBool enableShowDanmaku = Pref.enableShowDanmaku.obs;
  late final RxBool enableShowLiveDanmaku = Pref.enableShowLiveDanmaku.obs;
  RxBool get enableShowDanmakuAdaptive =>
      isLive ? enableShowLiveDanmaku : enableShowDanmaku;

  late final bool autoPiP = Pref.autoPiP;
  bool get isPipMode =>
      ((Platform.isAndroid || OS.isHarmony) && Floating().isPipMode) ||
      (PlatformUtils.isDesktop && isDesktopPip);

  /// [isPipMode] 的响应式镜像（仅鸿蒙由 onPipModeChanged 驱动）。页面布局
  /// 依赖 isPipMode 时应同时监听它触发重建，否则 PiP 结束时若无视口变化
  /// 页面会滞留在画中画布局。
  final RxBool pipModeRx = false.obs;
  late bool isDesktopPip = false;
  late Rect _lastWindowBounds;

  late final showWindowTitleBar = Pref.showWindowTitleBar;
  late final RxBool isAlwaysOnTop = false.obs;
  Future<void> setAlwaysOnTop(bool value) {
    isAlwaysOnTop.value = value;
    return windowManager.setAlwaysOnTop(value);
  }

  Future<void> exitDesktopPip() {
    isDesktopPip = false;
    return Future.wait([
      if (showWindowTitleBar)
        windowManager.setTitleBarStyle(TitleBarStyle.normal),
      windowManager.setMinimumSize(const Size(400, 700)),
      windowManager.setBounds(_lastWindowBounds),
      setAlwaysOnTop(false),
      windowManager.setAspectRatio(0),
    ]);
  }

  Future<void> enterDesktopPip() async {
    if (isFullScreen.value) return;

    isDesktopPip = true;

    _lastWindowBounds = await windowManager.getBounds();

    if (showWindowTitleBar) {
      windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    }

    final Size size;
    final state = videoPlayerController!.state;
    int width = state.width ?? this.width ?? 16;
    int height = state.height ?? this.height ?? 9;
    if (width == 0) {
      width = this.width ?? 16;
    }
    if (height == 0) {
      height = this.height ?? 9;
    }
    if (height > width) {
      size = Size(280.0, 280.0 * height / width);
    } else {
      size = Size(280.0 * width / height, 280.0);
    }

    await windowManager.setMinimumSize(size);
    setAlwaysOnTop(true);
    windowManager
      ..setSize(size)
      ..setAspectRatio(width / height);
  }

  void toggleDesktopPip() {
    if (isDesktopPip) {
      exitDesktopPip();
    } else {
      enterDesktopPip();
    }
  }

  late bool _isAutoEnterPip = false;
  bool get isAutoEnterPip => _isAutoEnterPip;

  static bool get _isCurrVideoPage {
    final routing = Get.routing;
    if (routing.route is! GetPageRoute) {
      return false;
    }
    return _isVideoPage(routing.current);
  }

  static bool _isVideoPage(String routeName) {
    return routeName == '/videoV' || routeName == '/liveRoom';
  }

  Future<PiPStatus> enterPip({bool isAuto = false}) {
    if (videoPlayerController != null) {
      final state = videoPlayerController!.state;
      return PageUtils.enterPip(
        isAuto: isAuto,
        width: state.width == 0 ? width : state.width,
        height: state.height == 0 ? height : state.height,
      );
    }
    return Future.value(PiPStatus.unavailable);
  }

  void _disableAutoEnterPip() {
    if (_isAutoEnterPip) {
      if (OS.isHarmony) {
        Floating().setAutoPip(false);
      } else {
        Utils.channel.invokeMethod('setPipAutoEnterEnabled', {
          'autoEnable': false,
        });
      }
    }
  }

  // 弹幕相关配置
  late final enableTapDm = PlatformUtils.isMobile && Pref.enableTapDm;
  late RuleFilter filters = Pref.danmakuFilterRule;
  // 关联弹幕控制器
  DanmakuController<DanmakuExtra>? danmakuController;
  bool showDanmaku = true;
  Set<int> dmState = <int>{};
  late final mergeDanmaku = Pref.mergeDanmaku;
  late final String midHash = getCrc32(
    ascii.encode(Accounts.main.mid.toString()),
    0,
  ).toRadixString(16);
  late final RxDouble danmakuOpacity = Pref.danmakuOpacity.obs;

  late List<double> speedList = Pref.speedList;
  late bool enableAutoLongPressSpeed = Pref.enableAutoLongPressSpeed;
  late final showControlDuration = Pref.enableLongShowControl
      ? const Duration(seconds: 30)
      : const Duration(seconds: 3);
  // 字幕
  late double subtitleFontScale = Pref.subtitleFontScale;
  late double subtitleFontScaleFS = Pref.subtitleFontScaleFS;
  late int subtitlePaddingH = Pref.subtitlePaddingH;
  late int subtitlePaddingB = Pref.subtitlePaddingB;
  late double subtitleBgOpacity = Pref.subtitleBgOpacity;
  final bool showVipDanmaku = Pref.showVipDanmaku; // loop unswitching
  late double subtitleStrokeWidth = Pref.subtitleStrokeWidth;
  late int subtitleFontWeight = Pref.subtitleFontWeight;

  // settings
  late final showFSActionItem = Pref.showFSActionItem;
  late final enableShrinkVideoSize = Pref.enableShrinkVideoSize;
  late final darkVideoPage = Pref.darkVideoPage;
  late final enableSlideVolumeBrightness = Pref.enableSlideVolumeBrightness;
  late final enableSlideFS = Pref.enableSlideFS;
  late final enableDragSubtitle = Pref.enableDragSubtitle;
  late final fastForBackwardDuration = Duration(
    seconds: Pref.fastForBackwardDuration,
  );

  late final horizontalSeasonPanel = Pref.horizontalSeasonPanel;
  late final preInitPlayer = Pref.preInitPlayer;
  late final showRelatedVideo = Pref.showRelatedVideo;
  late final showVideoReply = Pref.showVideoReply;
  late final showBangumiReply = Pref.showBangumiReply;
  late final reverseFromFirst = Pref.reverseFromFirst;
  late final horizontalPreview = Pref.horizontalPreview;
  late final showDmChart = Pref.showDmChart;
  late final showViewPoints = Pref.showViewPoints;
  late final showFsScreenshotBtn = Pref.showFsScreenshotBtn;
  late final showFsLockBtn = Pref.showFsLockBtn;
  late final keyboardControl = Pref.keyboardControl;
  late final uiScale = Pref.uiScale;

  late final bool autoEnterFullScreen = Pref.autoEnterFullScreen;
  late final bool autoExitFullscreen = Pref.autoExitFullscreen;
  late final bool autoPlayEnable = Pref.autoPlayEnable;
  late final bool enableVerticalExpand = Pref.enableVerticalExpand;
  late final bool pipNoDanmaku = Pref.pipNoDanmaku;

  late final bool tempPlayerConf = Pref.tempPlayerConf;

  late int? cacheVideoQa = PlatformUtils.isMobile ? null : Pref.defaultVideoQa;
  late int cacheAudioQa = Pref.defaultAudioQa;
  bool enableHeart = true;
  late final String? hwdec = Pref.enableHA ? Pref.hardwareDecoding : null;

  late final progressType = Pref.btmProgressBehavior;
  late final enableQuickDouble = Pref.enableQuickDouble;
  late final fullScreenGestureReverse = Pref.fullScreenGestureReverse;

  late final isRelative = Pref.useRelativeSlide;
  late final offset = isRelative
      ? Pref.sliderDuration / 100
      : Pref.sliderDuration * 1000;

  num get sliderScale => isRelative ? durationInMilliseconds * offset : offset;

  // 播放顺序相关
  late PlayRepeat playRepeat = Pref.playRepeat;

  TextStyle get subTitleStyle => TextStyle(
    height: 1.5,
    fontSize:
        16 * (isFullScreen.value ? subtitleFontScaleFS : subtitleFontScale),
    letterSpacing: 0.1,
    wordSpacing: 0.1,
    color: Colors.white,
    fontWeight: FontWeight.values[subtitleFontWeight],
    backgroundColor: subtitleBgOpacity == 0
        ? null
        : Colors.black.withValues(alpha: subtitleBgOpacity),
  );

  late final Rx<SubtitleViewConfiguration> subtitleConfig = getSubConfig.obs;

  SubtitleViewConfiguration get getSubConfig {
    final subTitleStyle = this.subTitleStyle;
    return SubtitleViewConfiguration(
      style: subTitleStyle,
      // TODO 鸿蒙待适配 strokeStyle media_kit
      // strokeStyle: subtitleBgOpacity == 0
      //     ? subTitleStyle.copyWith(
      //         color: null,
      //         background: null,
      //         backgroundColor: null,
      //         foreground: Paint()
      //           ..color = Colors.black
      //           ..style = PaintingStyle.stroke
      //           ..strokeWidth = subtitleStrokeWidth,
      //       )
      //     : null,
      padding: EdgeInsets.only(
        left: subtitlePaddingH.toDouble(),
        right: subtitlePaddingH.toDouble(),
        bottom: subtitlePaddingB.toDouble(),
      ),
      textScaler: TextScaler.noScaling,
    );
  }

  void updateSubtitleStyle() {
    subtitleConfig.value = getSubConfig;
  }

  void onUpdatePadding(EdgeInsets padding) {
    subtitlePaddingB = padding.bottom.round().clamp(0, 200);
    putSubtitleSettings();
  }

  static PlPlayerController? get instance => _instance;

  static bool instanceExists() {
    return _instance != null;
  }

  static void setPlayCallBack(PlayCallback? playCallBack) {
    _playCallBack = playCallBack;
  }

  static PlayCallback? _playCallBack;

  static Future<void>? playIfExists() {
    return _playCallBack?.call();
  }

  // try to get PlayerStatus
  static PlayerStatus? getPlayerStatusIfExists() {
    return _instance?.playerStatus.value;
  }

  static Future<void> pauseIfExists({
    bool notify = true,
    bool isInterrupt = false,
  }) async {
    if (_instance?.playerStatus.isPlaying ?? false) {
      await _instance?.pause(notify: notify, isInterrupt: isInterrupt);
    }
  }

  static Future<void> seekToIfExists(
    Duration position, {
    bool isSeek = true,
  }) async {
    await _instance?.seekTo(position, isSeek: isSeek);
  }

  static double? getVolumeIfExists() {
    return _instance?.volume.value;
  }

  static Future<void>? setVolumeIfExists(
    double volumeNew, {
    bool showIndicator = true,
  }) {
    return _instance?.setVolume(volumeNew, showIndicator: showIndicator);
  }

  Box video = GStorage.video;

  bool visible = true;

  DeviceOrientation? _orientation;
  // 上游基于 native_device_orientation 的方向监听在鸿蒙上无插件实现，
  // 转屏由 harmony_adapt/HarmonyChannel 与 auto_orientation 处理，故移除。
  void _stopOrientationListener() {}

  // 添加一个私有构造函数
  PlPlayerController._() {
    if (!Accounts.heartbeat.isLogin || Pref.historyPause) {
      enableHeart = false;
    }

    if (autoPiP) {
      if (Platform.isAndroid) {
        if (DeviceUtils.sdkInt < 36) {
          Utils.channel.setMethodCallHandler((call) async {
            if (call.method == 'onUserLeaveHint') {
              if (playerStatus.isPlaying && _isCurrVideoPage) {
                enterPip();
              }
            }
          });
        } else {
          _isAutoEnterPip = true;
        }
      } else if (OS.isHarmony) {
        _isAutoEnterPip = true;
      }
    }
  }

  // 获取实例 传参
  static PlPlayerController getInstance({bool isLive = false}) {
    // 如果实例尚未创建，则创建一个新实例
    return (_instance ??= PlPlayerController._())
      ..isLive = isLive
      .._playerCount += 1;
  }

  bool _processing = false;
  bool get processing => _processing;

  // offline
  bool get isFileSource => dataSource is FileSource;

  late final _audioNormalization = Pref.audioNormalization;
  late final enableAudioNormalization =
      Platform.isAndroid && _audioNormalization != '0';
  late final String _audioNormalizationParam =
      AudioNormalization.getParamFromConfig(_audioNormalization);

  // 初始化资源
  //
  // 播放器是全局单例，多个视频页共享同一实例。setDataSource 内部会异步
  // 创建 media_kit Player（_initPlayer）。若并发调用（如 preInitPlayer
  // 页面初始化进行中，另一个 autoPlay 页面又进入——autoPlay 分支不检查
  // processing），会同时创建多个 Player，后创建的覆盖先创建的，先创建的
  // 失去引用后永不释放，造成原生播放器与流监听泄漏。这里用 Future 队列
  // 将初始化串行化，保证同一时刻只有一个 _setDataSource 在执行。
  Future<void> setDataSource(
    DataSource dataSource, {
    bool isLive = false,
    bool autoplay = true,
    // 初始化播放位置
    Duration? seekTo,
    // 初始化播放速度
    double speed = 1.0,
    int? width,
    int? height,
    Duration? duration,
    // 方向
    bool? isVertical,
    // 记录历史记录
    int? aid,
    String? bvid,
    int? cid,
    int? epid,
    int? seasonId,
    int? pgcType,
    VideoType? videoType,
    VoidCallback? onInit,
    Volume? volume,
    bool autoFullScreenFlag = false,
  }) {
    final previous = _setDataSourceQueue;
    final run = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {
          // 前一个初始化失败不阻塞本次
        }
      }
      await _setDataSource(
        dataSource,
        isLive: isLive,
        autoplay: autoplay,
        seekTo: seekTo,
        speed: speed,
        width: width,
        height: height,
        duration: duration,
        isVertical: isVertical,
        aid: aid,
        bvid: bvid,
        cid: cid,
        epid: epid,
        seasonId: seasonId,
        pgcType: pgcType,
        videoType: videoType,
        onInit: onInit,
        volume: volume,
        autoFullScreenFlag: autoFullScreenFlag,
      );
    }();
    _setDataSourceQueue = run;
    return run;
  }

  /// setDataSource 串行队列尾；同一时刻仅一个初始化流程在执行
  Future<void>? _setDataSourceQueue;

  Future<void> _setDataSource(
    DataSource dataSource, {
    bool isLive = false,
    bool autoplay = true,
    // 初始化播放位置
    Duration? seekTo,
    // 初始化播放速度
    double speed = 1.0,
    int? width,
    int? height,
    Duration? duration,
    // 方向
    bool? isVertical,
    // 记录历史记录
    int? aid,
    String? bvid,
    int? cid,
    int? epid,
    int? seasonId,
    int? pgcType,
    VideoType? videoType,
    VoidCallback? onInit,
    Volume? volume,
    bool autoFullScreenFlag = false,
  }) async {
    try {
      _processing = true;
      this.isLive = isLive;
      _videoType = videoType ?? VideoType.ugc;
      this.width = width;
      this.height = height;
      this.dataSource = dataSource;
      _autoPlay = autoplay;
      // 初始化视频倍速
      // _playbackSpeed.value = speed;
      // 初始化数据加载状态
      dataStatus.value = DataStatus.loading;
      // 初始化全屏方向
      _isVertical = isVertical ?? false;
      _aid = aid;
      _bvid = bvid;
      this.cid = cid;
      _epid = epid;
      _seasonId = seasonId;
      _pgcType = pgcType;
      if (!isLive && bvid != null && cid != null) {
        HarmonyChannel.holdContinuation(this);
      } else {
        HarmonyChannel.releaseContinuation(this);
      }

      if (showSeekPreview) {
        _clearPreview();
      }
      cancelLongPressTimer();
      if (_videoPlayerController != null &&
          _videoPlayerController!.state.playing) {
        await pause(notify: false);
      }

      if (_playerCount == 0) {
        return;
      }
      // 配置Player 音轨、字幕等等
      await _createVideoController(dataSource, seekTo, volume);

      if (_playerCount == 0) {
        _removeListeners();
        await _videoPlayerController?.dispose();
        _videoPlayerController = null;
        _videoController = null;
        return;
      }

      updateDuration(duration ?? _videoPlayerController!.state.duration);
      position.value = buffered.value = seekTo?.inSeconds ?? 0;

      dataStatus.value = .loaded;

      if (autoFullScreenFlag && autoEnterFullScreen) {
        triggerFullScreen(status: true);
      }

      await _initializePlayer();
      onInit?.call();
    } catch (err, stackTrace) {
      dataStatus.value = DataStatus.error;
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
        debugPrint('plPlayer err:  $err');
      }
    } finally {
      _processing = false;
    }
  }

  String? shadersDirPath;
  Future<String> get copyShadersToExternalDirectory async {
    if (shadersDirPath != null) {
      return shadersDirPath!;
    }

    return shadersDirPath = await AssetUtils.getOrCopy(
      'assets/shaders',
      Assets.mpvAnime4KShaders.followedBy(Assets.mpvAnime4KShadersLite),
      path.join(appSupportDirPath, 'anime_shaders'),
    );
  }

  late final isAnim = _pgcType == 1 || _pgcType == 4;
  late final Rx<SuperResolutionType> superResolutionType =
      (isAnim ? Pref.superResolutionType : SuperResolutionType.disable).obs;
  Future<void> setShader([SuperResolutionType? type, NativePlayer? pp]) async {
    if (type == null) {
      type = superResolutionType.value;
    } else {
      superResolutionType.value = type;
      if (isAnim && !tempPlayerConf) {
        setting.put(SettingBoxKey.superResolutionType, type.index);
      }
    }
    pp ??= _videoPlayerController!.platform!.maybeAsNativePlayer;
    await pp.waitForPlayerInitialization;
    await pp.waitForVideoControllerInitializationIfAttached;
    switch (type) {
      case SuperResolutionType.disable:
        return pp.command(const ['change-list', 'glsl-shaders', 'clr', '']);
      case SuperResolutionType.efficiency:
        return pp.command([
          'change-list',
          'glsl-shaders',
          'set',
          PathUtils.buildShadersAbsolutePath(
            await copyShadersToExternalDirectory,
            Assets.mpvAnime4KShadersLite,
          ),
        ]);
      case SuperResolutionType.quality:
        return pp.command([
          'change-list',
          'glsl-shaders',
          'set',
          PathUtils.buildShadersAbsolutePath(
            await copyShadersToExternalDirectory,
            Assets.mpvAnime4KShaders,
          ),
        ]);
    }
  }

  static final loudnormRegExp = RegExp('loudnorm=([^,]+)');

  Future<Player> _initPlayer() async {
    assert(_videoPlayerController == null);
    final opt = {
      'video-sync': Pref.videoSync,
      if (Platform.isAndroid) 'ao': Pref.audioOutput,
      'volume':
          (PlatformUtils.isMobile ? Pref.playerVolume : volume.value * 100)
              .toString(),
      'volume-max': kMaxVolume.toString(),
    };
    final autosync = Pref.autosync;
    if (autosync != '0') {
      opt['autosync'] = autosync;
    }

    final player = Player(
      configuration: const PlayerConfiguration(
        logLevel: kDebugMode ? .warn : .error,
      ),
    );

    final pp = player.platform!.maybeAsNativePlayer;
    for (var o in opt.entries) {
      pp.setProperty(o.key, o.value);
    }

    assert(_videoController == null);

    _videoController = VideoController(
      player,
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: hwdec != null,
        androidAttachSurfaceAfterVideoParameters: false,
        hwdec: hwdec,
      ),
    );
    // await player.setAudioTrack(.auto());

    _startListeners(player.platform!.maybeAsNativePlayer);

    return player;
  }

  Map<String, String>? _buffer;
  Map<String, String> get buffer =>
      _buffer ??= Pref.initBuffer(_playbackSpeed.value);
  Map<String, String>? _liveBuffer;
  Map<String, String> get liveBuffer => _liveBuffer ??= Pref.initLiveBuffer();

  // 配置播放器
  Future<void> _createVideoController(
    DataSource dataSource,
    Duration? seekTo,
    Volume? volume,
  ) async {
    isBuffering.value = false;
    _heartDuration = 0;
    danmakuController?.clear();

    var player = _videoPlayerController;

    if (player == null) {
      player = await _initPlayer();
      if (_playerCount == 0) {
        _removeListeners();
        await player.dispose();
        player = null;
        _videoController = null;
        return;
      }
      _videoPlayerController = player;
      if (isAnim && superResolutionType.value != .disable) {
        await setShader();
      }
    }

    final Map<String, String> extras = {};

    if (dataSource is FileSource) {
      extras['cache'] = 'no';
    } else {
      if (isLive) {
        extras.addAll(liveBuffer);
      } else {
        extras.addAll(buffer);
      }
    }

    String video = dataSource.videoSource;
    if (dataSource.audioSource case final audio? when (audio.isNotEmpty)) {
      if (onlyPlayAudio.value) {
        video = audio;
      } else {
        var audioUri = Platform.isWindows
            ? audio.replaceAll(';', '\\;')
            : audio.replaceAll(':', '\\:');
        extras['audio-files'] = audioUri;
        player.platform!.maybeAsNativePlayer.setProperty(
          'audio-files',
          audioUri,
        );
      }
    } else {
      // 修复 Bug：从视频页返回直播间后，声音变成刚才视频的声音。
      // 原因：当前版本改用 NativePlayer.setProperty 直接设置 audio-files，
      // 该属性会持久化在复用的 Player 实例上；而 2.0.1 及之前版本是通过
      // Media.extras 传入 audio-files，每次 player.open 都会随新 Media 重置。
      // 当切换到无单独音频源的内容（如直播、关闭听视频）时，必须主动清空
      // audio-files，否则旧视频的外部音轨会继续播放，导致画面与声音不一致。
      player.platform!.maybeAsNativePlayer.setProperty('audio-files', '');
      if (enableAudioNormalization) {
        final String audioNormalization;
        if (volume != null && volume.isNotEmpty) {
          audioNormalization = _audioNormalizationParam.replaceFirstMapped(
            loudnormRegExp,
            (i) =>
                'loudnorm=${volume.format(
                  Map.fromEntries(
                    i.group(1)!.split(':').map((item) {
                      final parts = item.split('=');
                      return MapEntry(parts[0].toLowerCase(), num.parse(parts[1]));
                    }),
                  ),
                )}',
          );
        } else {
          audioNormalization = _audioNormalizationParam.replaceFirst(
            loudnormRegExp,
            AudioNormalization.getParamFromConfig(Pref.fallbackNormalization),
          );
        }
        if (audioNormalization.isNotEmpty) {
          extras['lavfi-complex'] = '"[aid1] $audioNormalization [ao]"';
        }
      }
    }

    await player.open(
      Media(
        video,
        httpHeaders: {
          'user-agent': BrowserUa.pc,
          'referer': HttpString.baseUrl,
        },
        start: seekTo,
        extras: extras.isEmpty ? null : extras,
      ),
      play: false,
    );
  }

  Future<bool?> refreshPlayer() async {
    if (dataSource is FileSource) {
      return null;
    }
    if (_videoPlayerController == null) {
      // SmartDialog.showToast('视频播放器为空，请重新进入本页面');
      return false;
    }
    if (dataSource.videoSource.isNullOrEmpty) {
      SmartDialog.showToast('视频源为空，请重新进入本页面');
      return false;
    }
    String? audioUri;
    if (!isLive) {
      if (dataSource.audioSource.isNullOrEmpty) {
        SmartDialog.showToast('音频源为空');
      } else {
        audioUri = Platform.isWindows
            ? dataSource.audioSource!.replaceAll(';', '\\;')
            : dataSource.audioSource!.replaceAll(':', '\\:');
        await (_videoPlayerController!.platform!).maybeAsNativePlayer
            .setProperty('audio-files', audioUri);
      }
    } else {
      // 与 _createVideoController 保持一致：直播等无外部音频源的场景下，
      // 刷新播放源前必须清空残留的 audio-files，防止旧视频音频继续播放。
      await (_videoPlayerController!.platform!).maybeAsNativePlayer.setProperty(
        'audio-files',
        '',
      );
    }
    await _videoPlayerController!.open(
      Media(
        dataSource.videoSource,
        start: Duration(milliseconds: positionInMilliseconds),
        extras: audioUri == null ? null : {'audio-files': '"$audioUri"'},
      ),
      play: true,
    );
    return true;
    // seekTo(currentPos);
  }

  // 开始播放
  Future<void> _initializePlayer() async {
    if (_instance == null) return;
    // 设置倍速
    if (isLive) {
      await setPlaybackSpeed(1.0);
    } else {
      if (_videoPlayerController?.state.rate != _playbackSpeed.value) {
        await setPlaybackSpeed(_playbackSpeed.value);
      }
    }
    _initVideoFit();
    // if (_looping) {
    //   await setLooping(_looping);
    // }

    // 跳转播放
    // if (seekTo != Duration.zero) {
    //   await this.seekTo(seekTo);
    // }

    // 自动播放
    if (_autoPlay) {
      playIfExists();
      // await play(duration: duration);
    }
  }

  List<StreamSubscription>? _subscriptions;
  final Set<ValueChanged<Duration>> _positionListeners = {};
  final Set<ValueChanged<PlayerStatus>> _statusListeners = {};

  /// 播放事件监听
  void _startListeners(NativePlayer player) {
    assert(_subscriptions == null);
    if (OS.isHarmony) {
      _startStallWatchdog();
      Floating().onPipAction = _onPipAction;
      // isPipMode 是普通 bool，build 读它不产生依赖；PiP 结束时若窗口尺寸
      // 恰好没变（如画中画期间从应用栏以小窗打开 app），没有任何重建时机，
      // 页面会冻结在画中画布局。用回调驱动 pipModeRx，页面据此重建。
      Floating().onPipModeChanged = (v) => pipModeRx.value = v;
      pipModeRx.value = Floating().isPipMode;
    }
    final stream = player.stream;
    _subscriptions = [
      /// playing
      stream.playing.listen((bool playing) {
        WakelockPlus.toggle(enable: playing);
        if (playing) {
          if (_isAutoEnterPip) {
            if (_isCurrVideoPage) {
              enterPip(isAuto: true);
            } else {
              _disableAutoEnterPip();
            }
          }
          playerStatus.value = .playing;
        } else {
          // 鸿蒙：退后台引发的暂停不取消自动画中画，否则该取消操作会与系统
          // 自动小窗的启动赛跑，导致自动小窗时灵时不灵（Android 的 PiP
          // auto-enter 与离开手势原子执行，无此问题）。仅在应用处于前台
          // （用户主动暂停）时才取消。
          if (!OS.isHarmony ||
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed) {
            _disableAutoEnterPip();
          }
          playerStatus.value = PlayerStatus.paused;
          // 鸿蒙：进入画中画的退后台过程中，系统会直接把 mpv 置为暂停
          //（应用层无任何 pause 调用，插桩证实；auto-start 武装与否均如此）。
          // 画中画窗口可见即应继续播放，且普通 play() 即可恢复（等效于
          // 用户按面板播放键），这里自动补上。_pauseRequestedByApp 排除
          // 用户/业务暂停，频率闸防止与系统拉锯。
          if (OS.isHarmony &&
              !_pauseRequestedByApp &&
              isPipMode &&
              !(videoPlayerController?.state.completed ?? false) &&
              _pipAutoResumeAllowed()) {
            play();
          }
        }
        if (OS.isHarmony) {
          // 同步鸿蒙小窗控制面板的播放/暂停图标
          Floating().updatePipControlStatus(playing: playing);
        }

        videoPlayerServiceHandler?.onStatusChange(
          playerStatus.value,
          isBuffering.value,
          isLive,
        );

        for (final element in _statusListeners) {
          element(playing ? .playing : .paused);
        }

        final seconds = videoPlayerController!.state.position.inSeconds;
        if (seconds != 0) {
          makeHeartBeat(seconds, type: .status);
        }
      }),

      ///completed
      stream.completed.listen((bool completed) {
        if (completed) {
          playerStatus.value = .completed;

          for (final element in _statusListeners) {
            element(.completed);
          }

          makeHeartBeat(-1, type: .completed);
        }
      }),

      /// position
      stream.position.listen((Duration position) {
        final posInSeconds = position.inSeconds;

        if (posInSeconds != this.position.value) {
          if (!isSeeking.value) {
            this.position.value = posInSeconds;
          }

          videoPlayerServiceHandler?.onPositionChange(position);

          makeHeartBeat(posInSeconds);
        }

        for (final element in _positionListeners) {
          element(position);
        }
      }),
      stream.duration.listen(updateDuration),
      stream.buffer.listen((Duration buffer) {
        buffered.value = buffer.inSeconds;
      }),
      stream.buffering.listen((bool buffering) {
        isBuffering.value = buffering;
        videoPlayerServiceHandler?.onStatusChange(
          playerStatus.value,
          buffering,
          isLive,
        );
      }),
      if (kDebugMode)
        stream.log.listen(((PlayerLog log) {
          if (log.level == 'error' || log.level == 'fatal') {
            Utils.reportError('${log.level}: ${log.prefix}: ${log.text}', null);
          } else {
            debugPrint(log.toString());
          }
        })),
      stream.error.listen((String event) {
        if (dataSource is FileSource &&
            event.startsWith("Failed to open file")) {
          return;
        }
        if (isLive) {
          if (event.startsWith('tcp: ffurl_read returned ') ||
              event.startsWith("Failed to open https://") ||
              event.startsWith("Can not open external file https://")) {
            Future.delayed(const Duration(milliseconds: 3000), refreshPlayer);
          }
          return;
        }
        if (event.startsWith("Failed to open https://") ||
            event.startsWith("Can not open external file https://") ||
            //tcp: ffurl_read returned 0xdfb9b0bb
            //tcp: ffurl_read returned 0xffffff99
            event.startsWith('tcp: ffurl_read returned ')) {
          EasyThrottle.throttle(
            'controllerStream.error.listen',
            const Duration(milliseconds: 10000),
            () {
              Future.delayed(const Duration(milliseconds: 3000), () {
                // if (kDebugMode) {
                //   debugPrint("isBuffering.value: ${isBuffering.value}");
                // }
                // if (kDebugMode) {
                //   debugPrint("_buffered.value: ${_buffered.value}");
                // }
                if (isBuffering.value && buffered.value == 0) {
                  SmartDialog.showToast(
                    '视频链接打开失败，重试中',
                    displayTime: const Duration(milliseconds: 500),
                  );
                  refreshPlayer();
                }
              });
            },
          );
        } else if (event.startsWith('Could not open codec')) {
          SmartDialog.showToast('无法加载解码器, $event，可能会切换至软解');
        } else if (!onlyPlayAudio.value) {
          if (event.startsWith("error running") ||
              event.startsWith("Failed to open .") ||
              event.startsWith("Cannot open") ||
              event.startsWith("Can not open")) {
            return;
          }
          Utils.reportError(event);
          // SmartDialog.showToast('视频加载错误, $event');
        }
      }),
    ];
  }

  /// 移除事件监听
  void _removeListeners() {
    _stallWatchdog?.cancel();
    _stallWatchdog = null;
    if (Floating().onPipAction == _onPipAction) {
      Floating().onPipAction = null;
    }
    _subscriptions?.forEach((e) => e.cancel());
    _subscriptions?.clear();
    _subscriptions = null;
  }

  /// 鸿蒙小窗控制面板按钮回调（floating 插件转发 controlPanelActionEvent）
  void _onPipAction(String event, int? status) {
    switch (event) {
      case 'playbackStateChanged':
        // status: 1=请求播放，0=请求暂停；缺省时按当前状态取反
        final wantPlay = status == null ? !playerStatus.isPlaying : status == 1;
        if (wantPlay) {
          play();
        } else {
          pause();
        }
      case 'fastForward':
        onForward(fastForBackwardDuration);
      case 'fastBackward':
        onBackward(fastForBackwardDuration);
    }
  }

  /// 鸿蒙音频打断兜底检测（见 _stallWatchdog 字段注释）
  void _startStallWatchdog() {
    _stallWatchdog?.cancel();
    _stallLastPosition = null;
    _stallTicks = 0;
    _stallWatchdog = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!playerStatus.isPlaying ||
          isBuffering.value ||
          positionInMilliseconds == 0) {
        _stallTicks = 0;
        _stallLastPosition = null;
        return;
      }
      if (positionInMilliseconds == _stallLastPosition) {
        _stallTicks++;
        // 连续约 2.4s 声称播放中却毫无进展：音频输出已被系统暂停。
        // 同步为暂停态，让按钮显示"播放"，恢复逻辑见 play()。
        if (_stallTicks >= 2) {
          _stallTicks = 0;
          _stallLastPosition = null;
          _audioInterrupted = true;
          pause(isInterrupt: true);
        }
      } else {
        _stallTicks = 0;
        _stallLastPosition = positionInMilliseconds;
      }
    });
  }

  void _cancelSubForSeek() {
    if (_subForSeek != null) {
      _subForSeek!.cancel();
      _subForSeek = null;
    }
  }

  /// 跳转至指定位置
  Future<void> seekTo(Duration position, {bool isSeek = true}) async {
    if (_playerCount == 0) {
      return;
    }
    if (position < Duration.zero) {
      position = Duration.zero;
    }
    _heartDuration = position.inSeconds;

    Future<void> seek() async {
      if (isSeek) {
        /// 拖动进度条调节时，不等待第一帧，防止抖动
        await _videoPlayerController?.stream.buffer.first;
      }
      danmakuController?.clear();
      try {
        await _videoPlayerController?.seek(position);
      } catch (e) {
        if (kDebugMode) debugPrint('seek failed: $e');
      }
    }

    if (duration.value != 0) {
      seek();
    } else {
      // if (kDebugMode) debugPrint('seek duration else');
      _subForSeek?.cancel();
      _subForSeek = duration.listen((_) {
        seek();
        _cancelSubForSeek();
      });
    }
  }

  /// 设置倍速
  Future<void> setPlaybackSpeed(double speed) async {
    lastPlaybackSpeed = playbackSpeed;

    if (speed == _videoPlayerController?.state.rate) {
      return;
    }

    await _videoPlayerController?.setRate(speed);
    _playbackSpeed.value = speed;
    if (danmakuController != null) {
      try {
        DanmakuOption currentOption = danmakuController!.option;
        double defaultDuration = currentOption.duration * lastPlaybackSpeed;
        double defaultStaticDuration =
            currentOption.staticDuration * lastPlaybackSpeed;
        DanmakuOption updatedOption = currentOption.copyWith(
          duration: defaultDuration / speed,
          staticDuration: defaultStaticDuration / speed,
        );
        danmakuController!.updateOption(updatedOption);
      } catch (_) {}
    }
  }

  // 还原默认速度
  double playSpeedDefault = Pref.playSpeedDefault;
  Future<void> setDefaultSpeed() async {
    await _videoPlayerController?.setRate(playSpeedDefault);
    _playbackSpeed.value = playSpeedDefault;
  }

  /// 播放视频
  Future<void> play({bool repeat = false, bool hideControls = true}) async {
    if (_playerCount == 0) return;
    _pauseRequestedByApp = false;
    // 播放时自动隐藏控制条
    controls = !hideControls;
    // repeat为true，将从头播放
    if (repeat) {
      // await seekTo(Duration.zero);
      await seekTo(Duration.zero, isSeek: false);
    }

    // 鸿蒙：被系统打断后 mpv 的音频渲染器已被暂停且 mpv 自身无感知，
    // 单纯解除暂停不会恢复。先重新激活音频会话抢回焦点（暂停其他 app 的
    // 音频），再用 ao-reload 重建音频输出，让新渲染器以新焦点启动。
    if (_audioInterrupted) {
      _audioInterrupted = false;
      try {
        await audioSessionHandler?.setActive(true);
      } catch (_) {}
      try {
        await _videoPlayerController?.platform?.maybeAsNativePlayer.command(
          const ['ao-reload'],
        );
      } catch (_) {}
    }

    await _videoPlayerController?.play();

    audioSessionHandler?.setActive(true);

    playerStatus.value = PlayerStatus.playing;
    // screenManager.setOverlays(false);
  }

  /// 暂停播放
  /// 应用层是否主动发起了当前这次暂停。用于区分"系统在进入画中画的退后台
  /// 过程中直接把 mpv 置为暂停"（Dart 层无任何 pause 调用，需要自动恢复）
  /// 与用户/业务发起的正常暂停。
  bool _pauseRequestedByApp = false;
  int _pipAutoResumeCount = 0;
  DateTime? _pipAutoResumeWindowStart;

  /// 生命周期回调的补偿入口：处于画中画且播放被系统静默暂停（而非应用
  /// 主动暂停）时自动续播。覆盖"系统暂停发生在 isPipMode 置位之前"的
  /// 时序——彼时 stream.playing 监听里的自动续播不满足条件，只能靠随后
  /// 到达的生命周期事件（floating 插件会在 PiP 启动后补发 inactive）触发。
  void autoResumeInPipIfNeeded() {
    if (OS.isHarmony &&
        !_pauseRequestedByApp &&
        isPipMode &&
        !playerStatus.isPlaying &&
        !(videoPlayerController?.state.completed ?? false) &&
        _pipAutoResumeAllowed()) {
      play();
    }
  }

  /// 限制画中画内自动续播的频率，防止与系统的强制暂停陷入拉锯。
  bool _pipAutoResumeAllowed() {
    final now = DateTime.now();
    if (_pipAutoResumeWindowStart == null ||
        now.difference(_pipAutoResumeWindowStart!) >
            const Duration(seconds: 10)) {
      _pipAutoResumeWindowStart = now;
      _pipAutoResumeCount = 0;
    }
    return ++_pipAutoResumeCount <= 3;
  }

  Future<void> pause({bool notify = true, bool isInterrupt = false}) async {
    _pauseRequestedByApp = true;
    await _videoPlayerController?.pause();
    playerStatus.value = PlayerStatus.paused;

    // 主动暂停时让出音频焦点
    if (!isInterrupt) {
      audioSessionHandler?.setActive(false);
    }
  }

  bool tripling = false;

  /// 隐藏控制条
  void hideTaskControls() {
    _timer?.cancel();
    _timer = Timer(showControlDuration, () {
      if (!isSeeking.value && !tripling) {
        controls = false;
      }
      _timer = null;
    });
  }

  void onSeekEnd() {
    if (seekToPos != null) {
      feedBack();
    }
    if (showSeekPreview) {
      showPreview.value = false;
    }
    hasToasted = false;
    isSeeking.value = false;
    hideTaskControls();
  }

  final RxBool volumeIndicator = false.obs;
  Timer? volumeTimer;
  bool volumeInterceptEventStream = false;

  final double maxVolume = PlatformUtils.isDesktop ? Pref.maxVolume : 1.0;
  Future<void> setVolume(double volume, {bool showIndicator = true}) async {
    if (this.volume.value != volume ||
        (PlatformUtils.isMobile &&
            await FlutterVolumeController.getVolume() != this.volume.value)) {
      this.volume.value = volume;
      try {
        if (PlatformUtils.isDesktop) {
          await _videoPlayerController!.setVolume(volume * 100);
          actualVolume.value = volume;
        } else {
          FlutterVolumeController.updateShowSystemUI(false);
          await FlutterVolumeController.setVolume(volume);
          actualVolume.value =
              await FlutterVolumeController.getVolume() ?? actualVolume.value;
        }
      } catch (err) {
        if (kDebugMode) debugPrint(err.toString());
      }
    }
    if (showIndicator) {
      volumeIndicator.value = true;
    }
    volumeInterceptEventStream = true;
    volumeTimer?.cancel();
    volumeTimer = Timer(const Duration(milliseconds: 200), () {
      volumeIndicator.value = false;
      volumeInterceptEventStream = false;
      if (PlatformUtils.isDesktop) {
        setting.put(SettingBoxKey.desktopVolume, volume.toPrecision(3));
      }
    });
  }

  /// Toggle Change the videofit accordingly
  void toggleVideoFit(VideoFitType value) {
    _prefFit = videoFit.value = value;
    video.put(VideoBoxKey.cacheVideoFit, value.index);
  }

  /// 读取fit
  var _prefFit = VideoFitType.values[Pref.cacheVideoFit];
  void _initVideoFit() {
    if (_prefFit == .fill && _isVertical) {
      videoFit.value = .contain;
    } else {
      videoFit.value = _prefFit;
    }
  }

  /// 设置后台播放
  void setBackgroundPlay(bool val) {
    videoPlayerServiceHandler?.enableBackgroundPlay = val;
    if (!tempPlayerConf) {
      setting.put(SettingBoxKey.enableBackgroundPlay, val);
    }
  }

  set controls(bool visible) {
    showControls.value = visible;
    _timer?.cancel();
    if (visible) {
      hideTaskControls();
    }
  }

  Timer? longPressTimer;
  void cancelLongPressTimer() {
    longPressTimer?.cancel();
    longPressTimer = null;
  }

  /// 设置长按倍速状态 live模式下禁用
  Future<void> setLongPressStatus(bool val) async {
    if (isLive) {
      return;
    }
    if (controlsLock.value) {
      return;
    }
    if (longPressStatus.value == val) {
      return;
    }
    if (val) {
      if (playerStatus.isPlaying) {
        longPressStatus.value = val;
        HapticFeedback.lightImpact();
        await setPlaybackSpeed(
          enableAutoLongPressSpeed ? playbackSpeed * 2 : longPressSpeed,
        );
      }
    } else {
      // if (kDebugMode) debugPrint('$playbackSpeed');
      longPressStatus.value = val;
      await setPlaybackSpeed(lastPlaybackSpeed);
    }
  }

  bool get isCompleted =>
      videoPlayerController!.state.completed ||
      durationInMilliseconds - positionInMilliseconds <= 50;

  // 双击播放、暂停
  Future<void> onDoubleTapCenter() async {
    if (!isLive && isCompleted) {
      await videoPlayerController!.seek(Duration.zero);
      videoPlayerController!.play();
    } else {
      videoPlayerController!.playOrPause();
    }
  }

  final RxBool mountSeekBackwardButton = false.obs;
  final RxBool mountSeekForwardButton = false.obs;

  void onDoubleTapSeekBackward() {
    mountSeekBackwardButton.value = true;
  }

  void onDoubleTapSeekForward() {
    mountSeekForwardButton.value = true;
  }

  void onForward(Duration duration) {
    onForwardBackward(videoPlayerController!.state.position + duration);
  }

  void onBackward(Duration duration) {
    onForwardBackward(videoPlayerController!.state.position - duration);
  }

  void onForwardBackward(Duration duration) {
    seekTo(
      duration.clamp(Duration.zero, videoPlayerController!.state.duration),
      isSeek: false,
    ).whenComplete(play);
  }

  void doubleTapFuc(DoubleTapType type) {
    if (!enableQuickDouble) {
      onDoubleTapCenter();
      return;
    }
    switch (type) {
      case DoubleTapType.left:
        // 双击左边区域 👈
        onDoubleTapSeekBackward();
        break;
      case DoubleTapType.center:
        onDoubleTapCenter();
        break;
      case DoubleTapType.right:
        // 双击右边区域 👈
        onDoubleTapSeekForward();
        break;
    }
  }

  /// 关闭控制栏
  void onLockControl(bool val) {
    feedBack();
    controlsLock.value = val;
    if (!val && showControls.value) {
      showControls.refresh();
    }
    controls = !val;
  }

  void _setFullScreen(bool val) {
    isFullScreen.value = val;
    updateSubtitleStyle();
    if (!OS.isHarmony) return;

    if (!val) {
      HarmonyChannel.onLandscapeOrMiniWindowChange(false, null); // 非横屏
    } else if (!isVertical) {
      HarmonyChannel.onLandscapeOrMiniWindowChange(true, null); // 横屏
    }
  }

  double screenRatio = 0.0;
  bool isManualFS = true;
  // 每次读取而不缓存：播放器是跨页面存活的单例，缓存会让在设置页改完
  // 「默认全屏方向」后本次会话仍用旧值，表现为「改了没反应」
  FullScreenMode get mode => Pref.fullScreenMode;
  late final horizontalScreen = Pref.horizontalScreen;
  late final removeSafeArea = Pref.removeSafeArea;

  Future<void>? changeOrientation({
    required bool isVertical,
    DeviceOrientation? orientation,
    bool isManualFS = true,
  }) async {
    if (orientation == null && mode == .none) {
      return;
    }
    if (orientation == null && mode == .gravity) {
      // 上游的 gravity 依赖方向监听器主动转屏，鸿蒙无该插件，改为放开四方向交给系统
      return OS.isHarmony ? harmonyFullAutoMode() : null;
    }
    // 自动进全屏（倾斜手机触发，isManualFS=false）时不再把窗口强制转到视频方向：
    // 保持设备当前方向、窗口跟随重力旋转——竖屏视频横向倾斜后停在横屏全屏，
    // 转回竖屏时停在竖屏全屏（对齐上游安卓效果）。只有手动进全屏才转到视频方向。
    if (orientation == null &&
        !isManualFS &&
        (mode == .auto || mode == .ratio)) {
      return;
    }
    final bool toPortrait =
        orientation == null &&
        (mode == .vertical ||
            (mode == .auto && isVertical) ||
            (mode == .ratio && (isVertical || screenRatio < kScreenRatio)));
    // 自适应类模式下，若系统开着自动旋转，就不把方向轴锁死：先转到视频方向
    // （点全屏按钮该有的反应），转完继续跟随设备，转回另一方向时页面会自动
    // 退出全屏。「强制竖屏 / 强制横屏」是显式指定，始终锁轴，不走这里。
    if (orientation == null &&
        (mode == .auto || mode == .ratio) &&
        !await HarmonyChannel.isRotationLocked()) {
      // 窗口已经在目标方向轴上就别动：USER_ROTATION_* 是「先转到该轴的默认
      // 朝向、之后再跟随传感器」，此时下发会把已经跟着设备转好的朝向硬掰回
      // 默认朝向（横屏即左边在下），要等下一次传感器变化才纠正回来。
      // screenRatio = 窗口高/宽，由播放页在尺寸变化时同步，0 表示尚未拿到。
      if (screenRatio > 0 && (screenRatio < 1) != toPortrait) {
        return;
      }
      return userRotateMode(landscape: !toPortrait);
    }
    if (toPortrait) {
      // 锁定竖屏轴，轴内仍按重力 180° 翻转
      return portraitAxisMode();
    } else {
      // 鸿蒙拿不到设备朝向（无 native_device_orientation），不能像下面那样锁定单一
      // 横屏方向，否则只能朝一边转。交给系统在左右横屏间按重力自动切换。
      if (OS.isHarmony) {
        return harmonyLandscapeAutoMode();
      }
      // https://github.com/flutter/flutter/issues/73651
      // https://github.com/flutter/flutter/issues/183708
      if (Platform.isAndroid) {
        if ((orientation ?? _orientation) == .landscapeRight) {
          return landscapeRightMode();
        } else {
          return landscapeLeftMode();
        }
      } else {
        if (orientation == .landscapeLeft) {
          return landscapeLeftMode();
        } else {
          return landscapeRightMode();
        }
      }
    }
  }

  // 全屏
  bool _fsProcessing = false;
  Future<void> triggerFullScreen({
    bool status = true,
    bool inAppFullScreen = false,
    DeviceOrientation? orientation,
    bool isManualFS = true,
  }) async {
    if (isDesktopPip) return;
    if (isFullScreen.value == status) return;

    if (_fsProcessing) return;
    _fsProcessing = true;
    this.isManualFS = isManualFS;
    try {
      if (status) {
        if (PlatformUtils.isMobile) {
          hideSystemBar();
          await changeOrientation(
            isVertical: isVertical,
            orientation: orientation,
            isManualFS: isManualFS,
          );
          if (OS.isHarmony && isManualFS) {
            // 手动进全屏的目标方向：横屏时等视口真正变横屏再置全屏布局，
            // 避免全屏先在竖屏/中间尺寸渲染，导致比例错误和动画跳变。
            final targetLandscape =
                orientation != null ||
                switch (mode) {
                  .vertical => false,
                  .horizontal => true,
                  .auto => !isVertical,
                  .ratio => !isVertical && screenRatio >= kScreenRatio,
                  _ => false,
                };
            if (targetLandscape) {
              await _waitForLandscapeViewport();
            }
          }
        } else {
          await enterDesktopFullScreen(inAppFullScreen: inAppFullScreen);
        }
      } else {
        if (PlatformUtils.isMobile) {
          if (!removeSafeArea) {
            if (OS.isHarmony && isManualFS) {
              // 手动退出：先恢复系统栏并等安全区变化在 Flutter 侧落定，
              // 再旋转并切回普通布局，避免普通页 AppBar 在旋转结束后才增长。
              // 自动退出（旋转回正触发）时旋转已在途中，跳过等待，
              // 让状态栏变化被旋转动画盖住。
              await showSystemBar('controller_fullscreen_exit');
              await Future<void>.delayed(kSystemBarSettleDelay);
            } else {
              showSystemBar('controller_fullscreen_exit');
            }
          }
          if (orientation == null && mode == .none) {
            return;
          }
          await (restorePageOrientation ?? resetScreenRotation)();
        } else {
          await exitDesktopFullScreen();
        }
      }
    } finally {
      _setFullScreen(status);
      _fsProcessing = false;
    }
  }

  /// 等待平台视口旋转为横屏（宽>高），带超时兜底。
  Future<void> _waitForLandscapeViewport({
    Duration timeout = const Duration(milliseconds: 600),
  }) async {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final view = views.first;
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMilliseconds < timeout.inMilliseconds) {
      final size = view.physicalSize;
      if (size.width > size.height) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  void addPositionListener(ValueChanged<Duration> listener) {
    if (_playerCount == 0) return;
    _positionListeners.add(listener);
  }

  void removePositionListener(ValueChanged<Duration> listener) =>
      _positionListeners.remove(listener);

  void addStatusLister(ValueChanged<PlayerStatus> listener) {
    if (_playerCount == 0) return;
    _statusListeners.add(listener);
  }

  void removeStatusLister(ValueChanged<PlayerStatus> listener) =>
      _statusListeners.remove(listener);

  // 记录播放记录
  Future<void>? makeHeartBeat(
    int progress, {
    HeartBeatType type = .playing,
    bool isManual = false,
    dynamic aid,
    dynamic bvid,
    dynamic cid,
    dynamic epid,
    dynamic seasonId,
    dynamic pgcType,
    VideoType? videoType,
  }) {
    if (isLive ||
        !enableHeart ||
        progress == 0 ||
        (playerStatus.isPaused && !isManual)) {
      return null;
    }

    Future<void> send() {
      return VideoHttp.heartBeat(
        aid: aid ?? _aid,
        bvid: bvid ?? _bvid,
        cid: cid ?? this.cid,
        progress: progress,
        epid: epid ?? _epid,
        seasonId: seasonId ?? _seasonId,
        subType: pgcType ?? _pgcType,
        videoType: videoType ?? _videoType,
      );
    }

    switch (type) {
      case .playing:
        if (progress - _heartDuration >= 5) {
          _heartDuration = progress;
          return send();
        }
      case .status:
        if (progress - _heartDuration >= 2) {
          _heartDuration = progress;
          return send();
        }
      case .completed:
        if (playerStatus.isCompleted &&
            (durationInMilliseconds - positionInMilliseconds) <= 1000) {
          progress = -1;
        }
        return send();
    }
    return null;
  }

  void setPlayRepeat(PlayRepeat type) {
    playRepeat = type;
    final handler = videoPlayerServiceHandler;
    handler?.updateRepeatMode(type);
    // 视频页循环模式也支持从播控中心/实况窗切换
    handler?.onRepeatModeChanged = (repeat) async {
      setPlayRepeat(repeat);
    };
    if (!tempPlayerConf) video.put(VideoBoxKey.playRepeat, type.index);
  }

  void putSubtitleSettings() {
    setting.putAllNE({
      SettingBoxKey.subtitleFontScale: subtitleFontScale,
      SettingBoxKey.subtitleFontScaleFS: subtitleFontScaleFS,
      SettingBoxKey.subtitlePaddingH: subtitlePaddingH,
      SettingBoxKey.subtitlePaddingB: subtitlePaddingB,
      SettingBoxKey.subtitleBgOpacity: subtitleBgOpacity,
      SettingBoxKey.subtitleStrokeWidth: subtitleStrokeWidth,
      SettingBoxKey.subtitleFontWeight: subtitleFontWeight,
    });
  }

  // isCloseAll 由外部页面直接置位（新 ohos 提交的写法），故为公开字段
  bool isCloseAll = false;

  /// 退出全屏后恢复的「页面级方向」。由播放页在存续期间注册（见
  /// video/view.dart）：关闭横屏适配时页面本身也要跟随设备方向，不能像
  /// 播放器销毁那样直接锁回竖屏。未注册时退回 [resetScreenRotation]。
  Future<void>? Function()? restorePageOrientation;

  /// 播放器销毁时恢复应用级方向：开着横屏适配跟随系统，否则锁回竖屏
  Future<void>? resetScreenRotation() {
    if (horizontalScreen) {
      return fullMode();
    } else {
      return portraitUpMode();
    }
  }

  void onCloseAll() {
    isCloseAll = true;
    // dispose 已改为异步（退后台清内存），这里不阻塞路由返回
    unawaited(dispose());
    Get.until((route) => route.isFirst);
  }

  Future<void> dispose() async {
    // 每次减1，最后销毁
    resetScreenRotation();
    cancelLongPressTimer();
    _cancelSubForSeek();
    if (!isCloseAll && _playerCount > 1) {
      _playerCount -= 1;
      _heartDuration = 0;
      return;
    }

    _playerCount = 0;
    if (removeSafeArea) {
      showSystemBar('controller_dispose');
    }
    danmakuController = null;
    _stopOrientationListener();
    _disableAutoEnterPip();
    setPlayCallBack(null);
    dmState.clear();
    if (showSeekPreview) {
      _clearPreview();
    }
    if (Platform.isAndroid) {
      AndroidHelper$ToDart.onUserLeaveHint?.release();
      AndroidHelper$ToDart.onUserLeaveHint = null;
    }
    _timer?.cancel();
    // _position.close();
    // _playerEventSubs?.cancel();
    // _sliderPosition.close();
    // _sliderTempPosition.close();
    // _isSliderMoving.close();
    // _duration.close();
    // _buffered.close();
    // _showControls.close();
    // _controlsLock.close();

    // playerStatus.close();
    // dataStatus.close();

    if (PlatformUtils.isDesktop && isAlwaysOnTop.value) {
      windowManager.setAlwaysOnTop(false);
    }

    _removeListeners();
    _positionListeners.clear();
    _statusListeners.clear();
    if (playerStatus.isPlaying) {
      WakelockPlus.disable();
    }
    if (kDebugMode) {
      debugPrint('dispose player');
    }
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _videoController = null;
    _instance = null;
    videoPlayerServiceHandler?.clear();
    HarmonyChannel.releaseContinuation(this);
  }

  static Future<void> updatePlayCount() async {
    if (_instance?._playerCount == 1) {
      await _instance?.dispose();
    } else {
      _instance?._playerCount -= 1;
    }
  }

  void setContinuePlayInBackground() {
    continuePlayInBackground.value = !continuePlayInBackground.value;
    if (!tempPlayerConf) {
      setting.put(
        SettingBoxKey.continuePlayInBackground,
        continuePlayInBackground.value,
      );
    }
  }

  void setOnlyPlayAudio() {
    onlyPlayAudio.value = !onlyPlayAudio.value;
    videoPlayerController?.setVideoTrack(
      onlyPlayAudio.value ? VideoTrack.no() : VideoTrack.auto(),
    );
  }

  late final Map<String, ui.Image?> previewCache = {};
  LoadingState<VideoShotData>? videoShot;
  late final RxBool showPreview = false.obs;
  late final showSeekPreview = Pref.showSeekPreview;
  late final previewIndex = RxnInt();

  void updatePreviewIndex(int seconds) {
    if (videoShot == null) {
      videoShot = LoadingState.loading();
      getVideoShot();
      return;
    }
    if (videoShot case Success(:final response)) {
      showPreview.value = true;
      previewIndex.value = max(
        0,
        (response.index.where((item) => item <= seconds).length - 2),
      );
    }
  }

  void _clearPreview() {
    showPreview.value = false;
    previewIndex.value = null;
    videoShot = null;
    for (final i in previewCache.values) {
      i?.dispose();
    }
    previewCache.clear();
  }

  Future<void> getVideoShot() async {
    videoShot = await VideoHttp.videoshot(bvid: bvid, cid: cid!);
  }

  Future<void> takeScreenshot() async {
    SmartDialog.showToast('截图中');
    // 鸿蒙 media_kit fork 的 screenshot 返回 Uint8List（上游 fork 返回 ui.Image）
    final bytes = await videoPlayerController?.screenshot(format: 'image/png');
    if (bytes == null) {
      SmartDialog.showToast('截图失败');
      return;
    }
    final time = DurationUtils.formatDuration(
      positionInMilliseconds / 1000,
    ).replaceAll(':', '-');
    SmartDialog.showToast('点击弹窗保存截图');
    showDialog(
      context: Get.context!,
      builder: (context) => GestureDetector(
        onTap: () {
          Get.back();
          ImageUtils.saveByteImg(
            bytes: bytes,
            fileName: 'screenshot_${cid}_$time',
          );
        },
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: min(MediaQuery.widthOf(context) / 3, 350),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 5,
                    color: ColorScheme.of(context).surface,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.memory(bytes),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) {
      if (playerStatus.isPlaying) {
        pause();
      }

      setPlayCallBack(null);

      if ((Platform.isAndroid || OS.isHarmony) && _playerCount <= 1) {
        _disableAutoEnterPip();
        if (!setSystemBrightness) {
          ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
        }
      }

      return;
    }

    if (controlsLock.value) {
      onLockControl(false);
      return;
    }
    if (isDesktopPip) {
      exitDesktopPip();
      return;
    }
    if (isFullScreen.value) {
      triggerFullScreen(status: false);
      return;
    }
    Get.back();
  }
}
