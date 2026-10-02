import 'package:flutter/foundation.dart';

import '../../leases/domain/lease.dart';
import '../../leases/domain/rent_charge.dart';
import 'property.dart';

/// Live operating figures for one property, derived from its leases and
/// rent ledger. Pure — no Flutter or storage dependencies.
@immutable
class PropertyMetrics {
  const PropertyMetrics({
    required this.property,
    required this.activeLeases,
    required this.monthlyRent,
    required this.rentStatus,
    required this.overdue,
    required this.nextDue,
    required this.lastRent,
    required this.vacantSince,
  });

  final Property property;
  final List<Lease> activeLeases;
  final int monthlyRent;
  final RentStatus? rentStatus;
  final List<RentCharge> overdue;
  final RentCharge? nextDue;

  /// Rent of the most recent lease (for vacant properties).
  final int lastRent;
  final DateTime? vacantSince;

  int get occupiedUnits => activeLeases.length;
  int get units => property.unitCount;
  bool get isVacant => activeLeases.isEmpty && property.status != PropertyStatus.owned;
  int get monthlyExpenses => property.monthlyExpenses;
  int get net => monthlyRent - monthlyExpenses;

  /// Net rental yield — net rent × 12 ÷ current value.
  double get yieldPct => property.currentValue == 0 || monthlyRent == 0
      ? 0
      : net * 12 / property.currentValue * 100;

  /// Label shown on cards: Occupied · Vacant · 5 of 6 let · Owned · Maintenance.
  String get statusLabel {
    if (property.status == PropertyStatus.maintenance) return 'Maintenance';
    if (property.status == PropertyStatus.owned) return 'Owned';
    if (activeLeases.isEmpty) return 'Vacant';
    if (units > 1 && occupiedUnits < units) return '$occupiedUnits of $units let';
    return 'Occupied';
  }

  bool get statusIsAttention => statusLabel == 'Vacant' || statusLabel == 'Maintenance';

  static PropertyMetrics compute(
    Property p,
    List<Lease> leases,
    List<RentCharge> charges,
    DateTime today,
  ) {
    final mine = leases.where((l) => l.propertyId == p.id).toList()..sort((a, b) => b.end.compareTo(a.end));
    final active = mine.where((l) => l.isActiveOn(today)).toList();
    final activeIds = active.map((l) => l.id).toSet();
    final myCharges = charges.where((c) => c.propertyId == p.id).toList();
    final overdue = myCharges.where((c) => c.statusOn(today) == RentStatus.overdue).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final upcoming = myCharges
        .where((c) => activeIds.contains(c.leaseId) && !c.isPaid && !c.dueDate.isBefore(today))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    RentStatus? status;
    if (overdue.isNotEmpty) {
      status = RentStatus.overdue;
    } else if (active.isNotEmpty) {
      final latestDue = myCharges.where((c) => activeIds.contains(c.leaseId) && !c.dueDate.isAfter(today));
      status = latestDue.isEmpty || latestDue.every((c) => c.isPaid) ? RentStatus.paid : RentStatus.pending;
    }

    return PropertyMetrics(
      property: p,
      activeLeases: active,
      monthlyRent: active.fold(0, (s, l) => s + l.monthlyRent),
      rentStatus: status,
      overdue: overdue,
      nextDue: upcoming.isEmpty ? null : upcoming.first,
      lastRent: mine.isEmpty ? 0 : mine.first.monthlyRent,
      vacantSince: active.isEmpty && mine.isNotEmpty ? mine.first.end : null,
    );
  }
}

/// Portfolio-wide roll-up.
@immutable
class PortfolioSummary {
  const PortfolioSummary(this.metrics);
  final List<PropertyMetrics> metrics;

  int get count => metrics.length;
  int get totalValue => metrics.fold(0, (s, m) => s + m.property.currentValue);
  int get units => metrics.fold(0, (s, m) => s + m.units);
  int get occupied => metrics.fold(0, (s, m) => s + m.occupiedUnits);
  int get monthlyRent => metrics.fold(0, (s, m) => s + m.monthlyRent);
  List<RentCharge> get overdue => [for (final m in metrics) ...m.overdue];
  double get occupancy => units == 0 ? 0 : occupied / units;
}
