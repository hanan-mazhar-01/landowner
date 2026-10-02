import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Material is only used as a host; every visible component is custom.
abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.overdueText,
      onError: AppColors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.transparent,
      hoverColor: AppColors.blue50,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.blue150,
        selectionHandleColor: AppColors.accent,
      ),
      textTheme: TextTheme(bodyMedium: AppType.body.copyWith(color: AppColors.ink)),
      cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: AppColors.accent),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        headerBackgroundColor: AppColors.blue600,
        headerForegroundColor: AppColors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
