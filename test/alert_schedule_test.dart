import 'package:flutter_test/flutter_test.dart';
import 'package:landowner/features/leases/domain/lease.dart';
import 'package:landowner/features/leases/domain/rent_charge.dart';
import 'package:landowner/features/notifications/domain/alert_schedule.dart';
import 'package:landowner/features/notifications/domain/app_notification.dart';
import 'package:landowner/features/reminders/domain/reminder.dart';

void main() {
  final now = DateTime(2026, 10, 1, 13, 53);

  List<String> keys(List<Reminder> reminders,
          {List<Lease> leases = const [],
          List<RentCharge> charges = const [],
          NotificationSettings settings = const NotificationSettings()}) =>
      AlertSchedule.build(
        reminders: reminders,
        leases: leases,
        charges: charges,
        properties: const [],
        tenants: const [],
        settings: settings,
        now: now,
      ).map((a) => a.key).toList();

  test('a reminder set one minute ahead is scheduled at that exact minute', () {
    final at = now.add(const Duration(minutes: 1));
    final alerts = AlertSchedule.build(
      reminders: [Reminder(id: 'r1', type: ReminderType.custom, title: 'Test', at: at)],
      leases: const [],
      charges: const [],
      properties: const [],
      tenants: const [],
      settings: const NotificationSettings(),
      now: now,
    );
    expect(alerts, hasLength(1));
    expect(alerts.single.at, at);
    expect(alerts.single.title, 'Test');
    expect(alerts.single.route, '/reminders/r1');
  });

  test('user reminders ignore quiet hours; past, done and muted ones are skipped', () {
    final late = DateTime(2026, 10, 1, 23, 30);
    expect(
      AlertSchedule.build(
        reminders: [Reminder(id: 'r1', type: ReminderType.custom, title: 'Late', at: late)],
        leases: const [],
        charges: const [],
        properties: const [],
        tenants: const [],
        settings: const NotificationSettings(),
        now: now,
      ).single.at,
      late,
    );
    expect(
      keys([
        Reminder(id: 'past', type: ReminderType.custom, title: 'x', at: now.subtract(const Duration(minutes: 1))),
        Reminder(id: 'done', type: ReminderType.custom, title: 'x', at: now.add(const Duration(hours: 1)), done: true),
        Reminder(id: 'mute', type: ReminderType.custom, title: 'x', at: now.add(const Duration(hours: 1)), notify: false),
      ]),
      isEmpty,
    );
  });

  test('repeating reminders schedule their next occurrences', () {
    final first = DateTime(2026, 9, 28, 9);
    final alerts = AlertSchedule.build(
      reminders: [Reminder(id: 'r', type: ReminderType.custom, title: 'Weekly', at: first, repeat: RepeatRule.weekly)],
      leases: const [],
      charges: const [],
      properties: const [],
      tenants: const [],
      settings: const NotificationSettings(),
      now: now,
    );
    expect(alerts.first.at, DateTime(2026, 10, 5, 9));
    expect(alerts, hasLength(6));
  });

  test('rent reminders follow the lease reminder offsets', () {
    final lease = Lease(
      id: 'l1',
      propertyId: 'p1',
      tenantId: 't1',
      monthlyRent: 85000,
      start: DateTime(2026, 10, 1),
      end: DateTime(2027, 9, 30),
      createdAt: now,
      reminderOffsets: const {ReminderOffset.threeDays, ReminderOffset.dueDate},
    );
    final rent = Reminder(
      id: 'rent:p1:20261101',
      sourceKey: 'rent:p1:20261101',
      type: ReminderType.rent,
      title: 'Rent due',
      propertyId: 'p1',
      at: DateTime(2026, 11, 1, 9),
    );
    expect(keys([rent], leases: [lease]), ['n:rent:p1:20261101:3d', 'n:rent:p1:20261101:due']);
    expect(keys([rent], leases: [lease], settings: const NotificationSettings().toggle('rent')), isEmpty);
  });

  test('unpaid rent alerts the morning the grace period ends', () {
    final charge = RentCharge(
      leaseId: 'l1',
      propertyId: 'p1',
      tenantId: 't1',
      dueDate: DateTime(2026, 10, 1),
      amount: 85000,
    );
    final alerts = AlertSchedule.build(
      reminders: const [],
      leases: const [],
      charges: [charge],
      properties: const [],
      tenants: const [],
      settings: const NotificationSettings(),
      now: now,
    );
    expect(alerts.single.at, DateTime(2026, 10, 4, 9));
    expect(alerts.single.route, '/overdue/${charge.id}');
    expect(keys(const [], charges: [charge.markPaid(now, 'Bank')]), isEmpty);
  });

  test('the master switch turns everything off', () {
    expect(
      keys([Reminder(id: 'r', type: ReminderType.custom, title: 'x', at: now.add(const Duration(hours: 1)))],
          settings: const NotificationSettings().toggle('push')),
      isEmpty,
    );
  });
}
