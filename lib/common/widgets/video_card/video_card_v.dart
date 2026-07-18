import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/flutter/layout_builder.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart' hide LayoutBuilder;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';

// 视频卡片 - 垂直布局
class VideoCardV extends StatefulWidget {
  final BaseRecVideoItemModel videoItem;
  final VoidCallback? onRemove;

  const VideoCardV({
    super.key,
    required this.videoItem,
    this.onRemove,
  });

  @override
  State<VideoCardV> createState() => _VideoCardVState();

  static final shortFormat = DateFormat('M-d');
  static final longFormat = DateFormat('yy-M-d');
}

class _VideoCardVState extends State<VideoCardV> with AutomaticKeepAliveClientMixin  {
  Future<void> onPushDetail(String heroTag) async {
    String? goto = widget.videoItem.goto;
    switch (goto) {
      case 'bangumi':
        PageUtils.viewPgc(epId: widget.videoItem.param!);
        break;
      case 'av':
        String bvid = widget.videoItem.bvid ?? IdUtils.av2bv(widget.videoItem.aid!);
        int? cid =
            widget.videoItem.cid ??
            await SearchHttp.ab2c(aid: widget.videoItem.aid, bvid: bvid);
        if (cid != null) {
          PageUtils.toVideoPage(
            aid: widget.videoItem.aid,
            bvid: bvid,
            cid: cid,
            cover: widget.videoItem.cover,
            title: widget.videoItem.title,
          );
        }
        break;
      // 动态
      case 'picture':
        try {
          PiliScheme.routePushFromUrl(widget.videoItem.uri!);
        } catch (err) {
          SmartDialog.showToast(err.toString());
        }
        break;
      default:
        if (widget.videoItem.uri?.isNotEmpty == true) {
          PiliScheme.routePushFromUrl(widget.videoItem.uri!);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    void onLongPress() => imageSaveDialog(
      title: widget.videoItem.title,
      cover: widget.videoItem.cover,
      bvid: widget.videoItem.bvid,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => onPushDetail(Utils.makeHeroTag(widget.videoItem.aid)),
            onLongPress: onLongPress,
            onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: StyleString.aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      double maxWidth = boxConstraints.maxWidth;
                      double maxHeight = boxConstraints.maxHeight;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          NetworkImgLayer(
                            src: widget.videoItem.cover,
                            width: maxWidth,
                            height: maxHeight,
                            borderRadius: BorderRadius.zero, // 此处应为非表情类型，且默认不需要圆角
                          ),
                          if (widget.videoItem.duration > 0)
                            PBadge(
                              bottom: 6,
                              right: 7,
                              size: PBadgeSize.small,
                              type: PBadgeType.gray,
                              text: DurationUtils.formatDuration(
                                widget.videoItem.duration,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                content(context),
              ],
            ),
          ),
        ),
        if (widget.videoItem.goto == 'av')
          Positioned(
            right: -5,
            bottom: -2,
            width: 29,
            height: 29,
            child: VideoPopupMenu(
              iconSize: 17,
              videoItem: widget.videoItem,
              onRemove: widget.onRemove,
            ),
          ),
      ],
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                "${widget.videoItem.title}\n",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  height: 1.38,
                ),
              ),
            ),
            videoStat(context, theme),
            Row(
              spacing: 2,
              children: [
                if (widget.videoItem.goto == 'bangumi')
                  PBadge(
                    text: widget.videoItem.pgcBadge,
                    isStack: false,
                    size: PBadgeSize.small,
                    type: PBadgeType.line_primary,
                    fontSize: 9,
                  ),
                if (widget.videoItem.rcmdReason != null)
                  PBadge(
                    text: widget.videoItem.rcmdReason,
                    isStack: false,
                    size: PBadgeSize.small,
                    type: PBadgeType.secondary,
                  ),
                if (widget.videoItem.goto == 'picture')
                  const PBadge(
                    text: '动态',
                    isStack: false,
                    size: PBadgeSize.small,
                    type: PBadgeType.line_primary,
                    fontSize: 9,
                  ),
                if (widget.videoItem.isFollowed)
                  const PBadge(
                    text: '已关注',
                    isStack: false,
                    size: PBadgeSize.small,
                    type: PBadgeType.secondary,
                  ),
                Expanded(
                  flex: 1,
                  child: Text(
                    widget.videoItem.owner.name.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    semanticsLabel: 'UP：${widget.videoItem.owner.name}',
                    style: TextStyle(
                      height: 1.5,
                      fontSize: theme.textTheme.labelMedium!.fontSize,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                if (widget.videoItem.goto == 'av') const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget videoStat(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        StatWidget(
          type: StatType.play,
          value: widget.videoItem.stat.view,
        ),
        if (widget.videoItem.goto != 'picture') ...[
          const SizedBox(width: 4),
          StatWidget(
            type: StatType.danmaku,
            value: widget.videoItem.stat.danmu,
          ),
        ],
        if (widget.videoItem is RecVideoItemModel) ...[
          const Spacer(),
          Text.rich(
            maxLines: 1,
            TextSpan(
              style: TextStyle(
                fontSize: theme.textTheme.labelSmall!.fontSize,
                color: theme.colorScheme.outline.withValues(alpha: 0.8),
              ),
              text: DateFormatUtils.dateFormat(
                widget.videoItem.pubdate,
                short: VideoCardV.shortFormat,
                long: VideoCardV.longFormat,
              ),
            ),
          ),
          const SizedBox(width: 2),
        ],
        // deprecated
        //  else if (videoItem is RecVideoItemAppModel &&
        //     videoItem.desc != null &&
        //     videoItem.desc!.contains(' · ')) ...[
        //   const Spacer(),
        //   Text.rich(
        //     maxLines: 1,
        //     TextSpan(
        //         style: TextStyle(
        //           fontSize: theme.textTheme.labelSmall!.fontSize,
        //           color: theme.colorScheme.outline.withValues(alpha: 0.8),
        //         ),
        //         text: Utils.shortenChineseDateString(
        //             videoItem.desc!.split(' · ').last)),
        //   ),
        //   const SizedBox(width: 2),
        // ]
      ],
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}
