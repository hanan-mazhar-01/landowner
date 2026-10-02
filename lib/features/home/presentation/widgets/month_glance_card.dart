import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/stagger.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../../finance/domain/finance_analytics.dart';

/// "September at a glance" — income, expenses, net, split bar, and an
/// occupancy strip (one block per unit, at most [maxBlocks]).
///
/// Entrance: header slides in, figures fade up and count from zero, the split
/// bar and divider draw from the left, then the unit blocks pop in one by one
/// and fill.
class MonthGlanceCard extends StatelessWidget {
  const MonthGlanceCard({
    super.key,
    required this.month,
    required this.totals,
    required this.properties,
    required this.units,
    required this.occupied,
    this.onTap,
  });

  final DateTime month;
  final MonthTotals totals;
  final int properties, units, occupied;
  final VoidCallback? onTap;

  /// Beyond this many units each block stands for a share of the portfolio.
  static const maxBlocks = 10;

  static const _ms = Duration(milliseconds: 1);

  /// (blocks shown, blocks filled). Up to [maxBlocks] units map 1:1; above
  /// that the strip shows the occupancy ratio, never rounding a partly
  /// occupied portfolio to fully empty or fully occupied.
  static (int, int) blocksFor(int units, int occupied) {
    if (units <= maxBlocks) return (units, occupied.clamp(0, units));
    var filled = (occupied / units * maxBlocks).round();
    if (occupied > 0) filled = filled.clamp(1, maxBlocks);
    if (occupied < units) filled = filled.clamp(0, maxBlocks - 1);
    return (maxBlocks, filled);
  }

  @override
  Widget build(BuildContext context) {
    final soft = TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: .7));
    final net = totals.net.clamp(0, 1 << 31);
    final (blocks, filled) = blocksFor(units, occupied);
    String money(num v) => Money.compact(v);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
      child: GradientCard(
        onTap: onTap,
        radius: AppRadius.hero,
        gradient: AppGradients.hero,
        shadow: AppShadows.heroCard,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredEntrance(
              from: const Offset(-14, 0),
              child: Row(
                children: [
                  Text(
                    '${Dates.month(month)} at a glance',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: .85),
                    ),
                  ),
                  const Spacer(),
                  HomelyIcon(HomelyIcons.chevronRight, size: 18, color: AppColors.white.withValues(alpha: .7)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 10, child: _fig('Income', totals.income, money, soft, 19, delay: _ms * 90)),
                const SizedBox(width: 8),
                Expanded(flex: 10, child: _fig('Expenses', totals.expense, money, soft, 19, delay: _ms * 170)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 12,
                  child: _fig('Net cash flow', totals.net, money, soft, 25, big: true, delay: _ms * 250),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GrowIn(
              delay: _ms * 320,
              duration: _ms * 800,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(
                        flex: net == 0 ? 1 : net,
                        child: const ColoredBox(color: AppColors.white),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        flex: totals.expense == 0 ? 1 : totals.expense,
                        child: ColoredBox(color: AppColors.white.withValues(alpha: .3)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 16),
              child: GrowIn(
                delay: _ms * 420,
                child: const Hairline(color: AppColors.onBlueDivider),
              ),
            ),
            Row(
              children: [
                StaggeredEntrance(
                  delay: _ms * 480,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CountUpText(
                        value: properties,
                        format: (v) => '${v.round()}',
                        delay: _ms * 480,
                        duration: _ms * 700,
                        style: AppType.num(22).copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: 3),
                      Text(properties == 1 ? 'Property' : 'Properties', style: soft),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < blocks; i++) ...[
                          if (i > 0) const SizedBox(width: 3),
                          _UnitBlock(occupied: i < filled, delay: _ms * (560 + 55 * i)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    StaggeredEntrance(
                      delay: _ms * 600,
                      from: const Offset(8, 0),
                      child: Text(
                        units == 0 ? 'No units added' : '$occupied of $units units occupied',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: .8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fig(
    String label,
    num value,
    String Function(num) format,
    TextStyle soft,
    double size, {
    bool big = false,
    Duration delay = Duration.zero,
  }) => StaggeredEntrance(
    delay: delay,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: soft, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: CountUpText(
            value: value,
            format: format,
            delay: delay,
            maxLines: 1,
            style: AppType.num(
              size,
              big ? FontWeight.w800 : FontWeight.w700,
              big ? -.6 : 0,
            ).copyWith(color: AppColors.white),
          ),
        ),
      ],
    ),
  );
}

/// One occupancy block: pops in, then occupied blocks fill to white.
class _UnitBlock extends StatelessWidget {
  const _UnitBlock({required this.occupied, required this.delay});
  final bool occupied;
  final Duration delay;

  static const _empty = .22;

  @override
  Widget build(BuildContext context) {
    final fillDelay = delay + const Duration(milliseconds: 220);
    final total = Motion.of(context, fillDelay + const Duration(milliseconds: 420));
    return StaggeredEntrance(
      delay: delay,
      duration: const Duration(milliseconds: 420),
      from: const Offset(0, 6),
      scale: .3,
      curve: Curves.easeOutBack,
      alignment: Alignment.bottomCenter,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: _empty, end: occupied ? 1 : _empty),
        duration: total,
        curve: total == Duration.zero
            ? Curves.linear
            : Interval(fillDelay.inMilliseconds / total.inMilliseconds, 1, curve: Curves.easeOut),
        builder: (_, a, _) => Container(
          width: 12,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: a),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
