import 'dart:math' as math;

import '../../../core/utils/formatters.dart';
import '../../../features/finance/domain/ledger_entry.dart';
import '../../../features/leases/domain/lease.dart';
import '../../../features/leases/domain/rent_charge.dart';
import '../../../features/properties/domain/property.dart';

const _historyMonths = 48;

DateTime _due(int y, int m, int day) {
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, day > last ? last : day);
}

/// Rent history for every lease: paid on time, one late payment on Green
/// Villa three months ago, and the latest LuxeApart Unit 3 charge unpaid.
List<RentCharge> seedCharges(List<Lease> leases, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final horizon = Dates.addMonths(today, 1);
  final floor = Dates.addMonths(Dates.monthStart(today), -_historyMonths);
  final out = <RentCharge>[];
  for (final l in leases) {
    var cursor = Dates.monthStart(l.start.isBefore(floor) ? floor : l.start);
    final lease = <RentCharge>[];
    while (!cursor.isAfter(horizon)) {
      final due = _due(cursor.year, cursor.month, l.dueDay);
      if (!due.isBefore(l.start) && !due.isAfter(l.end) && !due.isAfter(horizon)) {
        final monthsBack = (today.year - due.year) * 12 + today.month - due.month;
        final factor = 1 - 0.05 * (monthsBack.clamp(0, 999) / 12);
        final amount = (l.monthlyRent * factor / 500).round() * 500;
        final c = RentCharge(
          leaseId: l.id,
          propertyId: l.propertyId,
          tenantId: l.tenantId,
          dueDate: due,
          amount: amount,
          graceDays: l.graceDays,
        );
        final late = l.id == 'l1' && monthsBack == 3;
        final paidAt = due.add(Duration(days: late ? 6 : lease.length % 3));
        lease.add(due.isAfter(today) ? c : c.markPaid(paidAt.isAfter(today) ? today : paidAt, 'Bank transfer'));
      }
      cursor = Dates.addMonths(cursor, 1);
    }
    if (l.id == 'l2') {
      final i = lease.lastIndexWhere((c) => !c.dueDate.isAfter(today));
      if (i >= 0) {
        final c = lease[i];
        lease[i] = RentCharge(
          leaseId: c.leaseId,
          propertyId: c.propertyId,
          tenantId: c.tenantId,
          dueDate: c.dueDate,
          amount: 46000,
          graceDays: c.graceDays,
        );
      }
    }
    out.addAll(lease);
  }
  return out;
}

List<LedgerEntry> seedIncome(List<RentCharge> charges) => [
      for (final c in charges)
        if (c.isPaid)
          LedgerEntry(
            id: 'inc_${c.id}',
            kind: EntryKind.income,
            propertyId: c.propertyId,
            tenantId: c.tenantId,
            title: 'Rent',
            amount: c.amount,
            date: c.paidAt!,
            incomeType: IncomeType.rent,
            sourceRef: c.id,
          ),
    ];

LedgerEntry _exp(String id, String prop, String title, int amount, DateTime date, ExpenseCategory cat,
        {String? ref}) =>
    LedgerEntry(
      id: id,
      kind: EntryKind.expense,
      propertyId: prop,
      title: title,
      amount: amount,
      date: date,
      expenseCategory: cat,
      sourceRef: ref,
    );

/// Recurring running costs for past months plus the design's named
/// expenses for the current month.
List<LedgerEntry> seedExpenses(List<Property> props, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final rnd = math.Random(7);
  final out = <LedgerEntry>[];
  for (final p in props) {
    for (var back = _historyMonths; back >= 1; back--) {
      final m = Dates.addMonths(Dates.monthStart(today), -back);
      if (m.isBefore(Dates.monthStart(p.createdAt))) continue;
      final base = p.monthlyExpenses * (0.85 + rnd.nextDouble() * 0.3);
      void add(String t, double share, ExpenseCategory c, int day) => out.add(_exp(
          'exp_${p.id}_${m.year}${m.month}_${c.name}', p.id, t, (base * share / 500).round() * 500,
          DateTime(m.year, m.month, day), c));
      add('Utilities', .34, ExpenseCategory.utilities, 8);
      add('Upkeep', .30, ExpenseCategory.maintenance, 14);
      add('Management fee', .16, ExpenseCategory.management, 3);
      if (back % 4 == 0) add('Repairs', .45, ExpenseCategory.repairs, 20);
      if (m.month == today.month) add('Property tax', 1.3, ExpenseCategory.tax, 25);
      if (m.month == 10) add('Insurance premium', 1.1, ExpenseCategory.insurance, 13);
    }
  }
  DateTime ago(int d) => today.subtract(Duration(days: d));
  out.addAll([
    _exp('e_hvac_dep', 'p3', 'HVAC deposit', 20000, ago(1), ExpenseCategory.maintenance, ref: 'm5'),
    _exp('e_elec', 'p2', 'Electricity', 31000, ago(4), ExpenseCategory.utilities),
    _exp('e_tax', 'p4', 'Property tax', 37000, ago(5), ExpenseCategory.tax),
    _exp('e_gate', 'p1', 'Gate motor repair', 22000, ago(6), ExpenseCategory.repairs),
    _exp('e_water', 'p3', 'Water & gas', 30000, ago(8), ExpenseCategory.utilities),
    _exp('e_clean', 'p4', 'Deep clean', 6000, ago(10), ExpenseCategory.maintenance, ref: 'm8'),
    _exp('e_irrig', 'p1', 'Garden irrigation repair', 8500, ago(12), ExpenseCategory.maintenance, ref: 'm2'),
    _exp('e_upkeep', 'p2', 'Common area upkeep', 40500, ago(15), ExpenseCategory.maintenance),
    _exp('e_lobby', 'p3', 'Lobby lighting', 9000, ago(19), ExpenseCategory.maintenance, ref: 'm6'),
    _exp('e_heater', 'p2', 'Unit 2 water heater', 14000, ago(28), ExpenseCategory.maintenance, ref: 'm4'),
  ]);
  return out;
}
