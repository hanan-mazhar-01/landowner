import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/stagger.dart';
import '../../../../core/widgets/charts/rings.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../domain/finance_analytics.dart';
import '../../domain/ledger_entry.dart';
import '../finance_providers.dart';

/// "What changed" — horizontally snapping stat cards (first one blue).
class InsightCarousel extends StatelessWidget {
  const InsightCarousel({super.key, required this.items});
  final List<FinanceInsight> items;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 190,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) {
        final it = items[i];
        final fg = it.primary ? AppColors.white : AppColors.ink;
        return Container(
          width: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: it.primary ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.stat, style: AppType.stat36.copyWith(color: fg)),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  it.text,
                  overflow: TextOverflow.fade,
                  style: TextStyle(fontSize: 14, height: 1.45, color: fg),
                ),
              ),
              const SizedBox(height: 6),
              Text(it.source, style: TextStyle(fontSize: 11, color: fg.withValues(alpha: .65))),
            ],
          ),
        );
      },
    ),
  );
}

/// Expense breakdown card with header, category icon badges, and interlocking donut chart.
class ExpenseDonutCard extends StatelessWidget {
  const ExpenseDonutCard({
    super.key,
    required this.shares,
    this.title,
    this.onTap,
    this.margin = const EdgeInsets.fromLTRB(16, 22, 16, 0),
  });

  final List<CategoryShare> shares;
  final String? title;
  final VoidCallback? onTap;
  final EdgeInsets margin;

  static const _palette = [
    (color: Color(0xFF3858F6), iconColor: Color(0xFFFFFFFF)), // Vivid Blue
    (color: Color(0xFF374151), iconColor: Color(0xFFFFFFFF)), // Dark Grey (replaces green as requested)
    (color: Color(0xFF111830), iconColor: Color(0xFFFFFFFF)), // Obsidian Deep Navy
    (color: Color(0xFFBAC7FF), iconColor: Color(0xFF23389F)), // Soft Blue Tint
  ];

  static HomelyIcons _categoryIcon(ExpenseCategory cat) => switch (cat) {
    ExpenseCategory.maintenance => HomelyIcons.wrench,
    ExpenseCategory.utilities => HomelyIcons.sparkle,
    ExpenseCategory.tax => HomelyIcons.home,
    ExpenseCategory.repairs => HomelyIcons.shield,
    ExpenseCategory.insurance => HomelyIcons.shield,
    ExpenseCategory.management => HomelyIcons.users,
    ExpenseCategory.renovation => HomelyIcons.wrench,
    ExpenseCategory.mortgage => HomelyIcons.coin,
    ExpenseCategory.other => HomelyIcons.shield,
  };

  @override
  Widget build(BuildContext context) {
    final total = shares.fold<int>(0, (s, c) => s + c.amount);
    final top = shares.take(3).toList();
    final restAmount = shares.skip(3).fold<int>(0, (s, c) => s + c.amount);
    final restShare = shares.skip(3).fold<double>(0, (s, c) => s + c.share);

    final rows = <({String label, int amount, double share, HomelyIcons icon, Color color, Color iconColor})>[];
    if (shares.length <= 4) {
      for (var i = 0; i < shares.length; i++) {
        final s = shares[i];
        final p = _palette[i % _palette.length];
        rows.add((
          label: s.category.label == 'Tax' ? 'Property tax' : s.category.label,
          amount: s.amount,
          share: s.share,
          icon: _categoryIcon(s.category),
          color: p.color,
          iconColor: p.iconColor,
        ));
      }
    } else {
      for (var i = 0; i < top.length; i++) {
        final s = top[i];
        final p = _palette[i % _palette.length];
        rows.add((
          label: s.category.label == 'Tax' ? 'Property tax' : s.category.label,
          amount: s.amount,
          share: s.share,
          icon: _categoryIcon(s.category),
          color: p.color,
          iconColor: p.iconColor,
        ));
      }
      final p = _palette[3];
      rows.add((
        label: 'Other',
        amount: restAmount,
        share: restShare,
        icon: HomelyIcons.shield,
        color: p.color,
        iconColor: p.iconColor,
      ));
    }

    return SurfaceCard(
      margin: margin,
      radius: AppRadius.card,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      shadow: AppShadows.card,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                StaggeredEntrance(
                  scale: .4,
                  from: Offset.zero,
                  curve: Curves.easeOutBack,
                  duration: const Duration(milliseconds: 480),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFE8EEFF), borderRadius: BorderRadius.circular(10)),
                    child: const Center(
                      child: HomelyIcon(HomelyIcons.wallet, size: 20, color: AppColors.primary, strokeWidth: 2.0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StaggeredEntrance(
                    delay: const Duration(milliseconds: 80),
                    from: const Offset(-10, 0),
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const HomelyIcon(HomelyIcons.chevronRight, size: 18, color: AppColors.chevron, strokeWidth: 2.2),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InterlockingDonutChart(
                size: 148,
                shares: rows.map((r) => r.share).toList(),
                colors: rows.map((r) => r.color).toList(),
                showLabels: false,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountUpText(
                      value: total,
                      format: Money.compact,
                      delay: const Duration(milliseconds: 250),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Text(
                      'total expenses',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      StaggeredEntrance(
                        delay: Duration(milliseconds: 260 + 110 * i),
                        from: const Offset(18, 0),
                        child: Row(
                          children: [
                            StaggeredEntrance(
                              delay: Duration(milliseconds: 300 + 110 * i),
                              from: Offset.zero,
                              scale: .2,
                              curve: Curves.easeOutBack,
                              duration: const Duration(milliseconds: 460),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(color: rows[i].color, shape: BoxShape.circle),
                                child: Center(
                                  child: HomelyIcon(rows[i].icon, size: 14, color: rows[i].iconColor, strokeWidth: 2.0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    rows[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  CountUpText(
                                    value: rows[i].amount,
                                    format: Money.k,
                                    delay: Duration(milliseconds: 260 + 110 * i),
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CountUpText(
                              value: (rows[i].share * 100).round(),
                              format: (v) => '${v.round()}%',
                              delay: Duration(milliseconds: 260 + 110 * i),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No expenses this month',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
