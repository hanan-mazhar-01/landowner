// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landowner/core/data/memory_repository.dart';
import 'package:landowner/features/finance/domain/ledger_entry.dart';
import 'package:landowner/features/notifications/domain/alert_schedule.dart';
import 'package:landowner/features/notifications/domain/app_notification.dart';
import 'package:landowner/features/properties/domain/property.dart';
import 'package:landowner/features/properties/domain/usecases/add_property.dart';
import 'package:landowner/features/reminders/domain/reminder.dart';
import 'package:landowner/shared/data/seed/demo_seed.dart';
import 'package:landowner/shared/providers/collections.dart';
import 'package:landowner/shared/providers/portfolio.dart';
import 'package:landowner/shared/providers/repositories.dart';
import 'package:landowner/shared/providers/usecases.dart';
import 'package:landowner/shared/services/ops_sync.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 150));

ProviderContainer testContainer() {
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

  for (final p in [propertiesProvider, leasesProvider, chargesProvider, ledgerProvider, remindersProvider]) {
    c.listen(p, (_, _) {});
  }
  c.listen(opsSyncProvider, (_, _) {});
  return c;
}

void main() {
  group('Full Feature Verification: Property, Income, Expense, 1-Min Notification', () {
    test('1. Test 1-Minute Scheduled Notification is accurately scheduled', () {
      final now = DateTime.now();
      final oneMinAhead = now.add(const Duration(minutes: 1));

      final reminder = Reminder(
        id: 'test_rem_1',
        type: ReminderType.custom,
        title: 'Check Leases & Rent',
        at: oneMinAhead,
        notify: true,
      );

      final alerts = AlertSchedule.build(
        reminders: [reminder],
        leases: const [],
        charges: const [],
        properties: const [],
        tenants: const [],
        settings: const NotificationSettings(push: true),
        now: now,
      );

      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.at == oneMinAhead && a.title == 'Check Leases & Rent'), isTrue);
      print('✓ 1-Minute notification schedule verified: fires at $oneMinAhead');
    });

    test('2. Test Adding a New Property updates portfolio', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      await settle();

      final initialCount = c.read(propertiesProvider).value?.length ?? 0;
      expect(initialCount, greaterThan(0));

      // Save a new Property
      final newProp = await c.read(savePropertyProvider)(
        const PropertyDraft(
          name: 'Emerald Residency Tower',
          type: PropertyType.apartment,
          status: PropertyStatus.vacant,
          address: '42 Main Boulevard',
          city: 'Karachi',
          country: 'Pakistan',
          postalCode: '75500',
          bedrooms: 3,
          bathrooms: 2,
          areaSqft: 1850,
          purchasePrice: 28000000,
          currentValue: 32000000,
          notes: 'High yield unit on 8th floor',
        ),
      );
      await settle();

      final updatedProps = c.read(propertiesProvider).value!;
      expect(updatedProps.length, initialCount + 1);
      expect(updatedProps.any((p) => p.id == newProp.id && p.name == 'Emerald Residency Tower'), isTrue);

      final summary = c.read(portfolioSummaryProvider);
      expect(summary.count, initialCount + 1);
      print('✓ Property added successfully: ${newProp.name} (ID: ${newProp.id})');
    });

    test('3. Test Adding Income and Expense correctly updates financial ledger & cash flow', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      await settle();

      final today = DateTime.now();
      final beforeCashFlow = c.read(thisMonthProvider);
      final beforeIncome = beforeCashFlow.income;
      final beforeExpense = beforeCashFlow.expense;

      // Add Income: 150,000 Rent
      final income = await c.read(recordEntryProvider)(
        kind: EntryKind.income,
        propertyId: 'p1',
        amount: 150000,
        date: today,
        incomeType: IncomeType.rent,
        title: 'Monthly Rent Payment',
        method: PaymentMethod.bank,
      );
      await settle();
      expect(income.amount, 150000);

      // Add Expense: 25,000 Maintenance
      final expense = await c.read(recordEntryProvider)(
        kind: EntryKind.expense,
        propertyId: 'p1',
        amount: 25000,
        date: today,
        category: ExpenseCategory.maintenance,
        title: 'Air Conditioner Servicing',
        method: PaymentMethod.card,
      );
      await settle();
      expect(expense.amount, 25000);

      // Verify Cash Flow calculation
      final afterCashFlow = c.read(thisMonthProvider);
      expect(afterCashFlow.income, beforeIncome + 150000);
      expect(afterCashFlow.expense, beforeExpense + 25000);
      expect(afterCashFlow.net, (beforeIncome + 150000) - (beforeExpense + 25000));

      print('✓ Income added: +Rs 150,000');
      print('✓ Expense added: -Rs 25,000');
      print('✓ Net Cash Flow verified: Rs ${afterCashFlow.net}');
    });
  });
}
