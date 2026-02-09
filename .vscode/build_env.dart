import 'dart:convert';
import 'dart:io';

void main() async {
  // 手动指定 versionName
  const versionName = '1.1.5.3-ohos-1-pre2';

  // 通过 git 命令获取 hash 和 code
  final versionCode = await _getGitCommitCount();
  final commitHash = await _getGitCommitHash();

  final env = {
    '此环境变量由脚本自动生成': '请勿编辑',
    'pili.name': versionName,
    // 别问为什么除以1000，因为解码那边不知道为什么乘了1000
    'pili.time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'pili.hash': commitHash,
    'pili.code': versionCode,
  };
  File('./.vscode/env.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(env));
}

// 获取 Git 提交数量作为版本号
Future<int> _getGitCommitCount() async {
  try {
    final result = await Process.run('git', ['rev-list', '--count', 'HEAD']);
    if (result.exitCode == 0) {
      return int.tryParse(result.stdout.toString().trim()) ?? 0;
    }
  } catch (e) {
    print('获取 Git 提交数量失败: $e');
  }
  return 0;
}

// 获取 Git 提交哈希值
Future<String> _getGitCommitHash() async {
  try {
    final result = await Process.run('git', ['rev-parse', 'HEAD']);
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
  } catch (e) {
    print('获取 Git 提交哈希值失败: $e');
  }
  return '';
}
