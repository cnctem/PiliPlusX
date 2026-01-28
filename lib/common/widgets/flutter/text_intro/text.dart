import 'package:PiliPlus/common/widgets/flutter/text_intro/selectable_text.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/material.dart' hide SelectableText;

Widget selectableRichText(
  TextSpan textSpan, {
  TextStyle? style,
}) {
  if (PlatformUtils.isDesktop) {
    return SelectionArea(
      child: Text.rich(
        style: style,
        textSpan,
      ),
    );
  }
  return SelectableText.rich(
    style: style,
    textSpan,
    scrollPhysics: const NeverScrollableScrollPhysics(),
  );
}
