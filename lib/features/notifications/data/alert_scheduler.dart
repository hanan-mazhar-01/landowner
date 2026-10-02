import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/account_deletion.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/utils/clock.dart';
import '../../../shared/providers/collections.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/alert_schedule.dart';
import 'notification_settings_provider.dart';

/// Keeps the device's scheduled notifications in step with reminders, rent
/// charges and notification settings. Signing out clears them.
final alertSchedulerProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  final settings = ref.watch(notificationSettingsProvider);
  final reminders = ref.watch(remindersProvider).value;
  final leases = ref.watch(leasesProvider).value;
  final charges = ref.watch(chargesProvider).value;
  final properties = ref.watch(propertiesProvider).value ?? const [];
  final tenants = ref.watch(tenantsProvider).value ?? const [];

  if (user == null || AccountDeletion.inProgress) {
    unawaited(LocalNotificationService.sync(const []));
    return;
  }
  if (reminders == null || leases == null || charges == null) return;

  // Collections often change together (saving a lease writes charges and
  // reminders) — coalesce into one sync.
  final timer = Timer(const Duration(milliseconds: 600), () {
    if (AccountDeletion.inProgress) return;
    LocalNotificationService.sync(AlertSchedule.build(
      reminders: reminders,
      leases: leases,
      charges: charges,
      properties: properties,
      tenants: tenants,
      settings: settings,
      now: ref.read(clockProvider).now(),
    ));
  });
  ref.onDispose(timer.cancel);
});
