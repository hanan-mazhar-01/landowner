import '../../../core/utils/formatters.dart';
import '../../leases/domain/rent_charge.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/domain/reminder_engine.dart';
import 'app_notification.dart';

/// Derives alert notifications from live state. Ids are deterministic
/// (`alert:overdue:{chargeId}` …) so each alert is raised exactly once.
abstract final class NotificationEngine {
  static List<AppNotification> derive(
    ReminderInputs i,
    List<Reminder> reminders,
    NotificationSettings settings,
    DateTime now,
  ) {
    final props = {for (final p in i.properties) p.id: p};
    final tenants = {for (final t in i.tenants) t.id: t};
    final leases = {for (final l in i.leases) l.id: l};
    final out = <AppNotification>[];
    DateTime capped(DateTime d) => d.isAfter(now) ? now : d;
    final today = i.today;

    if (settings.payments) {
      for (final c in i.charges) {
        if (c.statusOn(i.today) != RentStatus.overdue) continue;
        final p = props[c.propertyId];
        final unit = leases[c.leaseId]?.unitLabel;
        out.add(AppNotification(
          id: 'alert:overdue:${c.id}',
          category: NotificationCategory.rent,
          title: 'Rent overdue',
          body: [
            '${p?.name ?? ''}${unit == null ? '' : ' $unit'}',
            tenants[c.tenantId]?.name ?? '',
            Money.full(c.amount),
          ].where((s) => s.isNotEmpty).join(' · '),
          createdAt: capped(DateTime(c.graceEnds.year, c.graceEnds.month, c.graceEnds.day, 9)),
          target: '/overdue/${c.id}',
          propertyId: c.propertyId,
          critical: true,
        ));
      }
    }

    for (final r in reminders) {
      // Overdue reminders are covered by the "Rent overdue" alert above.
      if (r.done || !r.notify || (r.sourceKey?.startsWith('overdue:') ?? false)) continue;
      // Reminders the user set appear once their time arrives (the device
      // notification fires at the same moment).
      if (!r.isAuto) {
        if (r.at.isAfter(now) || now.difference(r.at).inDays > 7) continue;
        out.add(AppNotification(
          id: 'alert:${r.id}',
          category: switch (r.type) {
            ReminderType.rent => NotificationCategory.rent,
            ReminderType.lease => NotificationCategory.lease,
            ReminderType.maintenance => NotificationCategory.maintenance,
            ReminderType.insurance || ReminderType.document => NotificationCategory.documents,
            _ => NotificationCategory.property,
          },
          title: r.title,
          body: [r.type.label, props[r.propertyId]?.name ?? ''].where((s) => s.isNotEmpty).join(' · '),
          createdAt: r.at,
          target: '/reminders/${Uri.encodeComponent(r.id)}',
          propertyId: r.propertyId,
        ));
        continue;
      }
      final days = DateTime(r.at.year, r.at.month, r.at.day).difference(today).inDays;
      final name = props[r.propertyId]?.name ?? '';
      final (NotificationCategory cat, bool enabled, int window, String title) = switch (r.type) {
        ReminderType.rent => (NotificationCategory.rent, settings.rent, 3, 'Rent due ${_inDays(days)}'),
        ReminderType.maintenance =>
          (NotificationCategory.maintenance, settings.maintenance, 1, 'Maintenance scheduled ${_inDays(days)}'),
        ReminderType.insurance =>
          (NotificationCategory.documents, settings.insurance, 30, 'Insurance expires ${_inDays(days)}'),
        ReminderType.document =>
          (NotificationCategory.documents, settings.documents, 30, '${r.title} ${_inDays(days)}'),
        ReminderType.lease => (NotificationCategory.lease, settings.lease, 90, 'Lease expires ${_inDays(days)}'),
        _ => (NotificationCategory.property, true, 0, r.title),
      };
      if (!enabled || days < 0 || days > window) continue;
      out.add(AppNotification(
        id: 'alert:${r.id}',
        category: cat,
        title: title,
        body: [
          if (r.type == ReminderType.maintenance) r.title,
          name,
          if (r.amountLabel.isNotEmpty && r.type == ReminderType.rent) r.amountLabel,
        ].where((s) => s.isNotEmpty).join(' · '),
        // Raised now — never back-dated to before the record existed.
        createdAt: now,
        target: '/reminders/${Uri.encodeComponent(r.id)}',
        propertyId: r.propertyId,
      ));
    }
    return out;
  }

  static String _inDays(int d) => switch (d) { 0 => 'today', 1 => 'tomorrow', _ => 'in $d days' };
}
