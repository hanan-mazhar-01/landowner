import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_decor.dart';
import '../../app/theme/app_typography.dart';
import '../icons/homely_icon.dart';
import 'pressable.dart';

/// Primary CTA — gradient, label flush left, arrow right.
class GradientCta extends StatelessWidget {
  const GradientCta({
    super.key,
    required this.label,
    this.onTap,
    this.trailing,
    this.height = 56,
    this.radius = AppRadius.cta,
    this.style,
    this.shadow,
    this.padding = 20,
    this.centered = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double height;
  final double radius;
  final TextStyle? style;
  final List<BoxShadow>? shadow;
  final double padding;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      haptic: true,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: padding),
          decoration: BoxDecoration(
            gradient: AppGradients.cta,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: shadow ?? AppShadows.ctaForm,
          ),
          child: Row(
            mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [
              // Scales down on narrow screens / half-width buttons instead of overflowing.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(label, maxLines: 1, style: (style ?? AppType.buttonSm).copyWith(color: AppColors.white)),
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? const HomelyIcon(HomelyIcons.arrowRight, color: AppColors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Solid / tinted pill button used inside cards ("Add a property", "Upgrade").
class SolidButton extends StatelessWidget {
  const SolidButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 46,
    this.radius = AppRadius.input,
    this.color = AppColors.accent,
    this.foreground = AppColors.white,
    this.fontSize = 15,
    this.padding = 18,
    this.border,
  });

  final String label;
  final VoidCallback? onTap;
  final double height, radius, fontSize, padding;
  final Color color, foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: padding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: Text(label,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: foreground)),
        ),
      );
}

/// 44px round icon button — white (default) or frosted glass over photos.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.glass = false,
    this.size = 44,
    this.iconSize = 20,
    this.strokeWidth = 2.2,
    this.color = AppColors.surface,
    this.iconColor,
    this.semanticLabel,
    this.badge = false,
    this.shadow,
  });

  final HomelyIcons icon;
  final VoidCallback? onTap;
  final bool glass;
  final double size, iconSize, strokeWidth;
  final Color color;
  final Color? iconColor;
  final String? semanticLabel;
  final bool badge;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final fg = iconColor ?? (glass ? AppColors.white : AppColors.ink);
    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glass ? AppColors.glassFill : color,
        border: glass ? Border.all(color: AppColors.glassBorder) : null,
        boxShadow: shadow,
      ),
      child: HomelyIcon(icon, size: iconSize, color: fg, strokeWidth: strokeWidth),
    );
    if (glass) {
      circle = ClipOval(
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: circle),
      );
    }
    if (badge) {
      circle = Stack(children: [
        circle,
        Positioned(
          top: 11,
          right: 12,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.overdue,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
          ),
        ),
      ]);
    }
    return Pressable(onTap: onTap, scale: .94, semanticLabel: semanticLabel, child: circle);
  }
}

/// Text link in primary blue ("View all", "Mark all read").
class LinkText extends StatelessWidget {
  const LinkText(this.label, {super.key, this.onTap, this.color = AppColors.primary, this.size = 14});
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: .96,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: color)),
        ),
      );
}
