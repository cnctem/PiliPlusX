import 'dart:io' show Platform;

import 'package:os_type/os_type.dart';

abstract final class PlatformUtils {
  static final bool isMobile = OS.isMobileOS;

  static final bool isDesktop = OS.isPCOS;

  @pragma("vm:platform-const")
  static final bool isDarwin = Platform.isIOS || Platform.isMacOS;
}

