import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video/cdn_type.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

sealed class CdnSelectResult {
  const CdnSelectResult();
}

final class CdnBuiltinResult extends CdnSelectResult {
  const CdnBuiltinResult(this.service);

  final CDNService service;
}

final class CdnCustomResult extends CdnSelectResult {
  const CdnCustomResult(this.host);

  final String host;
}

final class CdnClearCustomResult extends CdnSelectResult {
  const CdnClearCustomResult();
}

/// 保存 CDN 选择的唯一入口：写存储、同步运行时静态变量、toast
Future<void> applyCdnSelectResult(
  CdnSelectResult result, {
  String toastSuffix = '',
}) async {
  switch (result) {
    case CdnBuiltinResult(:final service):
      VideoUtils.cdnService = service;
      VideoUtils.customCDNUrl = null;
      await GStorage.setting.put(SettingBoxKey.CDNService, service.name);
      await GStorage.setting.delete(SettingBoxKey.customCDNUrl);
      SmartDialog.showToast('已设置为 ${service.desc}$toastSuffix');
    case CdnCustomResult(:final host):
      VideoUtils.customCDNUrl = host;
      await GStorage.setting.put(SettingBoxKey.customCDNUrl, host);
      SmartDialog.showToast('已设置自定义 CDN：$host$toastSuffix');
    case CdnClearCustomResult():
      VideoUtils.customCDNUrl = null;
      await GStorage.setting.delete(SettingBoxKey.customCDNUrl);
      SmartDialog.showToast('已清除自定义 CDN$toastSuffix');
  }
}

/// 下载测速，供内置枚举全量测速与节点点按测速复用
class CdnSpeedTester {
  CdnSpeedTester({this.sample});

  BaseItem? sample;
  Dio? _dio;
  final List<CancelToken> _tokens = [];

  Dio get dio => _dio ??= Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'user-agent': BrowserUa.pc,
        'referer': HttpString.baseUrl,
      },
    ),
  );

  Future<BaseItem> getSample() async {
    if (sample case final sample?) {
      return sample;
    }
    final result = await VideoHttp.videoUrl(
      cid: 196018899,
      bvid: 'BV1fK4y1t7hj',
      tryLook: false,
      videoType: VideoType.ugc,
    );
    final item = result.dataOrNull?.dash?.video?.first;
    if (item == null) throw Exception('无法获取视频流');
    return sample = item;
  }

  /// 最多下载 8MB / 15s，返回速度或错误描述
  Future<String> measure(String url) async {
    const maxSize = 8 * 1024 * 1024;
    const maxDuration = 15000000;
    final token = CancelToken();
    _tokens.add(token);
    int downloaded = 0;
    String? result;
    final start = DateTime.now().microsecondsSinceEpoch;
    String format(int bytes, int duration) =>
        '${(bytes / duration).toStringAsPrecision(3)}MB/s';
    try {
      await dio.get(
        url,
        cancelToken: token,
        onReceiveProgress: (count, total) {
          downloaded = count;
          final duration = DateTime.now().microsecondsSinceEpoch - start;
          if (downloaded >= maxSize || duration > maxDuration) {
            result ??= format(downloaded, duration);
            token.cancel();
          }
        },
      );
      final duration = DateTime.now().microsecondsSinceEpoch - start;
      result ??= downloaded > 0 ? format(downloaded, duration) : '测速失败';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        result ??= '测速超时';
      } else {
        result ??= _describeError(e);
      }
    } catch (e) {
      result ??= e.toString();
    } finally {
      _tokens.remove(token);
    }
    return result!;
  }

  String _describeError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && 400 <= statusCode && statusCode < 500) {
      return '此视频可能无法替换为该CDN';
    }
    final message = error.toString();
    return message.isEmpty ? '测速失败' : message;
  }

  void dispose() {
    for (final token in List.of(_tokens)) {
      token.cancel();
    }
    _tokens.clear();
    _dio?.close(force: true);
  }
}

/// MD3E 分组列表项：组内首尾外角 12dp、内角 4dp，选中态容器色
class M3eOptionItem extends StatelessWidget {
  const M3eOptionItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final textTheme = TextTheme.of(context);
    final foreground = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurface;
    final secondary = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;
    return Material(
      color: selected
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isFirst ? 12 : 4),
        bottom: Radius.circular(isLast ? 12 : 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (leading case final leading?) ...[
                  IconTheme(
                    data: IconThemeData(size: 20, color: secondary),
                    child: leading,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: textTheme.labelLarge!.copyWith(
                          color: foreground,
                        ),
                        child: title,
                      ),
                      if (subtitle case final subtitle?)
                        DefaultTextStyle(
                          style: textTheme.bodySmall!.copyWith(
                            color: secondary,
                          ),
                          child: subtitle,
                        ),
                    ],
                  ),
                ),
                if (trailing case final trailing?) ...[
                  const SizedBox(width: 8),
                  IconTheme(
                    data: IconThemeData(size: 20, color: secondary),
                    child: trailing,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CdnSelectDialog extends StatefulWidget {
  const CdnSelectDialog({
    super.key,
    this.sample,
  });

  final BaseItem? sample;

  @override
  State<CdnSelectDialog> createState() => _CdnSelectDialogState();
}

class _CdnSelectDialogState extends State<CdnSelectDialog> {
  late final bool _cdnSpeedTest = Pref.cdnSpeedTest;
  CdnSpeedTester? _tester;
  late final List<ValueNotifier<String?>> _speedResults;

  @override
  void initState() {
    super.initState();
    if (_cdnSpeedTest) {
      _tester = CdnSpeedTester(sample: widget.sample);
      _speedResults = List.generate(
        CDNService.values.length,
        (_) => ValueNotifier<String?>(null),
      );
      _testAll();
    }
  }

  @override
  void dispose() {
    _tester?.dispose();
    if (_cdnSpeedTest) {
      for (final notifier in _speedResults) {
        notifier.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _testAll() async {
    final tester = _tester!;
    try {
      final sample = await tester.getSample();
      for (final service in CDNService.values) {
        if (!mounted) return;
        // 显式绕过全局自定义节点，否则每行测到的都是同一个自定义 host
        final url = VideoUtils.getCdnUrl(
          sample.playUrls,
          defaultCDNService: service,
          applyCustomCDN: false,
        );
        final result = await tester.measure(url);
        if (!mounted) return;
        _speedResults[service.index].value = result;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CDN speed test failed: $e');
    }
  }

  Future<void> _inputCustom() async {
    final host = await showDialog<String>(
      context: context,
      builder: (context) =>
          _CdnInputDialog(initialValue: VideoUtils.customCDNUrl),
    );
    if (host != null && mounted) {
      Navigator.pop(context, CdnCustomResult(host));
    }
  }

  @override
  Widget build(BuildContext context) {
    final customHost = VideoUtils.customCDNUrl;
    const services = CDNService.values;
    return AlertDialog(
      clipBehavior: Clip.hardEdge,
      title: const Text('CDN 设置'),
      constraints: const BoxConstraints.tightFor(width: 320),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customHost != null) ...[
              M3eOptionItem(
                isFirst: true,
                isLast: true,
                selected: true,
                title: const Text('自定义节点'),
                subtitle: Text(
                  customHost,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: '清除自定义 CDN',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.pop(context, const CdnClearCustomResult()),
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (final (index, service) in services.indexed) ...[
              if (index != 0) const SizedBox(height: 2),
              M3eOptionItem(
                isFirst: index == 0,
                isLast: index == services.length - 1,
                selected:
                    customHost == null && service == VideoUtils.cdnService,
                title: Text(service.desc),
                subtitle: _cdnSpeedTest
                    ? ValueListenableBuilder(
                        valueListenable: _speedResults[index],
                        builder: (context, value, _) => Text(
                          value ?? '---',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : null,
                onTap: () =>
                    Navigator.pop(context, CdnBuiltinResult(service)),
              ),
            ],
            const SizedBox(height: 12),
            M3eOptionItem(
              isFirst: true,
              isLast: true,
              leading: const Icon(Icons.edit_outlined),
              title: const Text('手动输入'),
              subtitle: const Text('输入任意节点 host 或完整 URL'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _inputCustom,
            ),
          ],
        ),
      ),
    );
  }
}

class _CdnInputDialog extends StatefulWidget {
  const _CdnInputDialog({this.initialValue});

  final String? initialValue;

  @override
  State<_CdnInputDialog> createState() => _CdnInputDialogState();
}

class _CdnInputDialogState extends State<_CdnInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final host = VideoUtils.normalizeCustomCDNHost(_controller.text);
    if (host == null) {
      setState(() => _errorText = '请输入有效的 host 或完整 URL');
      return;
    }
    Navigator.pop(context, host);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('自定义 CDN 节点'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'upos-sz-mirrorali.bilivideo.com',
          helperText: '支持输入完整 URL，自动提取 host',
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        onSubmitted: (_) => _onConfirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '取消',
            style: TextStyle(color: ColorScheme.of(context).outline),
          ),
        ),
        TextButton(
          onPressed: _onConfirm,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
