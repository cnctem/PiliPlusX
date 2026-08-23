/// 见 pubspec.yaml 顶部说明：3.41 上把 cupertino_ui 映射回 SDK 内置 Cupertino。
///
/// `TranslateAnimationSource` 在 SDK 中标了 `@internal`，转导出会触发
/// invalid_export_of_internal_element，业务代码也用不到，这里隐藏掉。
library;

export 'package:flutter/cupertino.dart' hide TranslateAnimationSource;
