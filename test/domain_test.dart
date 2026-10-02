import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landowner/core/data/memory_repository.dart';
import 'package:landowner/core/utils/formatters.dart';
import 'package:landowner/features/leases/domain/lease.dart';
import 'package:landowner/features/leases/domain/rent_charge.dart';
import 'package:landowner/features/leases/domain/rent_schedule.dart';
import 'package:landowner/features/leases/domain/usecases/lease_usecases.dart';
import 'package:landowner/features/reminders/domain/reminder_engine.dart';
import 'package:landowner/shared/data/seed/demo_seed.dart';
import 'package:landowner/shared/providers/collections.dart';
import 'package:landowner/shared/providers/portfolio.dart';
import 'package:landowner/shared/providers/repositories.dart';
import 'package:landowner/shared/providers/usecases.dart';
import 'package:landowner/shared/services/ops_sync.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 150));

ProviderContainer container() {
  final demo = DemoSeed.build(DateTime.now());
  final c = ProviderContainer(overrides: [
    propertyRepoProvider.overrideWithValue(MemoryRepository(demo.properties, (e) => e.id)),
    tenantRepoProvider.overrideWithValue(MemoryRepository(demo.tenants, (e) => e.id)),
    leaseRepoProvider.overrideWithValue(MemoryRepository(demo.leases, (e) => e.id)),
    chargeRepoProvider.overrideWithValue(MemoryRepository(demo.charges, (e) => e.id)),
    ledgerRepoProvider.overrideWithValue(MemoryRepository(demo.ledger, (e) => e.id)),
    maintenanceRepoProvider.overrideWithValue(MemoryRepository(demo.maintenance, (e) => e.id)),
    documentRepoProvider.overrideWithValue(MemoryRepository(demo.documents, (e) => e.id)),
    notificationRepoProvider.overrideWithValue(MemoryRepository(demo.notifications, (e) => e.id)),
  ]);
  // Keep the collections and the sync engine alive like the app does.
  for (final p in [propertiesProvider, leasesProvider, chargesProvider, ledgerProvider, remindersProvider]) {
    c.listen(p, (_, _) {});
  }
  c.listen(opsSyncProvider, (_, _) {});
  return c;
}

void main() {
  group('formatters', () {
    test('design money formats', () {
      expect(Money.m(124800000), 'Rs124.8M');
      expect(Money.k(46000), 'Rs46K');
      expect(Money.k(42500), 'Rs42.5K');
      expect(Money.k(-18000), '−Rs18K');
      expect(Money.full(46000), 'Rs46,000');
      expect(Money.compact(1250000), 'Rs1.25M');
      expect(Money.parse('18,500,000'), 18500000);
    });

    test('addMonths handles negatives and month ends', () {
      expect(Dates.addMonths(DateTime(2026, 9, 1), -12), DateTime(2025, 9, 1));
      expect(Dates.addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(Dates.addMonths(DateTime(2026, 3, 15), -14), DateTime(2025, 1, 15));
    });
  });

  test('rent schedule is deterministic and covers the lease', () {
    final l = Lease(
      id: 'L',
      propertyId: 'p',
      tenantId: 't',
      monthlyRent: 100000,
      start: DateTime(2026, 10, 12),
      end: DateTime(2027, 10, 11),
      dueDay: 1,
      createdAt: DateTime(2026),
    );
    final a = RentSchedule.build(l), b = RentSchedule.build(l);
    expect(a.first.dueDate, DateTime(2026, 11, 1));
    expect(a.length, 12);
    expect(a.map((c) => c.id), b.map((c) => c.id));
  });

  test('reminder engine never duplicates on re-derivation', () async {
    final c = container();
    addTearDown(c.dispose);
    await settle();
    final repo = c.read(reminderRepoProvider);
    final first = repo.snapshot.length;
    expect(first, greaterThan(0));
    final keys = repo.snapshot.map((r) => r.sourceKey).toList();
    expect(keys.toSet().length, keys.length);
    // Re-run reconciliation against the current state: nothing new to add.
    final derived = ReminderEngine.derive(ReminderInputs(
      today: DateTime.now(),
      properties: c.read(propertyRepoProvider).snapshot,
      tenants: c.read(tenantRepoProvider).snapshot,
      leases: c.read(leaseRepoProvider).snapshot,
      charges: c.read(chargeRepoProvider).snapshot,
      maintenance: c.read(maintenanceRepoProvider).snapshot,
      documents: c.read(documentRepoProvider).snapshot,
    ));
    final (upserts, deletes) = ReminderEngine.reconcile(repo.snapshot, derived);
    expect(upserts, isEmpty);
    expect(deletes, isEmpty);
  });

  test('new lease → property rented, charges, reminders, notification', () async {
    final c = container();
    addTearDown(c.dispose);
    await settle();
    final today = DateTime.now();
    final notifsBefore = c.read(notificationRepoProvider).snapshot.length;
    final lease = await c.read(createLeaseProvider)(LeaseDraft(
      propertyId: 'p4',
      tenantName: 'Hira Qureshi',
      rent: 110000,
      deposit: 220000,
      start: DateTime(today.year, today.month, today.day),
      end: Dates.addMonths(today, 12),
      dueDay: today.day + 3 > 28 ? 1 : today.day + 3,
      frequency: PaymentFrequency.monthly,
      firstPayment: RentStatus.pending,
      graceDays: 3,
      offsets: {ReminderOffset.threeDays},
    ));
    await settle();
    expect(c.read(metricsForProvider('p4'))!.monthlyRent, 110000);
    expect(c.read(metricsForProvider('p4'))!.statusLabel, 'Occupied');
    expect(c.read(chargeRepoProvider).snapshot.where((x) => x.leaseId == lease.id), isNotEmpty);
    expect(c.read(reminderRepoProvider).snapshot.any((r) => r.sourceKey!.startsWith('rent:p4:')), isTrue);
    expect(c.read(notificationRepoProvider).snapshot.length, greaterThan(notifsBefore));
  });

  test('marking overdue rent paid updates income and clears the alert', () async {
    final c = container();
    addTearDown(c.dispose);
    await settle();
    final overdue = c.read(portfolioSummaryProvider).overdue;
    expect(overdue, hasLength(1));
    final before = c.read(thisMonthProvider).income;
    await c.read(recordRentPaymentProvider)(overdue.single.id);
    await settle();
    expect(c.read(portfolioSummaryProvider).overdue, isEmpty);
    expect(c.read(thisMonthProvider).income, before + overdue.single.amount);
    final alert = c.read(notificationRepoProvider).byId('alert:overdue:${overdue.single.id}');
    expect(alert?.critical, isFalse);
  });
}
