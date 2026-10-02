import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_notification.dart';

/// User notification preferences, persisted on the device.
class NotificationSettingsController extends Notifier<NotificationSettings> {
  static const _kFlags = 'notif.flags';
  static const _kTiming = 'notif.timing';

  @override
  NotificationSettings build() {
    _restore();
    return const NotificationSettings();
  }

  Future<void> _restore() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final flags = sp.getStringList(_kFlags);
      final timing = sp.getStringList(_kTiming);
      if (flags == null && timing == null) return;
      final on = flags?.toSet();
      final d = state;
      bool f(String key, bool fallback) => on == null ? fallback : on.contains(key);
      state = NotificationSettings(
        push: f('push', d.push),
        rent: f('rent', d.rent),
        payments: f('pay', d.payments),
        lease: f('lease', d.lease),
        maintenance: f('maint', d.maintenance),
        documents: f('docs', d.documents),
        insurance: f('ins', d.insurance),
        monthlySummary: f('fin', d.monthlySummary),
        quietHours: f('quiet', d.quietHours),
        defaultTiming: timing?.toSet() ?? d.defaultTiming,
      );
    } catch (e) {
      debugPrint('Notification settings restore failed: $e');
    }
  }

  Future<void> _save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setStringList(_kFlags, [for (final e in state.toMap().entries) if (e.value) e.key]);
      await sp.setStringList(_kTiming, state.defaultTiming.toList());
    } catch (e) {
      debugPrint('Notification settings save failed: $e');
    }
  }

  void toggle(String key) {
    state = state.toggle(key);
    _save();
  }

  void toggleTiming(String key) {
    state = state.toggleTiming(key);
    _save();
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsController, NotificationSettings>(NotificationSettingsController.new);
