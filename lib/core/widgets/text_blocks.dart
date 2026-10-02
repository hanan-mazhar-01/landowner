import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_typography.dart';

/// Section heading row — 20/800 Manrope with an optional trailing widget.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(24, 34, 24, 12),
    this.style,
    this.badge,
  });

  final String title;
  final Widget? trailing;
  final Widget? badge;
  final EdgeInsets padding;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(children: [
                Flexible(child: Text(title, style: style ?? AppType.section)),
                if (badge != null) ...[const SizedBox(width: 8), badge!],
              ]),
            ),
            ?trailing,
          ],
        ),
      );
}

/// Spaced uppercase overline — `11/700 Manrope, letter-spacing 1.4`.
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(24, 26, 24, 10)});
  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: padding, child: Text(text.toUpperCase(), style: AppType.overline));
}

/// Large page title with optional subtitle (Portfolio, Finance, More…).
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.subtitle, this.style});
  final String title;
  final String? subtitle;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: style ?? AppType.pageTitle),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppType.meta.copyWith(fontSize: 14)),
          ],
        ],
      );
}

/// Label above a Manrope figure ("Monthly rent / Rs120K").
class LabeledValue extends StatelessWidget {
  const LabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.labelStyle,
    this.gap = 4,
    this.end = false,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final double gap;
  final bool end;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle ?? AppType.caption),
          SizedBox(height: gap),
          Text(value, style: valueStyle ?? AppType.num(21), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      );
}

/// Hero figure: small grey "Rs" + 58px number + small unit ("M" / "K").
/// The number counts up over 900ms (ease-out cubic) as in the design.
class MoneyHero extends StatelessWidget {
  const MoneyHero({super.key, required this.value, required this.unit, this.decimals = 1, this.symbol = 'Rs'});
  final double value;
  final String unit;
  final int decimals;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final unitStyle = AppType.heroUnit;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(symbol, style: unitStyle)),
          const SizedBox(width: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: Motion.of(context, AppMotion.counter),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(v.toStringAsFixed(decimals), style: AppType.hero),
          ),
          const SizedBox(width: 4),
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(unit, style: unitStyle)),
        ],
      ),
    );
  }
}

/// Muted metadata line with ellipsis.
class MetaText extends StatelessWidget {
  const MetaText(this.text, {super.key, this.size = 13, this.color = AppColors.textMuted, this.maxLines = 1});
  final String text;
  final double size;
  final Color color;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Text(text,
      maxLines: maxLines, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: size, color: color));
}
