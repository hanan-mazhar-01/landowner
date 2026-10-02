import '../../../core/utils/formatters.dart';
import '../../finance/domain/finance_analytics.dart';
import '../../finance/domain/ledger_entry.dart';
import '../../leases/domain/rent_charge.dart';
import '../../properties/domain/property_metrics.dart';

/// Deterministic, data-grounded insights. This is the on-device baseline;
/// the LLM-backed Cloud Function returns richer text through the same
/// `AiRepository` contract.
abstract final class InsightEngine {
  static String forProperty({
    required PropertyMetrics m,
    required List<PropertyMetrics> all,
    required List<RentCharge> charges,
    required List<LedgerEntry> ledger,
    required DateTime today,
    String? overdueUnit,
  }) {
    final p = m.property;
    final mine = charges.where((c) => c.propertyId == p.id && c.isPaid).toList();
    if (mine.isEmpty && m.activeLeases.isEmpty && m.vacantSince == null) {
      return 'New to your portfolio. Insights appear once a month of income and expenses is recorded.';
    }
    if (m.overdue.isNotEmpty) {
      final c = m.overdue.first;
      final others = m.activeLeases.length - 1;
      final streak = _onTimeStreak(charges.where((x) => x.propertyId == p.id && x.leaseId != c.leaseId).toList());
      return '${overdueUnit ?? 'Rent'} is ${c.daysLate(today)} days overdue on ${Money.k(c.amount)}.'
          '${others > 0 ? ' The other ${_n(others)} units have paid on time for $streak consecutive month${streak == 1 ? '' : 's'}.' : ''}';
    }
    if (m.isVacant && m.vacantSince != null) {
      final days = today.difference(m.vacantSince!).inDays;
      final annual = all.fold<int>(0, (s, x) => s + x.monthlyRent) * 12;
      final pct = annual == 0 ? 0 : m.lastRent / annual * 100;
      return 'Vacant for $days days. At its last rent of ${Money.k(m.lastRent)}, each empty month lowers annual '
          'portfolio income by about ${pct.toStringAsFixed(1)}%.';
    }
    final best = [...all]..sort((a, b) => b.yieldPct.compareTo(a.yieldPct));
    if (best.isNotEmpty && best.first.property.id == p.id && m.units > m.occupiedUnits) {
      final perUnit = m.occupiedUnits == 0 ? 0 : m.monthlyRent / m.occupiedUnits;
      return '${all.length > 1 ? 'Highest yield in your portfolio' : 'Yielding'} at ${m.yieldPct.toStringAsFixed(1)}%. '
          '${_cap(_n(m.units - m.occupiedUnits))} of ${_n(m.units)} units is vacant — letting it would add about '
          '${Money.k((perUnit / 1000).round() * 1000)} a month.';
    }
    final q0 = DateTime(today.year, ((today.month - 1) ~/ 3) * 3 + 1);
    final cur = FinanceAnalytics.between(ledger, q0, today.add(const Duration(days: 1)), propertyId: p.id).expense;
    final prev = FinanceAnalytics.between(ledger, Dates.addMonths(q0, -3), q0, propertyId: p.id).expense;
    final streak = _onTimeStreak(mine);
    final record = switch (streak) {
      0 when mine.isEmpty => 'Record the first rent payment to start tracking reliability.',
      0 => 'The latest rent payment arrived after the grace period.',
      1 => 'Rent has been paid on time for 1 month.',
      _ => 'Rent has been paid on time for $streak months.',
    };
    if (prev > 0) {
      final ch = (cur - prev) / prev * 100;
      return 'Costs are ${ch >= 0 ? 'up' : 'down'} ${ch.abs().toStringAsFixed(0)}% on last quarter so far. $record';
    }
    return record;
  }

  static int _onTimeStreak(List<RentCharge> cs) {
    final paid = cs.where((c) => c.isPaid).toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    var n = 0;
    for (final c in paid) {
      if (c.paidLate()) break;
      n++;
    }
    return n.clamp(0, 99);
  }

  static String _n(int n) =>
      const ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'].elementAtOrNull(n) ?? '$n';
  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
