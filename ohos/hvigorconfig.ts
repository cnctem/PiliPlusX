import path from 'path'
import fs from 'fs'
import { execSync } from 'child_process'
import { injectNativeModules } from 'flutter-hvigor-plugin'

// 将版本信息注入到 Flutter 的 DART_DEFINES，便于 BuildConfig 读取
(() => {
  const projectRoot = path.dirname(__dirname)

  const readPubVersion = () => {
    try {
      const pubspec = fs.readFileSync(path.join(projectRoot, 'pubspec.yaml'), 'utf8')
      const match = pubspec.match(/version:\s*([\w\.\+\-]+)/)
      if (match && match[1]) return match[1]
    } catch (_) {}
    return '1.1.5'
  }

  const gitRevCount = () => {
    try {
      return parseInt(execSync('git rev-list --count HEAD').toString().trim(), 10)
    } catch (_) {
      return 1
    }
  }

  const gitShortHash = () => {
    try {
      return execSync('git rev-parse --short=9 HEAD').toString().trim()
    } catch (_) {
      return 'N/A'
    }
  }

  const gitCommitTime = () => {
    try {
      return parseInt(execSync('git show -s --format=%ct HEAD').toString().trim(), 10)
    } catch (_) {
      return Math.floor(Date.now() / 1000)
    }
  }

  const pubVersion = readPubVersion()
  // 去掉 pubspec 自带的 +build 元数据，避免重复添加 versionCode
  const baseVersion = pubVersion.split('+')[0]
  const versionCode = gitRevCount()              // 例如 4442
  const commitHash = gitShortHash()              // 例如 3741fe54f
  const buildTime = gitCommitTime()              // Git 最新提交的时间戳（秒）

  // 上游展示形态示例：1.1.5-3741fe54f+4442
  const versionName = `${baseVersion}-${commitHash}+${versionCode}`

  const defines = [
    `pili.name=${versionName}`,
    `pili.code=${versionCode}`,
    `pili.hash=${commitHash}`,
    `pili.time=${buildTime}`,
  ]

  // Flutter assemble expects each define to be Base64-encoded individually, then comma-joined
  process.env.DART_DEFINES = defines
    .map(d => Buffer.from(d).toString('base64'))
    .join(',')
})()

injectNativeModules(__dirname, path.dirname(__dirname))
