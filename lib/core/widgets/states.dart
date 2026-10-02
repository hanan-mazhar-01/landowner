import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_decor.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_typography.dart';
import '../icons/homely_icon.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Empty state card — "Nothing here yet" pattern from the Portfolio screen.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = HomelyIcons.emptyBuilding,
    this.actionLabel,
    this.onAction,
    this.tone = Tone.info,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
  });

  final String title;
  final String message;
  final HomelyIcons icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Tone tone;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: margin,
        radius: AppRadius.hero,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              size: 52,
              radius: 18,
              color: tone.tint,
              child: HomelyIcon(icon, size: 24, color: tone.fg, strokeWidth: 1.8),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppType.section),
            const SizedBox(height: 10),
            Text(message, style: AppType.body),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              // Own semantics node so screen readers can focus and activate
              // the action separately from the card's title and message.
              Semantics(
                container: true,
                button: true,
                label: actionLabel,
                excludeSemantics: true,
                onTap: onAction,
                child: SolidButton(label: actionLabel!, onTap: onAction),
              ),
            ],
          ],
        ),
      );
}

/// Error state — same card language, overdue tone, Retry.
class ErrorStateCard extends StatelessWidget {
  const ErrorStateCard({super.key, this.message = 'Something went wrong loading this.', this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyStateCard(
        title: 'Couldn’t load',
        message: message,
        icon: HomelyIcons.alert,
        tone: Tone.bad,
        actionLabel: onRetry == null ? null : 'Try again',
        onAction: onRetry,
      );
}

/// Soft shimmering placeholder block for loading states.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 80, this.width, this.radius = AppRadius.card});
  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) _c.stop();
    return FadeTransition(
      opacity: Tween(begin: .55, end: 1.0).animate(_c),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.imagePlaceholder,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Screen-level loading skeleton shaped like a dashboard.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 24, 16, 0),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 28, width: 220, radius: 10),
            SizedBox(height: 28),
            SkeletonBox(height: 58, width: 260, radius: 14),
            SizedBox(height: 24),
            SkeletonBox(height: 170),
            SizedBox(height: 16),
            SkeletonBox(height: 190, radius: AppRadius.hero),
            SizedBox(height: 16),
            SkeletonBox(height: 220),
          ],
        ),
      );
}
