# OHOS 适配记录（2025-12-16）

记录 Flutter -> OHOS 过程中各三方插件的可用性及处理建议，便于后续协同。

## 关键插件现状

- `flutter_volume_controller`：系统媒体音量读写，暂无 OHOS 适配；OHOS 端先移除/打桩，如需保留需自研 MethodChannel 封装系统音量接口。
- `flutter_displaymode`：Android 高刷/分辨率切换，OHOS 无对应实现；OHOS 构建直接排除。
- `wakelock_plus`：保持屏幕常亮，已有 `wakelock_plus_ohos` 变体，已接入。
- `floating`：悬浮窗/小窗（PIP），OHOS 未见可用适配且权限受限；OHOS 构建移除或用自绘 overlay 替代。
- `window_manager`：桌面窗口管理（尺寸/置顶/无边框），仅桌面适用；OHOS 构建排除。
- `tray_manager`：桌面系统托盘菜单；OHOS 不适用，排除。
- `audio_service` / `audio_session`：后台音频与系统媒体控制，官方未支持 OHOS；短期可仅前台播放（`media_kit`），长期需自研 OHOS 后台服务并封装兼容接口。
- `gt3_flutter_plugin`：极验验证码插件，未找到 OHOS 适配；可改用 H5 验证流程或自研。
- `image_cropper`：图片裁剪，可使用社区 `imagecropper_ohos` 适配包，待接入。
- `live_photo_maker`：生成 iOS Live Photo，OHOS 无对应能力；OHOS 端关闭或改为 GIF/短视频导出。
- `flutter_inappwebview`：已替换为 OHOS fork（gitcode 开源仓），当前可用。

## 后续建议

1. 在代码中对 OHOS 平台条件编译/禁用：`flutter_displaymode`、`floating`、`window_manager`、`tray_manager`、`gt3_flutter_plugin`、`live_photo_maker`、`flutter_volume_controller`（若未自研实现）。
2. 如需裁剪功能，加入 `imagecropper_ohos` 并验证接口兼容性。
3. 若业务需要后台音频或系统音量控制，评估自研 OHOS 插件或采用 OHOS 原生媒体服务能力。
