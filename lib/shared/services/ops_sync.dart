import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/account_deletion.dart';
import '../../core/utils/clock.dart';
import '../../features/notifications/data/notification_settings_provider.dart';
import '../../features/notifications/domain/notification_engine.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/reminders/domain/reminder_engine.dart';
import '../providers/collections.dart';
import '../providers/repositories.dart';

/// Keeps reminders and alert notifications in step with the portfolio.
///
/// Watches the source collections; whenever one changes it re-derives and
/// reconciles by deterministic key. With Firebase this same logic runs in a
/// Cloud Function (Firestore triggers + a daily schedule) instead.
final opsSyncProvider = Provider<void>((ref) {
  final props = ref.watch(propertiesProvider).value;
  final tenants = ref.watch(tenantsProvider).value;
  final leases = ref.watch(leasesProvider).value;
  final charges = ref.watch(chargesProvider).value;
  final maint = ref.watch(maintenanceProvider).value;
  final docs = ref.watch(documentsProvider).value;
  final settings = ref.watch(notificationSettingsProvider);
  // Re-run when the user's own reminders change (auto ones are written here,
  // so they're excluded to avoid feedback loops).
  ref.watch(remindersProvider.select((a) => [
        for (final r in a.value ?? const <Reminder>[])
          if (!r.isAuto) '${r.id}|${r.at.millisecondsSinceEpoch}|${r.done}|${r.notify}',
      ].join(',')));
  // The stored reminders and alerts must be loaded too; otherwise existing
  // records look "new" and get overwritten (losing done/read state).
  final storedReady = ref.watch(remindersProvider.select((a) => a.hasValue)) &&
      ref.watch(notificationsProvider.select((a) => a.hasValue));
  if ([props, tenants, leases, charges, maint, docs].contains(null) || !storedReady) return;

  final clock = ref.read(clockProvider);
  final now = clock.now();

  // Wake up when the next user reminder falls due (so it lands in the
  // notification center on time) or at midnight (day rollover).
  var wake = DateTime(now.year, now.month, now.day + 1).difference(now);
  for (final r in ref.read(reminderRepoProvider).snapshot) {
    if (r.isAuto || r.done || !r.at.isAfter(now)) continue;
    final d = r.at.difference(now);
    if (d < wake) wake = d;
  }
  final timer = Timer(wake + const Duration(seconds: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final inputs = ReminderInputs(
    today: clock.today(),
    properties: props!,
    tenants: tenants!,
    leases: leases!,
    charges: charges!,
    maintenance: maint!,
    documents: docs!,
  );

  final reminderRepo = ref.read(reminderRepoProvider);
  final notifRepo = ref.read(notificationRepoProvider);
  final chargeRepo = ref.read(chargeRepoProvider);

  Future<void> sync() async {
    if (AccountDeletion.inProgress) return;
    final (upserts, deletes) = ReminderEngine.reconcile(reminderRepo.snapshot, ReminderEngine.derive(inputs));
    if (upserts.isNotEmpty) await reminderRepo.upsertAll(upserts);
    for (final id in deletes) {
      await reminderRepo.delete(id);
    }

    final alerts = NotificationEngine.derive(inputs, reminderRepo.snapshot, settings, clock.now());
    final fresh = alerts.where((a) => notifRepo.byId(a.id) == null).toList();
    if (fresh.isNotEmpty) await notifRepo.upsertAll(fresh);

    // Resolve overdue alerts whose charge has since been paid.
    for (final n in notifRepo.snapshot) {
      if (!n.critical || !n.id.startsWith('alert:overdue:')) continue;
      final charge = chargeRepo.byId(n.id.substring('alert:overdue:'.length));
      if (charge != null && charge.isPaid) await notifRepo.upsert(n.copyWith(critical: false, unread: false));
    }
  }

  // Defer writes until after this build so we never mutate during a read.
  scheduleMicrotask(() async {
    try {
      await sync();
    } catch (e) {
      // Offline or rejected writes are retried on the next change.
      debugPrint('Ops sync note: $e');
    }
  });
});
