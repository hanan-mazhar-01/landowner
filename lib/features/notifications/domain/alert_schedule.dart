import '../../../core/services/local_notification_service.dart';
import '../../../core/utils/formatters.dart';
import '../../leases/domain/lease.dart';
import '../../leases/domain/rent_charge.dart';
import '../../properties/domain/property.dart';
import '../../reminders/domain/reminder.dart';
import '../../tenants/domain/tenant.dart';
import 'app_notification.dart';

/// Turns reminders and rent charges into the exact device notifications to
/// schedule. Pure, so it is unit-testable and deterministic.
abstract final class AlertSchedule {
  /// iOS keeps at most 64 pending local notifications per app.
  static const maxPending = 60;
  static const _repeatOccurrences = 6;

  static List<ScheduledAlert> build({
    required List<Reminder> reminders,
    required List<Lease> leases,
    required List<RentCharge> charges,
    required List<Property> properties,
    required List<Tenant> tenants,
    required NotificationSettings settings,
    required DateTime now,
  }) {
    if (!settings.push) return const [];
    final names = {for (final p in properties) p.id: p.name};
    final people = {for (final t in tenants) t.id: t.name};
    final out = <ScheduledAlert>[];

    void add(String key, DateTime at, String title, String body, String? route, {bool auto = true}) {
      final when = auto && settings.quietHours ? _outsideQuietHours(at) : at;
      if (!when.isAfter(now)) return;
      out.add(ScheduledAlert(key: key, at: when, title: title, body: body, route: route));
    }

    String join(List<String?> parts) => parts.where((s) => s != null && s.isNotEmpty).join(' · ');

    for (final r in reminders) {
      if (r.done || !r.notify) continue;
      final name = names[r.propertyId];
      final route = '/reminders/${Uri.encodeComponent(r.id)}';
      final key = r.sourceKey;

      // Reminders the user set themselves fire at the exact minute chosen.
      if (key == null) {
        final at = _occurrences(r.at, r.repeat, now);
        for (var i = 0; i < at.length; i++) {
          add('r:${r.id}:$i', at[i], r.title, join([r.type.label, name, r.notes]), route, auto: false);
        }
        continue;
      }
      if (key.startsWith('overdue:')) continue; // scheduled from charges below

      if (r.snoozed) {
        add('s:${r.id}', r.at, r.title, join([name, r.amountLabel]), route);
        continue;
      }

      final day = DateTime(r.at.year, r.at.month, r.at.day);
      if (key.startsWith('rent:')) {
        if (!settings.rent) continue;
        final offsets = <ReminderOffset>{
          for (final l in leases)
            if (l.propertyId == r.propertyId) ...l.reminderOffsets,
        };
        for (final o in offsets.isEmpty ? {ReminderOffset.dueDate} : offsets) {
          final title = switch (o.days) {
            0 => 'Rent due today',
            1 => 'Rent due tomorrow',
            _ => 'Rent due in ${o.days} days',
          };
          add('n:${r.id}:${o.key}', day.subtract(Duration(days: o.days)).add(const Duration(hours: 9)), title,
              join([name, r.amountLabel]), route);
        }
      } else if (key.startsWith('lease:')) {
        if (!settings.lease) continue;
        add('n:${r.id}:30d', day.subtract(const Duration(days: 30)).add(const Duration(hours: 9)),
            'Lease ends in 30 days', join([name, 'Time to discuss renewal']), route);
        add('n:${r.id}:due', day.add(const Duration(hours: 9)), 'Lease ends today', join([name]), route);
      } else if (key.startsWith('doc:')) {
        final insurance = r.type == ReminderType.insurance;
        if (!(insurance ? settings.insurance : settings.documents)) continue;
        final what = insurance ? 'Insurance policy' : r.title.replaceAll(' expires', '');
        for (final d in const [30, 7, 0]) {
          final when = d == 0 ? 'expires today' : 'expires in $d days';
          add('n:${r.id}:${d}d', day.subtract(Duration(days: d)).add(const Duration(hours: 10)), '$what $when',
              join([name]), route);
        }
      } else if (key.startsWith('maint:')) {
        if (!settings.maintenance) continue;
        add('n:${r.id}:1d', day.subtract(const Duration(days: 1)).add(const Duration(hours: 9)),
            'Maintenance tomorrow', join([r.title, name]), route);
        add('n:${r.id}:due', r.at, 'Maintenance today', join([r.title, name]), route);
      }
    }

    // Overdue rent — the morning the grace period ends without payment.
    if (settings.payments) {
      for (final c in charges) {
        if (c.isPaid) continue;
        final g = c.graceEnds;
        add('o:${c.id}', DateTime(g.year, g.month, g.day, 9), 'Rent overdue',
            join([names[c.propertyId], people[c.tenantId], Money.full(c.amount)]), '/overdue/${c.id}');
      }
    }

    if (settings.monthlySummary) {
      for (var i = 1; i <= 3; i++) {
        final first = DateTime(now.year, now.month + i, 1, 9);
        final month = Dates.month(DateTime(first.year, first.month - 1));
        add('m:${first.year}${first.month}', first, 'Your $month summary',
            'See income, costs and net cash flow for $month.', '/finance');
      }
    }

    out.sort((a, b) => a.at.compareTo(b.at));
    return out.length > maxPending ? out.sublist(0, maxPending) : out;
  }

  /// Next [_repeatOccurrences] times (from now on) for a repeating reminder.
  static List<DateTime> _occurrences(DateTime first, RepeatRule repeat, DateTime now) {
    if (repeat == RepeatRule.none) return [first];
    DateTime step(DateTime d, int n) => switch (repeat) {
          RepeatRule.daily => DateTime(first.year, first.month, first.day + n, first.hour, first.minute),
          RepeatRule.weekly => DateTime(first.year, first.month, first.day + 7 * n, first.hour, first.minute),
          RepeatRule.monthly => Dates.addMonths(first, n),
          RepeatRule.yearly => Dates.addMonths(first, 12 * n),
          RepeatRule.none => first,
        };
    final out = <DateTime>[];
    for (var n = 0; out.length < _repeatOccurrences && n < 5000; n++) {
      final d = step(first, n);
      if (d.isAfter(now)) out.add(d);
    }
    return out;
  }

  /// Holds automatic alerts that would land between 22:00 and 07:00 until 07:00.
  static DateTime _outsideQuietHours(DateTime at) {
    if (at.hour >= 22) return DateTime(at.year, at.month, at.day + 1, 7);
    if (at.hour < 7) return DateTime(at.year, at.month, at.day, 7);
    return at;
  }
}
