import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/clock.dart';
import '../../features/finance/domain/finance_analytics.dart';
import '../../features/properties/domain/property_metrics.dart';
import 'collections.dart';

/// Metrics for every property, recomputed only when properties, leases or
/// charges change.
final propertyMetricsProvider = Provider<List<PropertyMetrics>>((ref) {
  final props = ref.watch(propertiesProvider).value ?? const [];
  final leases = ref.watch(leasesProvider).value ?? const [];
  final charges = ref.watch(chargesProvider).value ?? const [];
  final today = ref.read(clockProvider).today();
  // Repository order = order added, so new properties appear last.
  return [for (final p in props) PropertyMetrics.compute(p, leases, charges, today)];
});

final metricsForProvider = Provider.family<PropertyMetrics?, String>((ref, id) {
  for (final m in ref.watch(propertyMetricsProvider)) {
    if (m.property.id == id) return m;
  }
  return null;
});

final portfolioSummaryProvider =
    Provider<PortfolioSummary>((ref) => PortfolioSummary(ref.watch(propertyMetricsProvider)));

/// Current calendar month income / expenses / net.
final thisMonthProvider = Provider<MonthTotals>((ref) {
  final ledger = ref.watch(ledgerProvider).value ?? const [];
  return FinanceAnalytics.monthTotals(ledger, ref.read(clockProvider).today());
});

/// Portfolio value month-by-month for the last 12 months (Home line chart).
final valueSeriesProvider = Provider<List<double>>((ref) {
  final props = ref.watch(propertiesProvider).value ?? const [];
  final today = ref.read(clockProvider).today();
  return List.generate(12, (i) {
    final m = DateTime(today.year, today.month - 11 + i);
    var total = 0;
    for (final p in props) {
      final h = p.valueHistory.where((v) => !v.date.isAfter(m));
      total += h.isEmpty ? (p.createdAt.isAfter(m) ? 0 : p.currentValue) : h.last.value;
    }
    return i == 11 ? props.fold<int>(0, (s, p) => s + p.currentValue).toDouble() : total.toDouble();
  });
});
