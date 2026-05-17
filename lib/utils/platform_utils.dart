import 'package:os_type/os_type.dart';

abstract final class PlatformUtils {
  static final isMobile = OS.isMobileOS;

  static final isDesktop = OS.isPCOS;
}
