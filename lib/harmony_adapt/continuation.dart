import 'dart:convert';

import 'package:PiliPlus/grpc/bilibili/app/listener/v1.pb.dart'
    show PlaylistSource;
import 'package:PiliPlus/harmony_adapt/harmony_channel.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/pages/article/controller.dart';
import 'package:PiliPlus/pages/audio/controller.dart';
import 'package:PiliPlus/pages/audio/view.dart';
import 'package:PiliPlus/pages/live_room/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// 鸿蒙跨设备接续（流转）：支持视频/直播/音频页/专栏文章。
/// 源端在系统回调 onContinue 时经 harmonyChannel 采集当前内容与播放状态
/// （播放中/暂停原样迁移），对端启动/唤醒后取回数据并跳转到对应页面。
abstract class HarmonyContinuation {
  /// 源端：从最近的“可接续”持有者生成快照（JSON），无可接续内容时为 null
  static String? currentState() {
    for (final owner in HarmonyChannel.continuationOwners.reversed) {
      final map = switch (owner) {
        PlPlayerController c => c.playSnapshot,
        LiveRoomController c => _liveState(c),
        AudioController c => _audioState(c),
        ArticleController c => _articleState(c),
        _ => null,
      };
      if (map != null) {
        return jsonEncode(map);
      }
    }
    return null;
  }

  static Map<String, dynamic> _liveState(LiveRoomController c) => {
    'type': 'live',
    'roomId': c.roomId,
    'playing': c.plPlayerController.playerStatus.isPlaying,
    'onlyPlayAudio': c.plPlayerController.onlyPlayAudio.value,
  };

  static Map<String, dynamic> _audioState(AudioController c) => {
    'type': 'audioPage',
    'id': c.id.toInt(),
    'oid': c.oid.toInt(),
    'subId': c.subId.map((e) => e.toInt()).toList(),
    'itemType': c.itemType,
    'from': c.from.value,
    'extraId': c.extraId?.toInt(),
    'progress': c.position.value.inMilliseconds,
    'playing': c.isPlaying(),
  };

  static Map<String, dynamic> _articleState(ArticleController c) => {
    'type': 'article',
    'id': c.id,
    'articleType': c.type,
  };

  /// 对端：按源端快照跳转到对应页面并恢复播放/暂停状态
  static void restore(String? data) {
    if (data == null || data.isEmpty) {
      return;
    }
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      switch (map['type']) {
        case 'video':
          _restoreVideo(map);
        case 'live':
          _restoreLive(map);
        case 'audioPage':
          _restoreAudio(map);
        case 'article':
          _restoreArticle(map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('continuation restore error: $e');
    }
  }

  static void _restoreVideo(Map<String, dynamic> map) {
    final int? aid = map['aid'];
    final String? bvid = map['bvid'];
    final int? cid = map['cid'];
    if (cid == null || (aid == null && bvid == null)) {
      return;
    }
    final int? progress = map['progress'];
    PageUtils.toVideoPage(
      videoType:
          VideoType.values.asNameMap()[map['videoType']] ?? VideoType.ugc,
      aid: aid,
      bvid: bvid,
      cid: cid,
      epId: map['epid'],
      seasonId: map['seasonId'],
      pgcType: map['pgcType'],
      progress: progress != null && progress > 0 ? progress : null,
      extraArguments: {
        // 接续是用户明确的“继续观看”动作，播放/暂停状态原样迁移，
        // 覆盖本机自动播放设置
        'autoPlay': map['playing'] ?? true,
        if (map['onlyPlayAudio'] == true) 'onlyPlayAudio': true,
      },
    );
  }

  static void _restoreLive(Map<String, dynamic> map) {
    final int? roomId = map['roomId'];
    if (roomId == null) {
      return;
    }
    final query = [
      if (map['playing'] == false) 'autoplay=false',
      if (map['onlyPlayAudio'] == true) 'onlyAudio=true',
    ];
    Get.toNamed(
      query.isEmpty ? '/liveRoom' : '/liveRoom?${query.join('&')}',
      arguments: roomId,
    );
  }

  static void _restoreAudio(Map<String, dynamic> map) {
    final int? oid = map['oid'];
    final int? itemType = map['itemType'];
    final from = PlaylistSource.valueOf(map['from'] ?? -1);
    if (oid == null || itemType == null || from == null) {
      return;
    }
    final int? progress = map['progress'];
    AudioPage.toAudioPage(
      id: map['id'],
      oid: oid,
      subId: (map['subId'] as List?)?.cast<int>(),
      itemType: itemType,
      from: from,
      extraId: map['extraId'],
      start: progress != null && progress > 0
          ? Duration(milliseconds: progress)
          : null,
      autoplay: map['playing'] ?? true,
    );
  }

  static void _restoreArticle(Map<String, dynamic> map) {
    final String? id = map['id'];
    final String? type = map['articleType'];
    if (id == null || type == null) {
      return;
    }
    Get.toNamed('/articlePage', parameters: {'id': id, 'type': type});
  }
}
