import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_decor.dart';
import '../icons/homely_icon.dart';

/// Small coloured dot (6×6).
class Dot extends StatelessWidget {
  const Dot(this.color, {super.key, this.size = 6});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// Tinted pill — "Paid", "+12.4%", "Overdue · 3 days".
class TonePill extends StatelessWidget {
  const TonePill({
    super.key,
    required this.label,
    required this.fg,
    required this.bg,
    this.dot,
    this.icon,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  factory TonePill.tone(String label, Tone t, {bool dot = false, double fontSize = 12}) =>
      TonePill(label: label, fg: t.fg, bg: t.tint, dot: dot ? t.dot : null, fontSize: fontSize);

  final String label;
  final Color fg, bg;
  final Color? dot;
  final HomelyIcons? icon;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot != null) ...[Dot(dot!), const SizedBox(width: 6)],
          if (icon != null) ...[HomelyIcon(icon!, size: 13, color: fg, strokeWidth: 2.4), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: fg)),
        ]),
      );
}

/// Status pill that floats over photography (white .88, coloured dot + text).
class PhotoStatusPill extends StatelessWidget {
  const PhotoStatusPill({super.key, required this.label, required this.color, this.strong = false});
  final String label;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: strong ? 5 : 6),
        decoration: BoxDecoration(
          color: strong ? AppColors.pillOnPhotoStrong : AppColors.pillOnPhoto,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Dot(color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

/// Frosted label over photos ("1 / 3 photos", "HIGHEST YIELD").
class GlassLabel extends StatelessWidget {
  const GlassLabel({super.key, required this.child, this.dark = false, this.height, this.padding});
  final Widget child;
  final bool dark;
  final double? height;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: dark ? 8 : 12, sigmaY: dark ? 8 : 12),
          child: Container(
            height: height,
            alignment: height == null ? null : Alignment.center,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            color: dark ? AppColors.inkBadge : AppColors.glassFill,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700),
              child: child,
            ),
          ),
        ),
      );
}

/// Red count badge ("Needs your attention  4").
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 22),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.overdue, borderRadius: BorderRadius.circular(11)),
        child: Text('$count',
            style: const TextStyle(
                fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white)),
      );
}
