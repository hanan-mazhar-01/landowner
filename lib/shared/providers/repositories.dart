import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/firestore_repository.dart';
import '../../core/data/memory_repository.dart';
import '../../core/data/repository.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/documents/domain/document_item.dart';
import '../../features/finance/domain/ledger_entry.dart';
import '../../features/leases/domain/lease.dart';
import '../../features/leases/domain/rent_charge.dart';
import '../../features/maintenance/domain/maintenance_ticket.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/properties/domain/property.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/tenants/domain/tenant.dart';
import '../data/seed/demo_seed.dart';

/// Demo dataset, generated once per app launch relative to "now".
final demoSeedProvider = Provider<DemoSeed>((_) => DemoSeed.build(DateTime.now()));

/// Cancels the Firestore listener when the provider rebuilds (sign-out /
/// account switch) so stale snapshots never leak between users.
FirestoreRepository<T> _disposing<T>(Ref ref, FirestoreRepository<T> repo) {
  ref.onDispose(repo.dispose);
  return repo;
}

/// Resolves user subcollection in Firestore if Firebase is active and user is signed in.
CollectionReference<Map<String, dynamic>>? _userCollection(Ref ref, String name) {
  if (Firebase.apps.isEmpty) return null;
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection(name);
}

final propertyRepoProvider = Provider<Repository<Property>>((ref) {
  final col = _userCollection(ref, 'properties');
  if (col != null) {
    return _disposing(ref, FirestoreRepository<Property>(
      collection: col,
      fromMap: Property.fromMap,
      toMap: (p) => p.toMap(),
      idOf: (p) => p.id,
    ));
  }
  return MemoryRepository(const <Property>[], (e) => e.id);
});

final tenantRepoProvider = Provider<Repository<Tenant>>((ref) {
  final col = _userCollection(ref, 'tenants');
  if (col != null) {
    return _disposing(ref, FirestoreRepository<Tenant>(
      collection: col,
      fromMap: Tenant.fromMap,
      toMap: (t) => t.toMap(),
      idOf: (t) => t.id,
    ));
  }
  return MemoryRepository(const <Tenant>[], (e) => e.id);
});

final leaseRepoProvider = Provider<Repository<Lease>>((ref) {
  final col = _userCollection(ref, 'leases');
  if (col != null) {
    return _disposing(ref, FirestoreRepository<Lease>(
      collection: col,
      fromMap: Lease.fromMap,
      toMap: (l) => l.toMap(),
      idOf: (l) => l.id,
    ));
  }
  return MemoryRepository(const <Lease>[], (e) => e.id);
});

final chargeRepoProvider = Provider<Repository<RentCharge>>((ref) {
  final col = _userCollection(ref, 'charges');
  if (col != null) {
    return _disposing(ref, FirestoreRepository<RentCharge>(
      collection: col,
      fromMap: RentCharge.fromMap,
      toMap: (c) => c.toMap(),
      idOf: (c) => c.id,
    ));
  }
  return MemoryRepository(const <RentCharge>[], (e) => e.id);
});

final ledgerRepoProvider = Provider<Repository<LedgerEntry>>((ref) {
  final col = _userCollection(ref, 'ledger');
  if (col != null) {
    return _disposing(ref, FirestoreRepository<LedgerEntry>(
      collection: col,
      fromMap: LedgerEntry.fromMap,
      toMap: (e) => e.toMap(),
      idOf: (e) => e.id,
    ));
  }
  return MemoryRepository(const <LedgerEntry>[], (e) => e.id);
});

final maintenanceRepoProvider = Provider<Repository<MaintenanceTicket>>(
    (ref) {
  final col = _userCollection(ref, 'maintenance');
  if (col != null) {
    return _disposing(ref, FirestoreRepository<MaintenanceTicket>(
      collection: col,
      fromMap: MaintenanceTicket.fromMap,
      toMap: (m) => m.toMap(),
      idOf: (m) => m.id,
    ));
  }
  return MemoryRepository(const <MaintenanceTicket>[], (e) => e.id);
});

final documentRepoProvider = Provider<Repository<DocumentItem>>((ref) {
  final col = _userCollection(ref, 'documents');
  if (col != null) {
    return _disposing(ref, FirestoreRepository<DocumentItem>(
      collection: col,
      fromMap: DocumentItem.fromMap,
      toMap: (d) => d.toMap(),
      idOf: (d) => d.id,
    ));
  }
  return MemoryRepository(const <DocumentItem>[], (e) => e.id);
});

final reminderRepoProvider = Provider<Repository<Reminder>>((ref) {
  final col = _userCollection(ref, 'reminders');
  if (col != null) {
    return _disposing(ref, FirestoreRepository<Reminder>(
      collection: col,
      fromMap: Reminder.fromMap,
      toMap: (r) => r.toMap(),
      idOf: (r) => r.id,
    ));
  }
  return MemoryRepository(const <Reminder>[], (e) => e.id);
});

final notificationRepoProvider = Provider<Repository<AppNotification>>((ref) {
  final col = _userCollection(ref, 'notifications');
  if (col != null) {
    return _disposing(ref, FirestoreRepository<AppNotification>(
      collection: col,
      fromMap: AppNotification.fromMap,
      toMap: (n) => n.toMap(),
      idOf: (n) => n.id,
    ));
  }
  return MemoryRepository(const <AppNotification>[], (e) => e.id);
});
