import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:stream_transform/stream_transform.dart';

/// Extension on [BaseCacheManager] to provide a [getSingleFile] convenience
/// method, which was available in flutter_cache_manager but is not included
/// in cached_network_image_ce's BaseCacheManager.
extension CacheManagerGetSingleFile on BaseCacheManager {
  /// Returns a [Future<File>] of the cached or newly downloaded file.
  ///
  /// This is functionally equivalent to the old `getSingleFile` from
  /// flutter_cache_manager: it streams the file (from cache or network)
  /// and returns the first [FileInfo]'s [File].
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    final fileInfo = await getFileStream(
      url,
      key: key,
      headers: headers,
      withProgress: false,
    ).whereType<FileInfo>().first;
    return fileInfo.file;
  }
}
