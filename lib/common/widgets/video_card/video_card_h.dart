import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/flutter/layout_builder.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/progress_bar/video_progress_indicator.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/material.dart' hide LayoutBuilder;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

// 视频卡片 - 水平布局
class VideoCardH extends StatelessWidget {
  const VideoCardH({
    super.key,
    required this.videoItem,
    this.onTap,
    this.onViewLater,
    this.onRemove,
  });
  final BaseVideoItemModel videoItem;
  final VoidCallback? onTap;
  final ValueChanged<int>? onViewLater;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    String type = 'video';
    String? badge;
    if (videoItem case final SearchVideoItemModel item) {
      final typeOrNull = item.type;
      if (typeOrNull != null && typeOrNull.isNotEmpty) {
        type = typeOrNull;
        if (type == 'ketang') {
          badge = '课堂';
        } else if (type == 'live_room') {
          badge = '直播';
        }
      }
      if (item.isUnionVideo == 1) {
        badge = '合作';
      }
    } else if (videoItem case final HotVideoItemModel item) {
      if (item.isCharging == true) {
        badge = '充电专属';
      } else if (item.isCooperation == 1) {
        badge = '合作';
      } else {
        badge = item.pgcLabel;
      }
    }
    void onLongPress() => imageSaveDialog(
      bvid: videoItem.bvid,
      title: videoItem.title,
      cover: videoItem.cover,
    );
    final colorScheme = ColorScheme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onLongPress: onLongPress,
            onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
            onTap:
                onTap ??
                () async {
                  if (type == 'ketang') {
                    PageUtils.viewPugv(seasonId: videoItem.aid);
                    return;
                  } else if (type == 'live_room') {
                    if (videoItem case final SearchVideoItemModel item) {
                      int? roomId = item.id;
                      if (roomId != null) {
                        PageUtils.toLiveRoom(roomId);
                      }
                    } else {
                      SmartDialog.showToast(
                        'err: live_room : ${videoItem.runtimeType}',
                      );
                    }
                    return;
                  }
                  if (videoItem case final HotVideoItemModel item) {
                    if (item.redirectUrl?.isNotEmpty == true &&
                        PageUtils.viewPgcFromUri(item.redirectUrl!)) {
                      return;
                    }
                  }

                  try {
                    final int? cid =
                        videoItem.cid ??
                        await SearchHttp.ab2c(
                          aid: videoItem.aid,
                          bvid: videoItem.bvid,
                        );
                    if (cid != null) {
                      PageUtils.toVideoPage(
                        bvid: videoItem.bvid,
                        cid: cid,
                        cover: videoItem.cover,
                        title: videoItem.title,
                      );
                    }
                  } catch (err) {
                    SmartDialog.showToast(err.toString());
                  }
                },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Style.safeSpace,
                vertical: 5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: Style.aspectRatio,
                    child: _CoverBuilderH(
                      cover: videoItem.cover,
                      badge: badge,
                      duration: videoItem.duration,
                      progress: videoItem is HotVideoItemModel
                          ? (videoItem as HotVideoItemModel).progress
                          : null,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  content(context),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 12,
            width: 29,
            height: 29,
            child: VideoPopupMenu(
              iconSize: 17,
              videoItem: videoItem,
              onRemove: onRemove,
            ),
          ),
        ],
      ),
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    String pubdate = DateFormatUtils.dateFormat(videoItem.pubdate!);
    if (pubdate != '') pubdate += '  ';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (videoItem case final SearchVideoItemModel item) ...[
            if (item.titleList?.isNotEmpty == true)
              Expanded(
                child: Text.rich(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  TextSpan(
                    children: item.titleList!
                        .map(
                          (e) => TextSpan(
                            text: e.text,
                            style: TextStyle(
                              fontSize: theme.textTheme.bodyMedium!.fontSize,
                              height: 1.42,
                              letterSpacing: 0.3,
                              color: e.isEm
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
          ] else
            Expanded(
              child: Text(
                videoItem.title,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: theme.textTheme.bodyMedium!.fontSize,
                  height: 1.42,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Text(
            "$pubdate${videoItem.owner.name}",
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              height: 1,
              color: theme.colorScheme.outline,
              overflow: TextOverflow.clip,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            spacing: 8,
            children: [
              StatWidget(
                type: StatType.play,
                value: videoItem.stat.view,
              ),
              StatWidget(
                type: StatType.danmaku,
                value: videoItem.stat.danmu,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverBuilderH extends StatefulWidget {
  const _CoverBuilderH({
    required this.cover,
    required this.badge,
    required this.duration,
    this.progress,
    required this.colorScheme,
  });

  final String? cover;
  final String? badge;
  final int duration;
  final num? progress;
  final ColorScheme colorScheme;

  @override
  State<_CoverBuilderH> createState() => _CoverBuilderHState();
}

class _CoverBuilderHState extends State<_CoverBuilderH> {
  BoxConstraints? _previousConstraints;
  Widget? _cachedChild;

  late final Widget Function(BuildContext, BoxConstraints) _builder = _build;

  Widget _build(BuildContext context, BoxConstraints constraints) {
    if (_cachedChild != null && constraints == _previousConstraints) {
      return _cachedChild!;
    }
    _previousConstraints = constraints;
    final double maxWidth = constraints.maxWidth;
    final double maxHeight = constraints.maxHeight;
    _cachedChild = Stack(
      clipBehavior: Clip.none,
      children: [
        NetworkImgLayer(
          src: widget.cover,
          width: maxWidth,
          height: maxHeight,
        ),
        if (widget.badge != null)
          PBadge(
            text: widget.badge,
            top: 6.0,
            right: 6.0,
            type: switch (widget.badge!) {
              '充电专属' => PBadgeType.error,
              _ => PBadgeType.primary,
            },
          ),
        if (widget.progress != null && widget.progress != 0) ...[
          PBadge(
            text: widget.progress == -1
                ? '已看完'
                : '${DurationUtils.formatDuration(widget.progress!)}/${DurationUtils.formatDuration(widget.duration)}',
            right: 6,
            bottom: 8,
            type: PBadgeType.gray,
          ),
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child: VideoProgressIndicator(
              color: widget.colorScheme.primary,
              backgroundColor: widget.colorScheme.secondaryContainer,
              progress: widget.progress == -1
                  ? 1
                  : widget.progress! / widget.duration,
            ),
          ),
        ] else if (widget.duration > 0)
          PBadge(
            text: DurationUtils.formatDuration(widget.duration),
            right: 6.0,
            bottom: 6.0,
            type: PBadgeType.gray,
          ),
      ],
    );
    return _cachedChild!;
  }

  @override
  void didUpdateWidget(_CoverBuilderH oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cover != widget.cover ||
        oldWidget.badge != widget.badge ||
        oldWidget.duration != widget.duration ||
        oldWidget.progress != widget.progress) {
      _cachedChild = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _builder);
  }
}
