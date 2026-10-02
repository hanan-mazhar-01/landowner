import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/portfolio.dart';
import '../../leases/domain/rent_charge.dart';
import '../domain/finance_analytics.dart';

final financeSeriesProvider = Provider.family<CashSeries, FinanceRange>((ref, range) {
  final ledger = ref.watch(ledgerProvider).value ?? const [];
  return FinanceAnalytics.series(ledger, range, ref.read(clockProvider).today());
});

final lastMonthProvider = Provider<MonthTotals>((ref) {
  final ledger = ref.watch(ledgerProvider).value ?? const [];
  final t = ref.read(clockProvider).today();
  return FinanceAnalytics.monthTotals(ledger, DateTime(t.year, t.month - 1));
});

final expenseBreakdownProvider = Provider<List<CategoryShare>>((ref) {
  final ledger = ref.watch(ledgerProvider).value ?? const [];
  return FinanceAnalytics.breakdown(ledger, ref.read(clockProvider).today());
});

class FinanceInsight {
  const FinanceInsight(this.stat, this.text, this.source, {this.primary = false});
  final String stat, text, source;
  final bool primary;
}

/// "What changed" — computed, source-attributed statements.
final financeInsightsProvider = Provider<List<FinanceInsight>>((ref) {
  final today = ref.read(clockProvider).today();
  final ledger = ref.watch(ledgerProvider).value ?? const [];
  final charges = ref.watch(chargesProvider).value ?? const <RentCharge>[];
  final metrics = ref.watch(propertyMetricsProvider);
  final out = <FinanceInsight>[];

  final q0 = DateTime(today.year, ((today.month - 1) ~/ 3) * 3 + 1);
  final qPrev = Dates.addMonths(q0, -3);
  final cur = FinanceAnalytics.between(ledger, q0, Dates.addMonths(q0, 3)).income;
  final prev = FinanceAnalytics.between(ledger, qPrev, q0).income;
  if (prev > 0) {
    final ch = (cur - prev) / prev * 100;
    String lead = '';
    var best = -1 << 31;
    for (final m in metrics) {
      final d = FinanceAnalytics.between(ledger, q0, Dates.addMonths(q0, 3), propertyId: m.property.id).income -
          FinanceAnalytics.between(ledger, qPrev, q0, propertyId: m.property.id).income;
      if (d > best) (best, lead) = (d, m.property.name);
    }
    out.add(FinanceInsight(
      '${ch >= 0 ? '+' : '−'}${ch.abs().toStringAsFixed(1)}%',
      'Rental income ${ch >= 0 ? 'rose' : 'fell'} versus last quarter${lead.isEmpty ? '' : ', led by $lead'}.',
      '${Dates.mon(q0)}–${Dates.mon(Dates.addMonths(q0, 2))} vs ${Dates.mon(qPrev)}–${Dates.mon(Dates.addMonths(qPrev, 2))}',
      primary: true,
    ));
  }

  final shares = FinanceAnalytics.breakdown(ledger, today);
  if (shares.isNotEmpty) {
    out.add(FinanceInsight('${(shares.first.share * 100).round()}%',
        'of this month’s expenses went to ${shares.first.category.label.toLowerCase()} — the largest category.',
        '${Dates.month(today)} expenses'));
  }

  final due = charges.where((c) => c.dueDate.year == today.year && c.dueDate.month == today.month && !c.dueDate.isAfter(today));
  final dueTotal = due.fold(0, (s, c) => s + c.amount);
  final paid = due.where((c) => c.isPaid).fold(0, (s, c) => s + c.amount);
  if (dueTotal > 0) {
    final outstanding = dueTotal - paid;
    out.add(FinanceInsight('${(paid / dueTotal * 100).toStringAsFixed(1)}%',
        'of rent due in ${Dates.month(today)} has been collected.${outstanding > 0 ? ' ${Money.k(outstanding)} is outstanding.' : ''}',
        'Rent ledger'));
  }

  final byYield = [...metrics]..sort((a, b) => b.yieldPct.compareTo(a.yieldPct));
  if (byYield.isNotEmpty && byYield.first.yieldPct > 0) {
    out.add(FinanceInsight('${byYield.first.yieldPct.toStringAsFixed(1)}%',
        byYield.length > 1
            ? '${byYield.first.property.name} has the highest rental yield in your portfolio.'
            : 'net rental yield on ${byYield.first.property.name}\u2019s current value.',
        'Net rent ÷ current value'));
  }
  return out;
});
