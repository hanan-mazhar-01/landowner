import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_decor.dart';
import 'pressable.dart';

/// White rounded surface — the design's primary card.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.card,
    this.color = AppColors.surface,
    this.shadow,
    this.onTap,
    this.pressScale = .99,
    this.margin,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final double pressScale;
  final EdgeInsetsGeometry? margin;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    Widget box = Container(
      margin: margin,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: child,
    );
    if (onTap != null) box = Pressable(onTap: onTap, scale: pressScale, child: box);
    return box;
  }
}

/// Blue hero card (`linear-gradient(160deg,#3F5DE8,#304BC7,#23389F)`).
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = AppRadius.card,
    this.shadow,
    this.onTap,
    this.gradient = AppGradients.heroAlt,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    Widget box = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: DefaultTextStyle.merge(style: const TextStyle(color: AppColors.white), child: child),
    );
    if (onTap != null) box = Pressable(onTap: onTap, scale: .99, child: box);
    return box;
  }
}

/// 1px hairline used between rows (`#E4E8F4` / `#EEF1F8`).
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.color = AppColors.divider, this.vertical = false});
  final Color color;
  final bool vertical;

  @override
  Widget build(BuildContext context) =>
      vertical ? Container(width: 1, color: color) : Container(height: 1, color: color);
}

/// Rounded square icon container (`40×40`, radius 14).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.child,
    required this.color,
    this.size = 40,
    this.radius = AppRadius.iconTile,
  });

  final Widget child;
  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
        child: child,
      );
}
