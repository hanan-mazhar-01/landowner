import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/charts/bars.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../domain/finance_analytics.dart';

/// Income vs expense chart with a tappable selection and range totals.
class CashFlowCard extends StatelessWidget {
  const CashFlowCard({
    super.key,
    required this.series,
    required this.range,
    required this.selected,
    required this.onSelect,
    required this.monthName,
  });

  final CashSeries series;
  final FinanceRange range;
  final int selected;
  final ValueChanged<int> onSelect;
  final String monthName;

  @override
  Widget build(BuildContext context) {
    final i = selected.clamp(0, series.length - 1);
    final label = series.fullLabels[i] + (range == FinanceRange.m1 ? ' · $monthName' : '');
    final net = series.income[i] - series.expense[i];
    Widget legend(Color c, String v) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(v, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]);

    return SurfaceCard(
      margin: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      radius: AppRadius.hero,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppType.caption),
              const SizedBox(height: 2),
              Text.rich(TextSpan(children: [
                TextSpan(text: Money.compact(net), style: AppType.num(18)),
                TextSpan(text: ' net', style: AppType.num(13, FontWeight.w600).copyWith(color: AppColors.textFaint)),
              ])),
            ]),
          ),
          legend(AppColors.accent, Money.compact(series.income[i])),
          const SizedBox(width: 12),
          legend(AppColors.ink, Money.compact(series.expense[i])),
        ]),
        const SizedBox(height: 18),
        CashBars(
          income: series.income,
          expense: series.expense,
          labels: series.labels,
          selected: i,
          onSelect: onSelect,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
          child: Row(children: [
            Expanded(child: _tot('Income · ${range.label}', Money.compact(series.totalIncome))),
            Expanded(child: _tot('Expenses', Money.compact(series.totalExpense))),
            Expanded(
                child: _tot('Net', Money.compact(series.totalIncome - series.totalExpense), color: AppColors.primary)),
          ]),
        ),
      ]),
    );
  }

  Widget _tot(String l, String v, {Color? color}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: AppType.micro),
        const SizedBox(height: 2),
        Text(v, style: AppType.num(16).copyWith(color: color ?? AppColors.ink)),
      ]);
}
