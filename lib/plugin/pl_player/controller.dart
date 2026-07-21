import 'dart:async' show StreamSubscription, Timer;
import 'dart:convert' show ascii;
import 'dart:io' show Platform;
import 'dart:math' show max, min;
import 'dart:ui' as ui;

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/harmony_adapt/harmony_channel.dart';
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
import 'package:PiliPlus/pages/mine/controller.dart';
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
import 'package:PiliPlus/utils/asset_utils.dart';
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
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:os_type/os_type.dart';
import 'package:path/path.dart' as path;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

typedef PlayCallback = Future<void>? Function();

class PlPlayerController with BlockConfigMixin {
  Player? _videoPlayerController;
  VideoController? _videoController;

  // 添加一个私有静态变量来保存实例
  static PlPlayerController? _instance;

  // 流事件  监听播放状态变化
  // StreamSubscription? _playerEventSubs;

  /// [playerStatus] has a [status] observable
  final playerStatus = PlPlayerStatus(PlayerStatus.playing);

  ///
  final Rx<DataStatus> dataStatus = Rx(DataStatus.none);

  // bool controlsEnabled = false;

  /// 响应数据
  /// 带有Seconds的变量只在秒数更新时更新，以避免频繁触发重绘
  // 播放位置
  Duration position = Duration.zero;
  final RxInt positionSeconds = 0.obs;

  /// 进度条位置
  Duration sliderPosition = Duration.zero;
  final RxInt sliderPositionSeconds = 0.obs;
  // 展示使用
  final Rx<Duration> sliderTempPosition = Rx(Duration.zero);

  /// 视频时长
  final Rx<Duration> duration = Rx(Duration.zero);

  /// 视频缓冲
  final Rx<Duration> buffered = Rx(Duration.zero);
  final RxInt bufferedSeconds = 0.obs;

  int _playerCount = 0;

  late double lastPlaybackSpeed = 1.0;
  final RxDouble _playbackSpeed = Pref.playSpeedDefault.obs;
  late final RxDouble _longPressSpeed = Pref.longPressSpeedDefault.obs;

  /// 音量控制条
  final RxDouble volume = RxDouble(
    PlatformUtils.isDesktop ? Pref.desktopVolume : 1.0,
  );

  /// 实际音量
  final actualVolume = 0.0.obs;
  final setSystemBrightness = Pref.setSystemBrightness;

  /// 亮度控制条
  final RxDouble brightness = (-1.0).obs;

  /// 是否展示控制条
  final RxBool showControls = false.obs;

  /// 亮度控制条展示/隐藏
  final RxBool showBrightnessStatus = false.obs;

  /// 是否长按倍速
  final RxBool longPressStatus = false.obs;

  /// 屏幕锁 为true时，关闭控制栏
  final RxBool controlsLock = false.obs;

  /// 全屏状态
  final RxBool isFullScreen = false.obs;
  // 默认投稿视频格式
  bool isLive = false;

  bool _isVertical = false;

  /// 视频比例
  final Rx<VideoFitType> videoFit = Rx(VideoFitType.contain);

  /// 后台播放
  late final RxBool continuePlayInBackground =
      Pref.continuePlayInBackground.obs;

  ///
  final RxBool isSliderMoving = false.obs;

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
  StreamSubscription<Duration>? _subForSeek;

  // 鸿蒙：mpv 的 ohaudio 音频输出感知不到系统音频打断（如其他 app 抢占焦点），
  // 被打断后 mpv 仍自认为在播放，进度停滞、UI 按钮状态错误且无法点击恢复。
  // 用位置停滞检测兜底：播放中且非缓冲时位置连续数秒不前进，视为被系统打断。
  Timer? _stallWatchdog;
  Duration? _stallLastPosition;
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
      'progress': position.inMilliseconds,
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
  bool get isVertical => _isVertical;

  /// 弹幕开关
  late final RxBool _enableShowDanmaku = Pref.enableShowDanmaku.obs;
  late final RxBool _enableShowLiveDanmaku = Pref.enableShowLiveDanmaku.obs;
  RxBool get enableShowDanmaku =>
      isLive ? _enableShowLiveDanmaku : _enableShowDanmaku;

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

  late bool _shouldSetPip = false;

  bool get _isCurrVideoPage {
    final routing = Get.routing;
    if (routing.route is! GetPageRoute) {
      return false;
    }
    final currentRoute = routing.current;
    return currentRoute.startsWith('/video') ||
        currentRoute.startsWith('/liveRoom');
  }

  bool get _isPreviousVideoPage {
    final previousRoute = Get.previousRoute;
    return previousRoute.startsWith('/video') ||
        previousRoute.startsWith('/liveRoom');
  }

  Future<PiPStatus> enterPip({bool isAuto = false}) {
    if (videoPlayerController != null) {
      controls = false;
      final state = videoPlayerController!.state;
      return PageUtils.enterPip(
        isAuto: isAuto,
        width: state.width == 0 ? width : state.width,
        height: state.height == 0 ? height : state.height,
      );
    }
    return Future.value(PiPStatus.unavailable);
  }

  void _disableAutoEnterPipIfNeeded() {
    if (!_isPreviousVideoPage) {
      _disableAutoEnterPip();
    }
  }

  void _disableAutoEnterPip() {
    if (_shouldSetPip) {
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

  num get sliderScale =>
      isRelative ? duration.value.inMilliseconds * offset : offset;

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

  void updateSliderPositionSecond() {
    int newSecond = sliderPosition.inSeconds;
    if (sliderPositionSeconds.value != newSecond) {
      sliderPositionSeconds.value = newSecond;
    }
  }

  void updatePositionSecond() {
    int newSecond = position.inSeconds;
    if (positionSeconds.value != newSecond) {
      positionSeconds.value = newSecond;
    }
  }

  void updateBufferedSecond() {
    int newSecond = buffered.value.inSeconds;
    if (bufferedSeconds.value != newSecond) {
      bufferedSeconds.value = newSecond;
    }
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
    // await _instance?.play(repeat: repeat, hideControls: hideControls);
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

  static Future<void>? setVolumeIfExists(double volumeNew) {
    return _instance?.setVolume(volumeNew);
  }

  Box video = GStorage.video;

  // 添加一个私有构造函数
  PlPlayerController._() {
    if (!Accounts.heartbeat.isLogin || Pref.historyPause) {
      enableHeart = false;
    }

    if (autoPiP) {
      if (Platform.isAndroid) {
        Utils.sdkInt.then((sdkInt) {
          if (sdkInt < 36) {
            Utils.channel.setMethodCallHandler((call) async {
              if (call.method == 'onUserLeaveHint') {
                if (playerStatus.isPlaying && _isCurrVideoPage) {
                  enterPip();
                }
              }
            });
          } else {
            _shouldSetPip = true;
          }
        });
      } else if (OS.isHarmony) {
        _shouldSetPip = true;
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

  // 初始化资源
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
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
        _videoController = null;
        return;
      }

      // 获取视频时长 00:00
      this.duration.value = duration ?? _videoPlayerController!.state.duration;
      position = buffered.value = sliderPosition = seekTo ?? Duration.zero;
      updatePositionSecond();
      updateSliderPositionSecond();
      updateBufferedSecond();
      // 数据加载完成
      dataStatus.value = DataStatus.loaded;

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
    };
    if (Platform.isAndroid) {
      opt['volume-max'] = '100';
      opt['ao'] = Pref.audioOutput;
    } else if (PlatformUtils.isDesktop) {
      opt['volume'] = (volume.value * 100).toString();
    }
    final autosync = Pref.autosync;
    if (autosync != '0') {
      opt['autosync'] = autosync;
    }

    final player = Player(
      configuration: PlayerConfiguration(
        bufferSize: Pref.expandBuffer
            ? (isLive ? 64 * 1024 * 1024 : 32 * 1024 * 1024)
            : (isLive ? 16 * 1024 * 1024 : 4 * 1024 * 1024),
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

  // 配置播放器
  Future<void> _createVideoController(
    DataSource dataSource,
    Duration? seekTo,
    Volume? volume,
  ) async {
    isBuffering.value = false;
    buffered.value = Duration.zero;
    _heartDuration = 0;
    position = Duration.zero;
    // 初始化时清空弹幕，防止上次重叠
    danmakuController?.clear();

    var player = _videoPlayerController;

    if (player == null) {
      player = await _initPlayer();
      if (_playerCount == 0) {
        _removeListeners();
        player.dispose();
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
      if (kDebugMode || Platform.isAndroid) {
        String audioNormalization = AudioNormalization.getParamFromConfig(
          Pref.audioNormalization,
        );
        if (volume != null && volume.isNotEmpty) {
          audioNormalization = audioNormalization.replaceFirstMapped(
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
          audioNormalization = audioNormalization.replaceFirst(
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
        start: position,
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
      stream.playing.listen((event) {
        WakelockPlus.toggle(enable: event);
        if (event) {
          if (_shouldSetPip) {
            if (_isCurrVideoPage) {
              enterPip(isAuto: true);
            } else {
              _disableAutoEnterPip();
            }
          }
          playerStatus.value = PlayerStatus.playing;
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
          Floating().updatePipControlStatus(playing: event);
        }
        videoPlayerServiceHandler?.onStatusChange(
          playerStatus.value,
          isBuffering.value,
          isLive,
        );

        /// 触发回调事件
        for (final element in _statusListeners) {
          element(event ? PlayerStatus.playing : PlayerStatus.paused);
        }
        if (videoPlayerController!.state.position.inSeconds != 0) {
          makeHeartBeat(positionSeconds.value, type: HeartBeatType.status);
        }
      }),
      stream.completed.listen((event) {
        if (event) {
          playerStatus.value = PlayerStatus.completed;

          /// 触发回调事件
          for (final element in _statusListeners) {
            element(PlayerStatus.completed);
          }
        } else {
          // playerStatus.value = PlayerStatus.playing;
        }
        makeHeartBeat(positionSeconds.value, type: HeartBeatType.completed);
      }),
      stream.position.listen((event) {
        position = event;
        updatePositionSecond();
        if (!isSliderMoving.value) {
          sliderPosition = event;
          updateSliderPositionSecond();
        }

        /// 触发回调事件
        for (final element in _positionListeners) {
          element(event);
        }
        makeHeartBeat(event.inSeconds);
      }),
      stream.duration.listen((Duration event) {
        duration.value = event;
      }),
      stream.buffer.listen((Duration event) {
        buffered.value = event;
        updateBufferedSecond();
      }),
      stream.buffering.listen((bool event) {
        isBuffering.value = event;
        videoPlayerServiceHandler?.onStatusChange(
          playerStatus.value,
          event,
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
                if (isBuffering.value && buffered.value == Duration.zero) {
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
      // controllerStream.volume.listen((event) {
      //   if (!mute.value && _volumeBeforeMute != event) {
      //     _volumeBeforeMute = event / 100;
      //   }
      // }),
      // 媒体通知监听
      if (videoPlayerServiceHandler != null) ...[
        playerStatus.listen((PlayerStatus event) {
          videoPlayerServiceHandler!.onStatusChange(
            event,
            isBuffering.value,
            isLive,
          );
        }),
        positionSeconds.listen((int event) {
          videoPlayerServiceHandler!.onPositionChange(Duration(seconds: event));
        }),
      ],
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
        final wantPlay =
            status == null ? !playerStatus.isPlaying : status == 1;
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
          position == Duration.zero) {
        _stallTicks = 0;
        _stallLastPosition = null;
        return;
      }
      if (position == _stallLastPosition) {
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
        _stallLastPosition = position;
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
    // if (position >= duration.value) {
    //   position = duration.value - const Duration(milliseconds: 100);
    // }
    if (_playerCount == 0) {
      return;
    }
    if (position < Duration.zero) {
      position = Duration.zero;
    }
    this.position = position;
    updatePositionSecond();
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

    if (duration.value != Duration.zero) {
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
      if (!isSliderMoving.value && !tripling) {
        controls = false;
      }
      _timer = null;
    });
  }

  /// 调整播放时间
  void onChangedSlider(int v) {
    sliderPosition = Duration(seconds: v);
    updateSliderPositionSecond();
  }

  void onChangedSliderStart([Duration? value]) {
    if (value != null) {
      sliderTempPosition.value = value;
    }
    isSliderMoving.value = true;
  }

  bool? cancelSeek;
  bool? hasToast;

  void onUpdatedSliderProgress(Duration value) {
    sliderTempPosition.value = value;
    sliderPosition = value;
    updateSliderPositionSecond();
  }

  void onChangedSliderEnd() {
    if (cancelSeek != true) {
      feedBack();
    }
    cancelSeek = null;
    hasToast = null;
    isSliderMoving.value = false;
    hideTaskControls();
  }

  final RxBool volumeIndicator = false.obs;
  Timer? volumeTimer;
  bool volumeInterceptEventStream = false;

  static final double maxVolume = PlatformUtils.isDesktop ? 2.0 : 1.0;
  Future<void> setVolume(double volume) async {
    if (this.volume.value != volume ||
        (PlatformUtils.isMobile &&
            await FlutterVolumeController.getVolume() != this.volume.value)) {
      this.volume.value = volume;
      try {
        if (PlatformUtils.isDesktop) {
          _videoPlayerController!.setVolume(volume * 100);
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
    volumeIndicator.value = true;
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

  bool get _isCompleted =>
      videoPlayerController!.state.completed ||
      (duration.value - position).inMilliseconds <= 50;

  // 双击播放、暂停
  Future<void> onDoubleTapCenter() async {
    if (!isLive && _isCompleted) {
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
    onForwardBackward(position + duration);
  }

  void onBackward(Duration duration) {
    onForwardBackward(position - duration);
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

  void toggleFullScreen(bool val) {
    isFullScreen.value = val;
    updateSubtitleStyle();
    if (!OS.isHarmony) return;

    if (!val) {
      HarmonyChannel.onLandscapeOrMiniWindowChange(false, null); // 非横屏
    } else if (!isVertical) {
      HarmonyChannel.onLandscapeOrMiniWindowChange(true, null); // 横屏
    }
  }

  late bool isManualFS = true;
  late final FullScreenMode mode = Pref.fullScreenMode;
  late final horizontalScreen = Pref.horizontalScreen;

  // 全屏
  bool fsProcessing = false;
  Future<void> triggerFullScreen({
    bool status = true,
    bool inAppFullScreen = false,
    bool isManualFS = true,
    FullScreenMode? mode,
  }) async {
    if (isDesktopPip) return;
    if (isFullScreen.value == status) return;

    if (fsProcessing) {
      return;
    }
    fsProcessing = true;
    toggleFullScreen(status);
    try {
      mode ??= this.mode;
      this.isManualFS = isManualFS;

      if (status) {
        if (PlatformUtils.isMobile) {
          hideStatusBar();
          if (mode == FullScreenMode.none) {
            return;
          }
          if (mode == FullScreenMode.gravity) {
            await fullAutoModeForceSensor();
            return;
          }
          late final size = MediaQuery.sizeOf(Get.context!);
          if ((mode == FullScreenMode.vertical ||
              (mode == FullScreenMode.auto && isVertical) ||
              (mode == FullScreenMode.ratio &&
                  (isVertical || size.height / size.width < kScreenRatio)))) {
            await verticalScreenForTwoSeconds();
          } else {
            await landscape();
          }
        } else {
          await enterDesktopFullscreen(inAppFullScreen: inAppFullScreen);
        }
      } else {
        if (PlatformUtils.isMobile) {
          showStatusBar();
          if (mode == FullScreenMode.none) {
            return;
          }
          if (!horizontalScreen) {
            await verticalScreenForTwoSeconds();
          } else {
            await autoScreen();
          }
        } else {
          await exitDesktopFullscreen();
        }
      }
    } finally {
      fsProcessing = false;
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
    HeartBeatType type = HeartBeatType.playing,
    bool isManual = false,
    dynamic aid,
    dynamic bvid,
    dynamic cid,
    dynamic epid,
    dynamic seasonId,
    dynamic pgcType,
    VideoType? videoType,
  }) {
    if (isLive) {
      return null;
    }
    if (!enableHeart || MineController.anonymity.value || progress == 0) {
      return null;
    } else if (playerStatus.isPaused) {
      if (!isManual) {
        return null;
      }
    }
    bool isComplete =
        playerStatus.isCompleted || type == HeartBeatType.completed;
    if ((duration.value - position).inMilliseconds > 1000) {
      isComplete = false;
    }
    // 播放状态变化时，更新

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
      case HeartBeatType.playing:
        if (progress - _heartDuration >= 5) {
          _heartDuration = progress;
          return send();
        }
      case HeartBeatType.status:
        if (progress - _heartDuration >= 2) {
          _heartDuration = progress;
          return send();
        }
      case HeartBeatType.completed:
        if (isComplete) progress = -1;
        return send();
    }
    return null;
  }

  void setPlayRepeat(PlayRepeat type) {
    playRepeat = type;
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

  bool isCloseAll = false;
  void dispose() {
    // 每次减1，最后销毁
    cancelLongPressTimer();
    _cancelSubForSeek();
    if (!isCloseAll && _playerCount > 1) {
      _playerCount -= 1;
      _heartDuration = 0;
      if (!_isPreviousVideoPage) {
        pause();
      }
      return;
    }

    _playerCount = 0;
    danmakuController = null;
    _disableAutoEnterPip();
    setPlayCallBack(null);
    dmState.clear();
    if (showSeekPreview) {
      _clearPreview();
    }
    Utils.channel.setMethodCallHandler(null);
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
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _videoController = null;
    _instance = null;
    videoPlayerServiceHandler?.clear();
    HarmonyChannel.releaseContinuation(this);
  }

  static void updatePlayCount() {
    if (_instance?._playerCount == 1) {
      _instance?.dispose();
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

  void takeScreenshot() {
    SmartDialog.showToast('截图中');
    videoPlayerController?.screenshot(format: 'image/png').then((value) {
      if (value != null) {
        SmartDialog.showToast('点击弹窗保存截图');
        showDialog(
          context: Get.context!,
          builder: (context) => GestureDetector(
            onTap: () {
              Get.back();
              ImageUtils.saveByteImg(
                bytes: value,
                fileName: 'screenshot_${ImageUtils.time}',
              );
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: min(Get.width / 3, 350),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 5,
                        color: Get.theme.colorScheme.surface,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.memory(value),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        SmartDialog.showToast('截图失败');
      }
    });
  }

  bool onPopInvokedWithResult(bool didPop, Object? result) {
    if ((Platform.isAndroid || OS.isHarmony) && didPop) {
      _disableAutoEnterPipIfNeeded();
    }
    if (controlsLock.value) {
      onLockControl(false);
      return true;
    }
    if (isDesktopPip) {
      exitDesktopPip();
      return true;
    }
    if (isFullScreen.value) {
      triggerFullScreen(status: false);
      return true;
    }
    return false;
  }
}
