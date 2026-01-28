import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/material.dart';

Widget selectableText(
  String text, {
  TextStyle? style,
}) {
  if (PlatformUtils.isDesktop) {
    return SelectionArea(
      child: Text(
        style: style,
        text,
      ),
    );
  }
  return SelectableText(
    style: style,
    text,
    scrollPhysics: const NeverScrollableScrollPhysics(),
  );
}
