import '../../../core/icons/homely_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../leases/domain/rent_charge.dart';
import '../../maintenance/domain/maintenance_ticket.dart';
import '../../properties/domain/property_metrics.dart';
import 'finance_analytics.dart';
import 'ledger_entry.dart';

enum ReportType {
  portfolio('Portfolio summary', 'Value, income, costs and net for every property', HomelyIcons.home),
  income('Income report', 'Every income line by property and type', HomelyIcons.trendUp),
  expense('Expense report', 'Costs by category and property', HomelyIcons.trendDown),
  cashFlow('Cash flow report', 'Income minus expenses, month by month', HomelyIcons.chart),
  performance('Property performance', 'Value growth, net rent and yield', HomelyIcons.compare),
  rental('Rental income report', 'Rent due versus collected', HomelyIcons.coin),
  maintenance('Maintenance cost report', 'Repairs and upkeep by property', HomelyIcons.wrench);

  const ReportType(this.label, this.description, this.icon);
  final String label, description;
  final HomelyIcons icon;
}

class ReportPeriod {
  const ReportPeriod(this.label, this.from, this.to);
  final String label;
  final DateTime from, to; // [from, to)

  static ReportPeriod preset(String label, DateTime today) {
    final m0 = DateTime(today.year, today.month);
    return switch (label) {
      'Last month' => ReportPeriod(label, DateTime(today.year, today.month - 1), m0),
      'This year' => ReportPeriod(label, DateTime(today.year), DateTime(today.year + 1)),
      'Last year' => ReportPeriod(label, DateTime(today.year - 1), DateTime(today.year)),
      _ => ReportPeriod('This month', m0, DateTime(today.year, today.month + 1)),
    };
  }

  bool contains(DateTime d) => !d.isBefore(from) && d.isBefore(to);
  String get range => '${Dates.dMy(from)} – ${Dates.dMy(to.subtract(const Duration(days: 1)))}';
}

class ReportRow {
  const ReportRow(this.label, this.sub, this.values);
  final String label, sub;
  final List<int> values;
}

/// Everything a report shows — and exactly what CSV/PDF export writes.
class ReportData {
  const ReportData({
    required this.type,
    required this.period,
    required this.income,
    required this.expense,
    required this.series,
    required this.columns,
    required this.rows,
    this.categories = const [],
    this.note = '',
    this.percentColumns = const {},
  });

  final ReportType type;
  final ReportPeriod period;
  final int income, expense;
  final CashSeries series;
  final List<String> columns;
  final List<ReportRow> rows;
  final List<CategoryShare> categories;
  final String note;

  /// Columns holding yield in tenths of a percent (75 → 7.5%).
  final Set<int> percentColumns;
  int get net => income - expense;

  String cell(int column, int v) => percentColumns.contains(column) ? '${(v / 10).toStringAsFixed(1)}%' : Money.compact(v);
}

abstract final class ReportBuilder {
  static ReportData build({
    required ReportType type,
    required ReportPeriod period,
    required List<PropertyMetrics> metrics,
    required List<LedgerEntry> ledger,
    required List<RentCharge> charges,
    required List<MaintenanceTicket> maintenance,
    String? propertyId,
  }) {
    final ms = metrics.where((m) => propertyId == null || m.property.id == propertyId).toList();
    final ids = {for (final m in ms) m.property.id};
    final entries = ledger.where((e) => ids.contains(e.propertyId) && period.contains(e.date)).toList();
    final inc = entries.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
    final exp = entries.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
    final series = _series(entries, period);
    MonthTotals t(String pid) => FinanceAnalytics.between(entries, period.from, period.to, propertyId: pid);

    List<ReportRow> byProperty() => [
          for (final m in ms) ReportRow(m.property.name, m.property.location, [t(m.property.id).income, t(m.property.id).expense, t(m.property.id).net]),
        ];

    switch (type) {
      case ReportType.portfolio:
      case ReportType.cashFlow:
        return ReportData(
          type: type,
          period: period,
          income: inc,
          expense: exp,
          series: series,
          columns: const ['Income', 'Expenses', 'Net'],
          rows: type == ReportType.cashFlow
              ? [for (var i = 0; i < series.length; i++) ReportRow(series.fullLabels[i], '', [series.income[i], series.expense[i], series.income[i] - series.expense[i]])]
              : byProperty(),
        );
      case ReportType.income:
        final byType = <String, int>{};
        for (final e in entries.where((e) => e.isIncome)) {
          byType[e.incomeType?.label ?? 'Other'] = (byType[e.incomeType?.label ?? 'Other'] ?? 0) + e.amount;
        }
        return ReportData(type: type, period: period, income: inc, expense: 0, series: _only(series, income: true),
            columns: const ['Income'],
            rows: [
              for (final m in ms) ReportRow(m.property.name, m.property.location, [t(m.property.id).income]),
              for (final e in byType.entries) ReportRow(e.key, 'Income type', [e.value]),
            ]);
      case ReportType.expense:
      case ReportType.maintenance:
        final maint = type == ReportType.maintenance;
        final ex = entries.where((e) => !e.isIncome && (!maint || e.expenseCategory == ExpenseCategory.maintenance || e.expenseCategory == ExpenseCategory.repairs)).toList();
        final total = ex.fold(0, (s, e) => s + e.amount);
        final cats = _shares(ex);
        final names = {for (final m in ms) m.property.id: m.property.name};
        return ReportData(type: type, period: period, income: 0, expense: total, series: _only(_series(ex, period), income: false),
            columns: const ['Expenses'], categories: cats,
            rows: maint
                ? [
                    for (final tk in maintenance.where((x) => ids.contains(x.propertyId) && period.contains(x.scheduledFor)))
                      ReportRow(tk.title, '${names[tk.propertyId]} · ${tk.status.label}', [tk.cost]),
                  ]
                : [for (final m in ms) ReportRow(m.property.name, m.property.location, [ex.where((e) => e.propertyId == m.property.id).fold(0, (s, e) => s + e.amount)])]);
      case ReportType.performance:
        return ReportData(type: type, period: period, income: inc, expense: exp, series: series,
            columns: const ['Value', 'Net / mo', 'Yield'],
            percentColumns: const {2},
            rows: [
              for (final m in ms)
                ReportRow(m.property.name, '${m.statusLabel} · up ${m.property.gainPct.toStringAsFixed(1)}%',
                    [m.property.currentValue, m.net, (m.yieldPct * 10).round()]),
            ]);
      case ReportType.rental:
        final due = charges.where((c) => ids.contains(c.propertyId) && period.contains(c.dueDate)).toList();
        final dueSum = due.fold(0, (s, c) => s + c.amount);
        final paid = due.where((c) => c.isPaid).fold(0, (s, c) => s + c.amount);
        return ReportData(type: type, period: period, income: paid, expense: dueSum - paid, series: _only(series, income: true),
            columns: const ['Due', 'Collected', 'Outstanding'],
            note: dueSum == 0 ? '' : 'Collection rate ${(paid / dueSum * 100).toStringAsFixed(1)}%',
            rows: [
              for (final m in ms)
                () {
                  final d = due.where((c) => c.propertyId == m.property.id);
                  final ds = d.fold(0, (s, c) => s + c.amount), ps = d.where((c) => c.isPaid).fold(0, (s, c) => s + c.amount);
                  return ReportRow(m.property.name, '${d.length} rent charges', [ds, ps, ds - ps]);
                }(),
            ]);
    }
  }

  static CashSeries _series(List<LedgerEntry> entries, ReportPeriod p) {
    final months = <DateTime>[];
    for (var m = DateTime(p.from.year, p.from.month); m.isBefore(p.to); m = DateTime(m.year, m.month + 1)) {
      months.add(m);
    }
    if (months.length <= 1) {
      final weeks = List.generate(4, (i) => (p.from.add(Duration(days: i * 7)), i == 3 ? p.to : p.from.add(Duration(days: (i + 1) * 7))));
      final t = weeks.map((w) => FinanceAnalytics.between(entries, w.$1, w.$2)).toList();
      return CashSeries([for (var i = 1; i <= 4; i++) 'W$i'], [for (var i = 1; i <= 4; i++) 'Week $i'],
          t.map((e) => e.income).toList(), t.map((e) => e.expense).toList());
    }
    final t = months.map((m) => FinanceAnalytics.monthTotals(entries, m)).toList();
    return CashSeries(months.map((m) => months.length > 8 ? Dates.mon(m)[0] : Dates.mon(m)).toList(),
        months.map((m) => '${Dates.mon(m)} ${m.year}').toList(), t.map((e) => e.income).toList(), t.map((e) => e.expense).toList());
  }

  static CashSeries _only(CashSeries s, {required bool income}) => income
      ? CashSeries(s.labels, s.fullLabels, s.income, List.filled(s.length, 0))
      : CashSeries(s.labels, s.fullLabels, s.expense, List.filled(s.length, 0));

  static List<CategoryShare> _shares(List<LedgerEntry> ex) {
    final by = <ExpenseCategory, int>{};
    for (final e in ex) {
      by[e.expenseCategory ?? ExpenseCategory.other] = (by[e.expenseCategory ?? ExpenseCategory.other] ?? 0) + e.amount;
    }
    final total = by.values.fold(0, (a, b) => a + b);
    return by.entries.map((e) => CategoryShare(e.key, e.value, total == 0 ? 0 : e.value / total)).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }
}
