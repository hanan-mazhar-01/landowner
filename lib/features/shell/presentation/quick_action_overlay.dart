import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_motion.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/widgets/pressable.dart';
import 'quick_actions_controller.dart';

/// Blurred scrim with four primary actions fanning out on an arc above the
/// + button and a glass grid of secondary actions. Angles (152°, 111°, 69°,
/// 28°), radius (128) and staggers come straight from the design.
class QuickActionOverlay extends ConsumerStatefulWidget {
  const QuickActionOverlay({super.key, required this.onAction, required this.navBottom});

  final ValueChanged<QuickAction> onAction;

  /// Distance from the screen bottom to the nav bar's bottom edge.
  final double navBottom;

  @override
  ConsumerState<QuickActionOverlay> createState() => _QuickActionOverlayState();
}

class _QuickActionOverlayState extends ConsumerState<QuickActionOverlay> with SingleTickerProviderStateMixin {
  static const _total = 540.0;
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 540));
  static const _angles = [152.0, 111.0, 69.0, 28.0];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _interval(double startMs, double durMs, Curve curve) => CurvedAnimation(
        parent: _c,
        curve: Interval(startMs / _total, math.min(1, (startMs + durMs) / _total), curve: curve),
      );

  void _pick(QuickAction a) {
    ref.read(quickActionsProvider.notifier).close();
    Future.delayed(Motion.of(context, const Duration(milliseconds: 180)), () => widget.onAction(a));
  }

  @override
  Widget build(BuildContext context) {
    final open = ref.watch(quickActionsProvider);
    _c.duration = Motion.of(context, const Duration(milliseconds: 540));
    open ? _c.forward() : _c.reverse();
    final scrim = _interval(0, 240, Curves.ease);
    final bottom = widget.navBottom;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        if (_c.value == 0) return const SizedBox.shrink();
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: ref.read(quickActionsProvider.notifier).close,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8 * scrim.value, sigmaY: 8 * scrim.value),
                child: ColoredBox(color: AppColors.scrim.withValues(alpha: .42 * scrim.value)),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottom + 292,
            child: Opacity(opacity: _interval(60, 280, Curves.ease).value, child: _secondary()),
          ),
          for (var i = 0; i < 4; i++) _arcItem(i, bottom),
        ]);
      },
    );
  }

  Widget _secondary() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add to your portfolio', style: AppType.title26.copyWith(color: AppColors.white)),
          const SizedBox(height: 3),
          Text('Everything you add links to a property.',
              style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: .8))),
          const SizedBox(height: 14),
          Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _gridTile(QuickAction.secondary[i], i)),
            ],
          ]),
        ],
      );

  Widget _gridTile(QuickAction a, int i) {
    final t = _interval(120 + i * 30.0, 320, AppMotion.flyOut).value;
    return Transform.translate(
      offset: Offset(0, 16 * (1 - t)),
      child: Pressable(
        onTap: () => _pick(a),
        scale: .96,
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.tileGlass,
            borderRadius: BorderRadius.circular(AppRadius.cta),
            border: Border.all(color: AppColors.tileGlassBorder),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            HomelyIcon(a.icon, size: 20, color: AppColors.white, strokeWidth: 1.9),
            const SizedBox(height: 7),
            FittedBox(
              child: Text(a.label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
            ),
          ]),
        ),
      ),
    );
  }

  /// Each arc item is laid out at its real position (not visually translated),
  /// so its hit area moves with it and taps land on the button.
  Widget _arcItem(int i, double bottom) {
    const itemWidth = 72.0;
    final t = _interval(i * 32.0, 380, AppMotion.flyOut).value;
    final a = _angles[i] * math.pi / 180;
    final dx = math.cos(a) * 128 * t, rise = (math.sin(a) * 128 + 26) * t;
    final act = QuickAction.primary[i];
    final centerX = MediaQuery.sizeOf(context).width / 2;
    return Positioned(
      left: centerX - itemWidth / 2 + dx,
      bottom: bottom + 8 + rise,
      width: itemWidth,
      child: Opacity(
        opacity: _interval(0, 220, Curves.ease).value,
        child: Transform.scale(
          scale: .3 + .7 * t,
          child: Pressable(
            onTap: () => _pick(act),
            scale: .94,
            semanticLabel: 'Add ${act.label.toLowerCase()}',
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: AppShadows.quickAction),
                child: Center(child: HomelyIcon(act.icon, size: 24, color: AppColors.primary, strokeWidth: 1.9)),
              ),
              const SizedBox(height: 6),
              Text(act.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white)),
            ]),
          ),
        ),
      ),
    );
  }
}
