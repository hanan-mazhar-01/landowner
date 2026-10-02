import 'package:flutter/painting.dart';

/// Every colour used by HOMELY, taken 1:1 from `Homely Redesign.dc.html`.
///
/// Do not add colours here that do not exist in the design file.
abstract final class AppColors {
  // Blue ramp.
  static const blue700 = Color(0xFF23389F);
  static const blue600 = Color(0xFF304BC7); // primary
  static const blue500 = Color(0xFF3F5DE8);
  static const blue400 = Color(0xFF4D6DFA); // accent
  static const blue300 = Color(0xFF9EAEFF);
  static const blue200 = Color(0xFFC9D3FF);
  static const blue150 = Color(0xFFDCE3FF);
  static const blue100 = Color(0xFFE7EBFF);
  static const blue50 = Color(0xFFF1F3FF);
  static const blue25 = Color(0xFFF7F9FF);

  static const primary = blue600;
  static const accent = blue400;

  // Ink & text.
  static const ink = Color(0xFF111830);
  static const inkDeep = Color(0xFF0B0F1F);
  static const textSecondary = Color(0xFF4A5170);
  static const textMuted = Color(0xFF6B7186);
  static const textFaint = Color(0xFF9AA0B4);
  static const chevron = Color(0xFFC0C6D8);
  static const navOffInk = Color(0xFF7F88AD);

  // Surfaces & lines.
  static const background = Color(0xFFF3F6FE);
  static const canvas = Color(0xFFE6EBF8);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDE3F3);
  static const divider = Color(0xFFE4E8F4);
  static const dividerSoft = Color(0xFFEEF1F8);
  static const neutralTint = Color(0xFFEEF1F8);
  static const imagePlaceholder = Color(0xFFDFE5F5);
  static const mapGround = Color(0xFFE3E9F8);
  static const mapGrid = Color(0xFFD3DCF2);
  static const dotInactive = Color(0xFFC9D3F5);

  // Status.
  static const positive = Color(0xFF2FB673);
  static const positiveText = Color(0xFF1B8A55);
  static const positiveTint = Color(0xFFE3F5EC);
  static const attention = Color(0xFFF2A93B);
  static const attentionText = Color(0xFFB7741A);
  static const attentionTint = Color(0xFFFDF1DC);
  static const overdue = Color(0xFFE5484D);
  static const overdueText = Color(0xFFD23B40);
  static const overdueTint = Color(0xFFFCE7E8);

  // Translucent layers.
  static const white = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);
  static const scrim = Color(0x6B111830); // rgba(17,24,48,.42)
  static const glassFill = Color(0x38FFFFFF); // white .22
  static const glassBorder = Color(0x4DFFFFFF); // white .30
  static const tileGlass = Color(0x24FFFFFF); // white .14
  static const tileGlassBorder = Color(0x38FFFFFF); // white .22
  static const onBlueDivider = Color(0x29FFFFFF); // white .16
  static const navLight = Color(0xF0FFFFFF); // white .94
  static const readRow = Color(0x8CFFFFFF); // white .55
  static const pillOnPhoto = Color(0xE0FFFFFF); // white .88
  static const pillOnPhotoStrong = Color(0xE6FFFFFF); // white .90
  static const priceTag = Color(0xEBFFFFFF); // white .92
  static const inkBadge = Color(0x8C111830); // rgba(17,24,48,.55)

  /// Disabled content — built from existing tokens (design defines none).
  static const disabledTrack = border;
  static const disabledText = textFaint;
}

/// Semantic tone pairs used by pills, icon tiles and attention rows
/// (`TONE` in the design).
enum Tone {
  ok(AppColors.positiveText, AppColors.positiveTint, AppColors.positive),
  bad(AppColors.overdueText, AppColors.overdueTint, AppColors.overdue),
  warn(AppColors.attentionText, AppColors.attentionTint, AppColors.attention),
  info(AppColors.blue600, AppColors.blue100, AppColors.blue400),
  neutral(AppColors.textSecondary, AppColors.neutralTint, AppColors.textMuted);

  const Tone(this.fg, this.tint, this.dot);
  final Color fg;
  final Color tint;
  final Color dot;
}
