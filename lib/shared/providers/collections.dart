import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/documents/domain/document_item.dart';
import '../../features/finance/domain/ledger_entry.dart';
import '../../features/leases/domain/lease.dart';
import '../../features/leases/domain/rent_charge.dart';
import '../../features/maintenance/domain/maintenance_ticket.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/properties/domain/property.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/tenants/domain/tenant.dart';
import 'repositories.dart';

// Exactly one live listener per collection, shared by every screen.
// Derived providers read `.value ?? const []` so they stay synchronous.

final propertiesProvider = StreamProvider<List<Property>>((ref) => ref.watch(propertyRepoProvider).watchAll());
final tenantsProvider = StreamProvider<List<Tenant>>((ref) => ref.watch(tenantRepoProvider).watchAll());
final leasesProvider = StreamProvider<List<Lease>>((ref) => ref.watch(leaseRepoProvider).watchAll());
final chargesProvider = StreamProvider<List<RentCharge>>((ref) => ref.watch(chargeRepoProvider).watchAll());
final ledgerProvider = StreamProvider<List<LedgerEntry>>((ref) => ref.watch(ledgerRepoProvider).watchAll());
final maintenanceProvider =
    StreamProvider<List<MaintenanceTicket>>((ref) => ref.watch(maintenanceRepoProvider).watchAll());
final documentsProvider = StreamProvider<List<DocumentItem>>((ref) => ref.watch(documentRepoProvider).watchAll());
final remindersProvider = StreamProvider<List<Reminder>>((ref) => ref.watch(reminderRepoProvider).watchAll());
final notificationsProvider =
    StreamProvider<List<AppNotification>>((ref) => ref.watch(notificationRepoProvider).watchAll());

/// True once every core collection has delivered its first snapshot.
final portfolioReadyProvider = Provider<bool>((ref) => [
      ref.watch(propertiesProvider),
      ref.watch(leasesProvider),
      ref.watch(chargesProvider),
      ref.watch(ledgerProvider),
    ].every((a) => a.hasValue));

/// Lookup helpers.
final propertyByIdProvider = Provider.family<Property?, String>((ref, id) {
  final list = ref.watch(propertiesProvider).value ?? const [];
  for (final p in list) {
    if (p.id == id) return p;
  }
  return null;
});

final tenantByIdProvider = Provider.family<Tenant?, String>((ref, id) {
  final list = ref.watch(tenantsProvider).value ?? const [];
  for (final t in list) {
    if (t.id == id) return t;
  }
  return null;
});
