import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/main.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class ThemeUtils {
  static ThemeData getThemeData({
    required ColorScheme colorScheme,
    required bool isDynamic,
    bool isDark = false,
  }) {
    final appFontWeight = Pref.appFontWeight.clamp(
      -1,
      FontWeight.values.length - 1,
    );
    final fontWeight = appFontWeight == -1
        ? null
        : FontWeight.values[appFontWeight];

    // 根据设置决定使用系统字体还是 HarmonyOS_Sans
    final fontFamilyFallback = Pref.useSystemFont ? null : ['HarmonyOS_Sans'];
    late final textStyle = TextStyle(fontWeight: fontWeight);
    ThemeData themeData = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: fontWeight == null
          ? TextTheme(
              bodyLarge: TextStyle(fontFamilyFallback: fontFamilyFallback),
              bodyMedium: TextStyle(fontFamilyFallback: fontFamilyFallback),
              bodySmall: TextStyle(fontFamilyFallback: fontFamilyFallback),
              displayLarge: TextStyle(fontFamilyFallback: fontFamilyFallback),
              displayMedium: TextStyle(fontFamilyFallback: fontFamilyFallback),
              displaySmall: TextStyle(fontFamilyFallback: fontFamilyFallback),
              headlineLarge: TextStyle(fontFamilyFallback: fontFamilyFallback),
              headlineMedium: TextStyle(fontFamilyFallback: fontFamilyFallback),
              headlineSmall: TextStyle(fontFamilyFallback: fontFamilyFallback),
              titleLarge: TextStyle(fontFamilyFallback: fontFamilyFallback),
              titleMedium: TextStyle(fontFamilyFallback: fontFamilyFallback),
              titleSmall: TextStyle(fontFamilyFallback: fontFamilyFallback),
              labelLarge: TextStyle(fontFamilyFallback: fontFamilyFallback),
              labelMedium: TextStyle(fontFamilyFallback: fontFamilyFallback),
              labelSmall: TextStyle(fontFamilyFallback: fontFamilyFallback),
            )
          : TextTheme(
              displayLarge:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              displayMedium:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              displaySmall:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              headlineLarge:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              headlineMedium:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              headlineSmall:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              titleLarge:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              titleMedium:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              titleSmall:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              bodyLarge:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              bodyMedium:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              bodySmall:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              labelLarge:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              labelMedium:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
              labelSmall:
                  textStyle.copyWith(fontFamilyFallback: fontFamilyFallback),
            ),
      tabBarTheme: fontWeight == null
          ? null
          : TabBarThemeData(labelStyle: textStyle),
      appBarTheme: AppBarTheme(
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        titleTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
          fontWeight: fontWeight,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        surfaceTintColor: isDynamic ? colorScheme.onSurfaceVariant : null,
      ),
      snackBarTheme: SnackBarThemeData(
        actionTextColor: colorScheme.primary,
        backgroundColor: colorScheme.secondaryContainer,
        closeIconColor: colorScheme.secondary,
        contentTextStyle: TextStyle(color: colorScheme.onSecondaryContainer),
        elevation: 20,
      ),
      popupMenuTheme: PopupMenuThemeData(
        surfaceTintColor: isDynamic ? colorScheme.onSurfaceVariant : null,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        surfaceTintColor: isDynamic
            ? colorScheme.onSurfaceVariant
            : isDark
                ? colorScheme.onSurfaceVariant
                : null,
        shadowColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        // ignore: deprecated_member_use
        year2023: false,
        refreshBackgroundColor: colorScheme.onSecondary,
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: TextStyle(
          fontSize: 18,
          color: colorScheme.onSurface,
          fontWeight: fontWeight,
        ),
        backgroundColor: colorScheme.surface,
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: StyleString.bottomSheetRadius,
        ),
      ),
      // ignore: deprecated_member_use
      sliderTheme: const SliderThemeData(year2023: false),
      tooltipTheme: TooltipThemeData(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[700]!.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        selectionHandleColor: colorScheme.primary,
      ),
      switchTheme: const SwitchThemeData(
        padding: .zero,
        materialTapTargetSize: .shrinkWrap,
        thumbIcon: WidgetStateProperty<Icon?>.fromMap(
          <WidgetStatesConstraint, Icon?>{
            WidgetState.selected: Icon(Icons.done),
            WidgetState.any: null,
          },
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
    if (isDark) {
      if (Pref.isPureBlackTheme) {
        themeData = darkenTheme(themeData);
      }
      if (Pref.darkVideoPage) {
        MyApp.darkThemeData = themeData;
      }
    }
    return themeData;
  }

  static ThemeData darkenTheme(ThemeData themeData) {
    final colorScheme = themeData.colorScheme;
    final color = colorScheme.surfaceContainerHighest.darken(0.7);

    // 获取字体回退设置
    final fontFamilyFallback = Pref.useSystemFont ? null : ['HarmonyOS_Sans'];

    return themeData.copyWith(
      scaffoldBackgroundColor: Colors.black,
      textTheme: themeData.textTheme.copyWith(
        bodyLarge: themeData.textTheme.bodyLarge
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        bodyMedium: themeData.textTheme.bodyMedium
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        bodySmall: themeData.textTheme.bodySmall
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        displayLarge: themeData.textTheme.displayLarge
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        displayMedium: themeData.textTheme.displayMedium
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        displaySmall: themeData.textTheme.displaySmall
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        headlineLarge: themeData.textTheme.headlineLarge
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        headlineMedium: themeData.textTheme.headlineMedium
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        headlineSmall: themeData.textTheme.headlineSmall
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        titleLarge: themeData.textTheme.titleLarge
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        titleMedium: themeData.textTheme.titleMedium
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        titleSmall: themeData.textTheme.titleSmall
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        labelLarge: themeData.textTheme.labelLarge
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        labelMedium: themeData.textTheme.labelMedium
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
        labelSmall: themeData.textTheme.labelSmall
            ?.copyWith(fontFamilyFallback: fontFamilyFallback),
      ),
      appBarTheme: themeData.appBarTheme.copyWith(
        backgroundColor: Colors.black,
      ),
      cardTheme: themeData.cardTheme.copyWith(
        color: Colors.black,
      ),
      dialogTheme: themeData.dialogTheme.copyWith(
        backgroundColor: color,
      ),
      bottomSheetTheme: themeData.bottomSheetTheme.copyWith(
        backgroundColor: color,
      ),
      bottomNavigationBarTheme: themeData.bottomNavigationBarTheme.copyWith(
        backgroundColor: color,
      ),
      navigationBarTheme: themeData.navigationBarTheme.copyWith(
        backgroundColor: color,
      ),
      navigationRailTheme: themeData.navigationRailTheme.copyWith(
        backgroundColor: Colors.black,
      ),
      colorScheme: colorScheme.copyWith(
        primary: colorScheme.primary.darken(0.1),
        onPrimary: colorScheme.onPrimary.darken(0.1),
        primaryContainer: colorScheme.primaryContainer.darken(0.1),
        onPrimaryContainer: colorScheme.onPrimaryContainer.darken(0.1),
        inversePrimary: colorScheme.inversePrimary.darken(0.1),
        secondary: colorScheme.secondary.darken(0.1),
        onSecondary: colorScheme.onSecondary.darken(0.1),
        secondaryContainer: colorScheme.secondaryContainer.darken(0.1),
        onSecondaryContainer: colorScheme.onSecondaryContainer.darken(0.1),
        error: colorScheme.error.darken(0.1),
        surface: Colors.black,
        onSurface: colorScheme.onSurface.darken(0.15),
        surfaceTint: colorScheme.surfaceTint.darken(),
        inverseSurface: colorScheme.inverseSurface.darken(),
        onInverseSurface: colorScheme.onInverseSurface.darken(),
        surfaceContainer: colorScheme.surfaceContainer.darken(),
        surfaceContainerHigh: colorScheme.surfaceContainerHigh.darken(),
        surfaceContainerHighest: colorScheme.surfaceContainerHighest.darken(
          0.4,
        ),
      ),
    );
  }
}
