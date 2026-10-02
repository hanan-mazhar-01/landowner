import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../../../shared/providers/collections.dart';
import '../../leases/domain/lease.dart';
import '../../leases/domain/rent_charge.dart';
import '../../properties/domain/property.dart';
import '../domain/tenancy_status.dart';
import '../domain/tenant.dart';

/// Row model for the tenant list.
class TenancyRow {
  const TenancyRow(this.tenancy, this.tenant, this.property);
  final Tenancy tenancy;
  final Tenant? tenant;
  final Property? property;

  Lease get lease => tenancy.lease;
  String get place => '${property?.name ?? ''}${lease.unitLabel == null ? '' : ' · ${lease.unitLabel}'}';
}

final tenancyRowsProvider = Provider<List<TenancyRow>>((ref) {
  final today = ref.read(clockProvider).today();
  final charges = ref.watch(chargesProvider).value ?? const <RentCharge>[];
  final tenants = {for (final t in ref.watch(tenantsProvider).value ?? const <Tenant>[]) t.id: t};
  final props = {for (final p in ref.watch(propertiesProvider).value ?? const <Property>[]) p.id: p};
  return [
    for (final l in ref.watch(leasesProvider).value ?? const <Lease>[])
      TenancyRow(Tenancy.of(l, charges, today), tenants[l.tenantId], props[l.propertyId]),
  ];
});

final tenancyRowProvider = Provider.autoDispose.family<TenancyRow?, String>((ref, leaseId) {
  for (final r in ref.watch(tenancyRowsProvider)) {
    if (r.lease.id == leaseId) return r;
  }
  return null;
});

/// Active lease for a property (first by start date) — Tenancy card entry.
final primaryLeaseForProvider = Provider.autoDispose.family<String?, String>((ref, propertyId) {
  final today = ref.read(clockProvider).today();
  final rows = ref.watch(tenancyRowsProvider).where((r) => r.lease.propertyId == propertyId && r.lease.isActiveOn(today)).toList()
    ..sort((a, b) {
      int rank(TenancyRow r) => r.tenancy.status == TenancyStatus.overdue ? 0 : 1;
      final byRank = rank(a) - rank(b);
      return byRank != 0 ? byRank : a.lease.start.compareTo(b.lease.start);
    });
  return rows.isEmpty ? null : rows.first.lease.id;
});
