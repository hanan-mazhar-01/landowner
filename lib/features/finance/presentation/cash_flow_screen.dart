import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/text_blocks.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/widgets/sub_page.dart';
import '../domain/finance_analytics.dart';
import 'finance_providers.dart';
import 'widgets/cash_flow_card.dart';

/// Cash flow — the Finance chart plus period rows and per-property net.
class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});
  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  FinanceRange _range = FinanceRange.y1;
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final today = ref.read(clockProvider).today();
    final s = ref.watch(financeSeriesProvider(_range));
    final ledger = ref.watch(ledgerProvider).value ?? const [];
    final props = ref.watch(propertiesProvider).value ?? const [];
    final from = switch (_range) {
      FinanceRange.m1 => Dates.monthStart(today),
      FinanceRange.m6 => Dates.addMonths(Dates.monthStart(today), -5),
      FinanceRange.y1 => Dates.addMonths(Dates.monthStart(today), -11),
      FinanceRange.all => DateTime(1970),
    };
    final to = Dates.addMonths(Dates.monthStart(today), 1);
    final byProp = [
      for (final p in props) (p.name, FinanceAnalytics.between(ledger, from, to, propertyId: p.id)),
    ]..sort((a, b) => b.$2.net.compareTo(a.$2.net));

    Widget row(String label, int inc, int exp, {bool first = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: first ? null : const BoxDecoration(border: Border(top: BorderSide(color: AppColors.dividerSoft))),
          child: Row(children: [
            Expanded(flex: 5, child: Text(label, style: AppType.rowTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Expanded(flex: 3, child: Text(Money.compact(inc), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: AppColors.positiveText))),
            Expanded(flex: 3, child: Text(Money.compact(exp), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            Expanded(
              flex: 3,
              child: Text(Money.compact(inc - exp),
                  textAlign: TextAlign.right, style: AppType.num(14, FontWeight.w800).copyWith(color: AppColors.primary)),
            ),
          ]),
        );

    return SubPage(
      title: 'Cash flow',
      subtitle: 'Income minus expenses, by period and property',
      action: InkSegments(
        labels: [for (final r in FinanceRange.values) r.label],
        index: _range.index,
        onChanged: (i) => setState(() {
          _range = FinanceRange.values[i];
          _sel = null;
        }),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: CashFlowCard(
            series: s,
            range: _range,
            selected: _sel ?? s.length - 1,
            onSelect: (i) => setState(() => _sel = i),
            monthName: Dates.month(today),
          ),
        ),
        const SliverToBoxAdapter(child: Overline('By period')),
        SliverToBoxAdapter(
          child: SurfaceCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            radius: AppRadius.list,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Column(children: [
              for (var i = s.length - 1; i >= 0; i--) row(s.fullLabels[i], s.income[i], s.expense[i], first: i == s.length - 1),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: Overline('By property')),
        SliverToBoxAdapter(
          child: SurfaceCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            radius: AppRadius.list,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Column(children: [
              for (final (i, r) in byProp.indexed) row(r.$1, r.$2.income, r.$2.expense, first: i == 0),
            ]),
          ),
        ),
      ],
    );
  }
}
