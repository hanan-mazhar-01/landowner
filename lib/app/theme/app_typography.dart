import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Type system: Manrope for numbers, names and headings; the platform system
/// font (SF Pro on iOS) for body, controls and metadata.
abstract final class AppType {
  static const display = 'Manrope';

  static TextStyle _m(double size, FontWeight w, [double ls = 0, double? h]) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        height: h,
        color: AppColors.ink,
      );

  static TextStyle _b(double size, FontWeight w, [Color c = AppColors.ink, double? h]) =>
      TextStyle(fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: 0);

  // Display numbers.
  static final hero = _m(58, FontWeight.w800, -2.6, 1);
  static final heroUnit = _m(26, FontWeight.w700).copyWith(color: AppColors.textFaint);
  static final value44 = _m(44, FontWeight.w800, -1.8, 1);
  static final value40 = _m(40, FontWeight.w800, -1.6, 1);
  static final stat36 = _m(36, FontWeight.w800, -1.4, 1);

  // Headings.
  static final welcome = _m(36, FontWeight.w800, -1.4, 1.08);
  static final pageTitle = _m(32, FontWeight.w800, -1.2);
  static final detailTitle = _m(32, FontWeight.w800, -1, 1.08);
  static final title30 = _m(30, FontWeight.w800, -1, 1.1);
  static final title28 = _m(28, FontWeight.w800, -1, 1.1);
  static final title26 = _m(26, FontWeight.w800, -.8);
  static final greeting = _m(25, FontWeight.w800, -.8);
  static final title22 = _m(22, FontWeight.w800, -.5);
  static final section = _m(20, FontWeight.w800, -.4);
  static final section18 = _m(18, FontWeight.w800, -.3);
  static final cardTitle = _m(17, FontWeight.w800);
  static final brand = _m(20, FontWeight.w800, -.5);

  // Numbers & labels in Manrope.
  static TextStyle num(double size, [FontWeight w = FontWeight.w800, double ls = 0]) =>
      _m(size, w, ls);
  static final button = _m(17, FontWeight.w700);
  static final buttonSm = _m(16, FontWeight.w700);
  static final button15 = _m(15, FontWeight.w700);
  static final overline = _m(11, FontWeight.w700, 1.4).copyWith(color: AppColors.textMuted);

  // Body (system font).
  static final input = _b(16, FontWeight.w400);
  static final rowTitle = _b(15, FontWeight.w600);
  static final menuItem = _b(15, FontWeight.w500);
  static final body15 = _b(15, FontWeight.w400, AppColors.textMuted, 1.5);
  static final body = _b(14, FontWeight.w400, AppColors.textMuted, 1.5);
  static final label14 = _b(14, FontWeight.w600);
  static final meta = _b(13, FontWeight.w400, AppColors.textMuted);
  static final label13 = _b(13, FontWeight.w600, AppColors.textMuted);
  static final caption = _b(12, FontWeight.w400, AppColors.textMuted);
  static final caption12Bold = _b(12, FontWeight.w700);
  static final micro = _b(11, FontWeight.w400, AppColors.textMuted);
  static final micro11Bold = _b(11, FontWeight.w700);
  static final axis = _b(10, FontWeight.w400, AppColors.textFaint);
  static final navLabel = _b(10, FontWeight.w700);
}
