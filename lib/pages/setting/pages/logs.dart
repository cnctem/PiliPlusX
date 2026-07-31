import 'dart:async' show Timer;
import 'dart:convert' show jsonDecode;
import 'dart:io' show Platform;

import 'package:PiliPlus/build_config.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/selection_text.dart';
import 'package:PiliPlus/services/logger.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:catcher_2/model/platform_type.dart';
import 'package:catcher_2/model/report.dart' as catcher;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:os_type/os_type.dart';

const _snackBarDisplayDuration = Duration(seconds: 1);

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<_ExpandedItem<Report>> logsContent = [];
  _ExpandedItem<_DeviceInfo>? _deviceInfo;
  Report? latestLog;
  late bool enableLog = Pref.enableLog;

  @override
  void initState() {
    _initDeviceInfo();
    getLog();
    super.initState();
  }

  @override
  void dispose() {
    if (latestLog != null) {
      final time = latestLog!.dateTime;
      if (DateTime.now().difference(time) >= const Duration(days: 14)) {
        LoggerUtils.clearLogs();
      }
    }
    super.dispose();
  }

  Future<void> _initDeviceInfo() async {
    final device = await _loadDeviceParameters();
    final info = _loadApplicationParameters();
    final custom = _loadCustomParameters();
    _deviceInfo = _ExpandedItem((device, info, custom));
    if (mounted) {
      setState(() {});
    }
  }

  Future<Map<String, dynamic>> _loadDeviceParameters() async {
    final device = <String, dynamic>{};
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (OS.isHarmony) {
        final ohosInfo = await deviceInfo.ohosInfo;
        device.addAll(ohosInfo.data);
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        device.addAll({
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        device.addAll({
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
        });
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        device.addAll({
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores,
          'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
        });
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        device.addAll({
          'name': linuxInfo.name,
          'version': linuxInfo.version,
          'prettyName': linuxInfo.prettyName,
        });
      } else if (Platform.isMacOS) {
        final macosInfo = await deviceInfo.macOsInfo;
        device.addAll(macosInfo.data);
      }
    } catch (e) {
      debugPrint('Failed to load device info: $e');
    }
    return device;
  }

  Map<String, dynamic> _loadApplicationParameters() => {
    'versionName': BuildConfig.versionName,
    'versionCode': BuildConfig.versionCode,
  };

  Map<String, dynamic> _loadCustomParameters() => {
    'Build Time': DateFormatUtils.format(
      BuildConfig.buildTime,
      format: DateFormatUtils.longFormatDs,
    ),
    if (BuildConfig.commitHash.isNotEmpty) 'Commit Hash': BuildConfig.commitHash,
  };

  Future<void> getLog() async {
    final logsPath = await LoggerUtils.getLogsPath();
    logsContent = (await logsPath.readAsLines()).reversed.map((i) {
      try {
        final log = Report.fromJson(jsonDecode(i));
        latestLog ??= log;
        return _ExpandedItem(log);
      } catch (e, s) {
        return _ExpandedItem(
          Report(
            'Parse log failed: $e\n\n\n$i',
            s,
            DateTime.now(),
            const {},
            const {},
            const {},
            null,
            PlatformType.unknown,
            null,
          ),
        );
      }
    }).toList();
    if (mounted) {
      setState(() {});
    }
  }

  void copyLogs() {
    Utils.copyText(
      '```\n${logsContent.join('\n\n')}```',
      needToast: false,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('复制成功'),
          duration: _snackBarDisplayDuration,
        ),
      );
    }
  }

  Future<void> clearLogs() async {
    latestLog = null;
    if (await LoggerUtils.clearLogs()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已清空'),
            duration: _snackBarDisplayDuration,
          ),
        );
        logsContent.clear();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('日志'),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => [
              if (kDebugMode)
                PopupMenuItem(
                  onTap: () => Timer.periodic(
                    const Duration(milliseconds: 3500),
                    (timer) {
                      Utils.reportError('Manual', StackTrace.current);
                      if (timer.tick > 3) {
                        timer.cancel();
                        if (mounted) getLog();
                      }
                    },
                  ),
                  child: const Text('引发错误'),
                ),
              PopupMenuItem(
                onTap: () {
                  enableLog = !enableLog;
                  GStorage.setting.put(SettingBoxKey.enableLog, enableLog);
                  SmartDialog.showToast('已${enableLog ? '开启' : '关闭'}，重启生效');
                },
                child: Text('${enableLog ? '关闭' : '开启'}日志'),
              ),
              PopupMenuItem(
                onTap: copyLogs,
                child: const Text('复制日志'),
              ),
              PopupMenuItem(
                onTap: () =>
                    PageUtils.launchURL('${Constants.sourceCodeUrl}/issues'),
                child: const Text('错误反馈'),
              ),
              PopupMenuItem(
                onTap: clearLogs,
                child: const Text('清空日志'),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: logsContent.isNotEmpty || _deviceInfo != null
          ? Padding(
              padding: EdgeInsets.only(
                left: padding.left + 12,
                right: padding.right + 12,
              ),
              child: CustomScrollView(
                slivers: [
                  if (_deviceInfo != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const .only(bottom: 12),
                        child: _InfoCard(info: _deviceInfo!),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: padding.bottom + 100),
                    sliver: SliverList.separated(
                      itemCount: logsContent.length,
                      itemBuilder: (context, index) =>
                          _ReportCard(report: logsContent[index]),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                    ),
                  ),
                ],
              ),
            )
          : scrollableError,
    );
  }
}

typedef _DeviceInfo = (
  Map<String, dynamic>,
  Map<String, dynamic>,
  Map<String, dynamic>,
);

class _InfoCard extends StatelessWidget {
  final _ExpandedItem<_DeviceInfo> info;

  const _InfoCard({required this.info});

  Widget _buildMapSection(
    Color color,
    String title,
    Map<String, dynamic> map,
  ) {
    if (map.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontWeight: .bold, color: color, fontSize: 15),
        ),
        ...map.entries.map(
          (entry) => Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '• ${entry.key}: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: entry.value.toString(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return _card([
      Row(
        spacing: 8,
        children: [
          Icon(
            Icons.info_outline,
            size: 22,
            color: colorScheme.primary,
          ),
          const Expanded(
            child: Text(
              '相关信息',
              style: TextStyle(fontWeight: .bold, fontSize: 15),
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ),
          iconButton(
            size: 34,
            iconSize: 22,
            tooltip: info.isExpanded ? '收起' : '展开',
            icon: Icon(
              info.isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onPressed: () {
              info.isExpanded = !info.isExpanded;
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      if (info.isExpanded) ...[
        _buildMapSection(colorScheme.primary, '设备信息', info.item.$1),
        _buildMapSection(colorScheme.primary, '应用信息', info.item.$2),
        _buildMapSection(colorScheme.primary, '编译信息', info.item.$3),
      ],
    ]);
  }
}

/// Formats a stack trace string into a list of non-empty lines.
List<String> _formatStackString(String? stackTrace) {
  if (stackTrace == null || stackTrace.isEmpty || stackTrace == 'null') {
    return const [];
  }
  return stackTrace
      .split('\n')
      .map((line) => line.trimRight())
      .where((line) => line.isNotEmpty)
      .toList();
}

class _ReportCard extends StatelessWidget {
  final _ExpandedItem<Report> report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    late final stackTrace = _formatStackString(
      report.item.stackTrace?.toString(),
    );
    final dateTime = DateFormatUtils.longFormatDs.format(report.item.dateTime);
    return _card([
      Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              spacing: 6,
              crossAxisAlignment: .start,
              children: [
                Text(
                  report.item.error.toString(),
                  style: const TextStyle(fontWeight: .bold, fontSize: 15),
                  maxLines: 2,
                  overflow: .ellipsis,
                ),
                Text(
                  dateTime,
                  style: TextStyle(
                    height: 1.2,
                    color: colorScheme.outline,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          iconButton(
            size: 34,
            iconSize: 22,
            tooltip: '复制',
            onPressed: () {
              Utils.copyText('```\n$report```', needToast: false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已将 $dateTime 复制至剪贴板'),
                  duration: _snackBarDisplayDuration,
                ),
              );
            },
            icon: const Icon(Icons.copy_outlined, size: 16),
          ),
          iconButton(
            size: 34,
            iconSize: 22,
            tooltip: report.isExpanded ? '收起' : '展开',
            icon: Icon(
              report.isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onPressed: () {
              report.isExpanded = !report.isExpanded;
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      if (report.isExpanded) ...[
        const SizedBox(height: 16),
        Text(
          '错误详情',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.error,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const .all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const .all(.circular(8)),
            border: .all(color: colorScheme.outline.withValues(alpha: 0.5)),
          ),
          child: SelectionText(
            report.item.error.toString(),
            style: TextStyle(
              fontFamily: 'Monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // stackTrace may be null or String("null") or blank
        if (stackTrace.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '堆栈跟踪',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const .all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const .all(.circular(8)),
              border: .all(color: colorScheme.outline.withValues(alpha: 0.5)),
            ),
            child: SelectionText.rich(
              TextSpan(
                children: stackTrace
                    .map(
                      (i) => TextSpan(
                        text: '$i\n',
                        style: i.contains('(package:${Constants.appName}')
                            ? TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: .w600,
                              )
                            : TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                    .toList(),
              ),
              style: const TextStyle(fontFamily: 'Monospace', fontSize: 13),
            ),
          ),
        ],
      ],
    ]);
  }
}

Widget _card(List<Widget> contents) {
  return Card(
    child: Padding(
      padding: const .all(12),
      child: Column(
        crossAxisAlignment: .stretch,
        children: contents,
      ),
    ),
  );
}

class _ExpandedItem<T> {
  bool isExpanded = false;
  final T item;

  _ExpandedItem(this.item);

  @override
  String toString() => item.toString();
}

class Report extends catcher.Report {
  Report(
    super.error,
    super.stackTrace,
    super.dateTime,
    super.deviceParameters,
    super.applicationParameters,
    super.customParameters,
    super.errorDetails,
    super.platformType,
    super.screenshot,
  );

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    json['error'],
    json['stackTrace'],
    DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime(1970),
    json['deviceParameters'] ?? const {},
    json['applicationParameters'] ?? const {},
    json['customParameters'] ?? const {},
    null,
    PlatformType.values.byName(json['platformType']),
    null,
  );

  Report copyWith({
    dynamic error,
    dynamic stackTrace,
    DateTime? dateTime,
    Map<String, dynamic>? deviceParameters,
    Map<String, dynamic>? applicationParameters,
    Map<String, dynamic>? customParameters,
    FlutterErrorDetails? errorDetails,
    PlatformType? platformType,
  }) {
    return Report(
      error ?? this.error,
      stackTrace ?? this.stackTrace,
      dateTime ?? this.dateTime,
      deviceParameters ?? this.deviceParameters,
      applicationParameters ?? this.applicationParameters,
      customParameters ?? this.customParameters,
      errorDetails ?? this.errorDetails,
      platformType ?? this.platformType,
      null,
    );
  }

  String _params2String(Map<String, dynamic> params) {
    return params.entries
        .map((entry) => '${entry.key}: ${entry.value}\n')
        .join();
  }

  @override
  String toString() {
    return '------- DEVICE INFO -------\n${_params2String(deviceParameters)}'
        '------- APP INFO -------\n${_params2String(applicationParameters)}'
        '------- ERROR -------\n$error\n'
        '------- STACK TRACE -------\n${stackTrace.toString().trim()}\n'
        '------- CUSTOM INFO -------\n${_params2String(customParameters)}';
  }
}