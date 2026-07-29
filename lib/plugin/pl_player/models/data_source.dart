import 'dart:io' show File;

import 'package:PiliPlus/utils/path_utils.dart';
import 'package:path/path.dart' as path;

/// 把本地文件路径规整为绝对路径，供 mpv 使用。
///
/// media_kit 的 `Media.normalizeURI` 依赖 uri_parser 判断是否为本地文件，而
/// uri_parser 只认以 `/` 或 `X:/` 开头的路径（见其 `_isFileOrDirectory`）。
/// 鸿蒙的公共下载目录写作 `storage/Users/currentUser/Download/<bundle>`，没有
/// 前导斜杠：Dart 侧的文件 API 会按进程工作目录解析，所以扫描列表正常，但 mpv
/// 拿到的是相对路径，会一直卡在加载中。
///
/// 这里用 `File.absolute` 而非硬拼 `/` 或 `file://`，因为它按真实工作目录解析，
/// 对已是绝对路径的情况（桌面端自定义下载目录）也是幂等的。
String _absoluteFilePath(String p) => File(p).absolute.path;

sealed class DataSource {
  final String videoSource;
  final String? audioSource;

  DataSource({
    required this.videoSource,
    required this.audioSource,
  });
}

class NetworkSource extends DataSource {
  NetworkSource({
    required super.videoSource,
    required super.audioSource,
  });
}

class FileSource extends DataSource {
  final String dir;
  final bool isMp4;

  FileSource({
    required this.dir,
    required this.isMp4,
    required bool hasDashAudio,
    required String typeTag,
  }) : super(
         videoSource: _absoluteFilePath(
           path.join(
             dir,
             typeTag,
             isMp4 ? PathUtils.videoNameType1 : PathUtils.videoNameType2,
           ),
         ),
         audioSource: isMp4 || !hasDashAudio
             ? null
             : _absoluteFilePath(
                 path.join(dir, typeTag, PathUtils.audioNameType2),
               ),
       );
}
