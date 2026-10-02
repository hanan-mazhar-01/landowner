import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import 'ledger_entry.dart';

enum FinanceRange { m1('1M'), m6('6M'), y1('1Y'), all('ALL');

  const FinanceRange(this.label);
  final String label;
}

/// Income vs expense buckets for the Finance chart.
@immutable
class CashSeries {
  const CashSeries(this.labels, this.fullLabels, this.income, this.expense);
  final List<String> labels;
  final List<String> fullLabels;
  final List<int> income;
  final List<int> expense;

  int get totalIncome => income.fold(0, (a, b) => a + b);
  int get totalExpense => expense.fold(0, (a, b) => a + b);
  int get length => labels.length;
}

@immutable
class MonthTotals {
  const MonthTotals(this.income, this.expense);
  final int income;
  final int expense;
  int get net => income - expense;
  double get keptPct => income == 0 ? 0 : net / income * 100;
}

@immutable
class CategoryShare {
  const CategoryShare(this.category, this.amount, this.share);
  final ExpenseCategory category;
  final int amount;
  final double share;
}

/// Pure financial analytics over the ledger.
abstract final class FinanceAnalytics {
  static bool _inMonth(DateTime d, DateTime m) => d.year == m.year && d.month == m.month;

  static MonthTotals monthTotals(Iterable<LedgerEntry> ledger, DateTime month, {String? propertyId}) {
    var inc = 0, exp = 0;
    for (final e in ledger) {
      if (propertyId != null && e.propertyId != propertyId) continue;
      if (!_inMonth(e.date, month)) continue;
      e.isIncome ? inc += e.amount : exp += e.amount;
    }
    return MonthTotals(inc, exp);
  }

  static MonthTotals between(Iterable<LedgerEntry> ledger, DateTime from, DateTime to, {String? propertyId}) {
    var inc = 0, exp = 0;
    for (final e in ledger) {
      if (propertyId != null && e.propertyId != propertyId) continue;
      if (e.date.isBefore(from) || !e.date.isBefore(to)) continue;
      e.isIncome ? inc += e.amount : exp += e.amount;
    }
    return MonthTotals(inc, exp);
  }

  static CashSeries series(Iterable<LedgerEntry> ledger, FinanceRange range, DateTime today) {
    final m0 = Dates.monthStart(today);
    switch (range) {
      case FinanceRange.m1:
        final weeks = <(DateTime, DateTime)>[];
        for (var w = 0; w < 4; w++) {
          final from = m0.add(Duration(days: w * 7));
          final to = w == 3 ? Dates.addMonths(m0, 1) : m0.add(Duration(days: (w + 1) * 7));
          weeks.add((from, to));
        }
        final t = weeks.map((w) => between(ledger, w.$1, w.$2)).toList();
        return CashSeries(List.generate(4, (i) => 'W${i + 1}'), List.generate(4, (i) => 'Week ${i + 1}'),
            t.map((e) => e.income).toList(), t.map((e) => e.expense).toList());
      case FinanceRange.m6:
      case FinanceRange.y1:
        final n = range == FinanceRange.m6 ? 6 : 12;
        final months = List.generate(n, (i) => Dates.addMonths(m0, i - n + 1));
        final t = months.map((m) => monthTotals(ledger, m)).toList();
        return CashSeries(
          months.map((m) => n == 12 ? Dates.mon(m)[0] : Dates.mon(m)).toList(),
          months.map(Dates.mon).toList(),
          t.map((e) => e.income).toList(),
          t.map((e) => e.expense).toList(),
        );
      case FinanceRange.all:
        final years = <int>{for (final e in ledger) e.date.year}.toList()..sort();
        final ys = years.isEmpty ? [today.year] : years;
        final t = ys.map((y) => between(ledger, DateTime(y), DateTime(y + 1))).toList();
        final labels = ys.map((y) => '$y').toList();
        return CashSeries(labels, labels, t.map((e) => e.income).toList(), t.map((e) => e.expense).toList());
    }
  }

  static List<CategoryShare> breakdown(Iterable<LedgerEntry> ledger, DateTime month) {
    final by = <ExpenseCategory, int>{};
    for (final e in ledger) {
      if (e.isIncome || !_inMonth(e.date, month)) continue;
      final c = e.expenseCategory ?? ExpenseCategory.other;
      by[c] = (by[c] ?? 0) + e.amount;
    }
    final total = by.values.fold(0, (a, b) => a + b);
    final list = by.entries.map((e) => CategoryShare(e.key, e.value, total == 0 ? 0 : e.value / total)).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  /// Monthly average per quarter for the last 8 quarters (Rent / Costs tabs).
  static List<int> quarterlyAverages(Iterable<LedgerEntry> ledger, DateTime today, String propertyId,
      {required bool income}) {
    final q0 = DateTime(today.year, ((today.month - 1) ~/ 3) * 3 + 1);
    return List.generate(8, (i) {
      final from = Dates.addMonths(q0, (i - 7) * 3);
      final t = between(ledger, from, Dates.addMonths(from, 3), propertyId: propertyId);
      return ((income ? t.income : t.expense) / 3).round();
    });
  }

  /// "Q4'24, Q1, Q2, Q3, Q4, Q1'26…" labels matching the design.
  static List<String> quarterLabels(DateTime today) {
    final q0 = DateTime(today.year, ((today.month - 1) ~/ 3) * 3 + 1);
    return List.generate(8, (i) {
      final d = Dates.addMonths(q0, (i - 7) * 3);
      final q = (d.month - 1) ~/ 3 + 1;
      final withYear = i == 0 || q == 1;
      return withYear ? "Q$q'${(d.year % 100).toString().padLeft(2, '0')}" : 'Q$q';
    });
  }
}
