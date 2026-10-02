import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/notifications/data/notification_settings_provider.dart';
import 'account_deletion.dart';
import 'local_notification_service.dart';
import 'notification_permission.dart';

/// Top-level background message handler required by `firebase_messaging`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('FCM background message received: ${message.messageId}');
}

/// Remote push (FCM). Reminder notifications are scheduled on the device by
/// [LocalNotificationService]; this handles server-sent messages and keeps the
/// device token registered on the user's profile.
class PushNotificationService {
  PushNotificationService();

  bool _initialized = false;

  Future<void> init(Ref ref) async {
    await LocalNotificationService.init();
    if (_initialized || Firebase.apps.isEmpty) return;
    _initialized = true;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;

      // Foreground messages are shown through the local channel.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final n = message.notification;
        if (n == null || kIsWeb || !ref.read(notificationSettingsProvider).push) return;
        LocalNotificationService.show(
          id: n.hashCode & 0x7fffffff,
          title: n.title,
          body: n.body,
          route: message.data['target']?.toString(),
        );
      });

      // Tapping a remote notification opens its target screen.
      void open(RemoteMessage? m) {
        final target = m?.data['target']?.toString();
        if (target != null && target.startsWith('/')) LocalNotificationService.openRoute(target);
      }

      open(await messaging.getInitialMessage());
      FirebaseMessaging.onMessageOpenedApp.listen(open);

      // Register the token once signed in (permission is asked separately,
      // see NotificationPermission).
      ref.listen(currentUserProvider, (previous, next) {
        if (next != null && previous?.uid != next.uid) _register(next.uid);
      }, fireImmediately: true);

      // Once the user has answered the permission prompt, register the token.
      NotificationPermission.onAsked.listen((_) {
        final user = ref.read(currentUserProvider);
        if (user != null) _register(user.uid);
      });

      messaging.onTokenRefresh.listen((newToken) {
        final user = ref.read(currentUserProvider);
        if (user != null) _saveTokenToFirestore(user.uid, newToken);
      });
    } catch (e) {
      debugPrint('PushNotificationService init note: $e');
    }
  }

  Future<void> _register(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveTokenToFirestore(uid, token);
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String uid, String token) async {
    if (AccountDeletion.inProgress) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmUpdate': FieldValue.serverTimestamp(),
        // Tells the backend this device schedules reminder alerts itself, so
        // the daily job doesn't push duplicates.
        'localReminders': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save FCM token to Firestore: $e');
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService();
  service.init(ref);
  return service;
});
