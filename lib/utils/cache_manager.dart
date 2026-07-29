import 'dart:io' show Directory, File;

import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

/// 鸿蒙分支使用 pub.dev 上的 cached_network_image_ce，它没有上游 fork 的
/// `DefaultCacheManager.init` / `getTotalLength` / `cacheDir` / `getSingleFile`，
/// 因此这里保留 ohos 原本基于临时目录统计的实现，并补一个 [getSingleFile] 扩展
/// 以便调用点与上游保持一致。
abstract final class CacheManager {
  static late final DefaultCacheManager manager;

  static Future<void> ensureInitialized() async {
    manager = DefaultCacheManager(
      maxNrOfCacheObjects: Pref.maxCacheSize.toInt(),
    );
  }

  // 获取缓存目录
  @pragma('vm:notify-debugger-on-exception')
  static Future<int> loadApplicationCache([
    final num maxSize = double.infinity,
  ]) async {
    try {
      final Directory tempDirectory = await getTemporaryDirectory();
      if (PlatformUtils.isDesktop) {
        final dir = Directory('${tempDirectory.path}/cached_network_image_ce');
        if (dir.existsSync()) {
          return await getTotalSizeOfFilesInDir(dir, maxSize);
        }
        return 0;
      }
      if (tempDirectory.existsSync()) {
        return await getTotalSizeOfFilesInDir(tempDirectory, maxSize);
      }
    } catch (_) {}
    return 0;
  }

  // 循环计算文件的大小
  @pragma('vm:notify-debugger-on-exception')
  static Future<int> getTotalSizeOfFilesInDir(
    final Directory file, [
    final num maxSize = double.infinity,
  ]) async {
    int total = 0;
    await for (final child in file.list(recursive: true)) {
      if (child is File) {
        total += await child.length();
        if (total >= maxSize) return total;
      }
    }
    return total;
  }

  // 缓存大小格式转换
  static String formatSize(num value) {
    const unitArr = ['B', 'K', 'M', 'G', 'T', 'P'];
    int index = 0;
    while (value >= 1024) {
      index++;
      value = value / 1024;
    }
    String size = value.toStringAsFixed(2);
    return size + (unitArr.elementAtOrNull(index) ?? '');
  }

  // 清除 Library/Caches 目录及文件缓存
  @pragma('vm:notify-debugger-on-exception')
  static Future<void> clearLibraryCache() async {
    try {
      await manager.emptyCache();
      final tempDirectory = await getTemporaryDirectory();
      if (PlatformUtils.isDesktop) {
        final dir = Directory('${tempDirectory.path}/cached_network_image_ce');
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
        return;
      }
      if (tempDirectory.existsSync()) {
        await for (final file in tempDirectory.list(recursive: false)) {
          await file.delete(recursive: true);
        }
      }
    } catch (_) {}
  }
}

/// 补齐上游 fork 才有的 `getSingleFile`，基于 4.9.0 的 [getFileStream] 实现。
extension DefaultCacheManagerExt on DefaultCacheManager {
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    await for (final res in getFileStream(url, key: key, headers: headers)) {
      if (res is FileInfo) return res.file;
    }
    throw StateError('failed to fetch file: $url');
  }
}
