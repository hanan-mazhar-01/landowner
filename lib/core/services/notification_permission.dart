import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_notification_service.dart';

/// Asks for notification permission once, at a moment the user understands
/// (the onboarding step, or the first visit to Home for existing users),
/// instead of on launch. Shows the system prompt on iOS and Android 13+;
/// older Android versions allow notifications by default.
abstract final class NotificationPermission {
  static const _key = 'notif.permissionAsked';

  static final _asked = StreamController<void>.broadcast();

  /// Fires after the prompt was shown, so the push token can be registered.
  static Stream<void> get onAsked => _asked.stream;

  static Future<bool> wasAsked() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markAsked() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, true);
    } catch (_) {}
  }

  /// Shows the system prompt (where the platform has one).
  static Future<void> request() async {
    await _markAsked();
    await LocalNotificationService.requestPermission();
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      } catch (e) {
        debugPrint('FCM permission note: $e');
      }
    }
    _asked.add(null);
  }

  /// The user chose "Not now" — don't ask again automatically.
  static Future<void> decline() => _markAsked();

  /// For users who never went through onboarding (e.g. signed in on a new
  /// device): ask once.
  static Future<void> requestIfNeverAsked() async {
    if (!await wasAsked()) await request();
  }
}
