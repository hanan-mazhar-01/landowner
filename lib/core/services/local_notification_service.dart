import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One notification to deliver at an exact moment.
@immutable
class ScheduledAlert {
  const ScheduledAlert({required this.key, required this.at, required this.title, required this.body, this.route});

  /// Stable identity (e.g. `rent:p1:2026101:3d`) — rescheduling the same key
  /// replaces the pending notification instead of duplicating it.
  final String key;
  final DateTime at;
  final String title;
  final String body;

  /// App route opened when the notification is tapped.
  final String? route;

  int get id => notificationIdFor(key);
}

/// Stable 31-bit id from a string key (FNV-1a), so ids survive restarts.
int notificationIdFor(String key) {
  var h = 0x811c9dc5;
  for (final c in key.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

/// Device-side notifications: the reminders a user sets fire at their exact
/// time even when the app is closed or offline. Remote pushes (FCM) reuse the
/// same channel for foreground display.
abstract final class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'landowner_reminders',
    'LandOwner Reminders & Alerts',
    description: 'Rent due dates, overdue payments, lease and document expiries, and your own reminders.',
    importance: Importance.high,
    playSound: true,
  );

  static NotificationDetails get details => NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'ic_stat_notify',
          color: const Color(0xFF304BC7),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentList: true, presentSound: true),
      );

  /// Routes from tapped notifications; the app shell navigates to them.
  static final _taps = StreamController<String>.broadcast();
  static Stream<String> get taps => _taps.stream;

  /// Opens [route] in the running app.
  static void openRoute(String route) => _taps.add(route);

  static Completer<void>? _init;

  static Future<void> init() {
    if (_init != null) return _init!.future;
    final c = _init = Completer<void>();
    () async {
      try {
        tzdata.initializeTimeZones();
        await plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_stat_notify'),
            // Permission is asked once the user is signed in, not on launch.
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
          onDidReceiveNotificationResponse: (r) {
            final route = r.payload;
            if (route != null && route.startsWith('/')) _taps.add(route);
          },
        );
        await plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
        final launch = await plugin.getNotificationAppLaunchDetails();
        final payload = launch?.notificationResponse?.payload;
        if ((launch?.didNotificationLaunchApp ?? false) && payload != null && payload.startsWith('/')) {
          // Let the app shell subscribe before delivering the cold-start tap.
          Future<void>.delayed(const Duration(milliseconds: 800), () => _taps.add(payload));
        }
      } catch (e) {
        debugPrint('LocalNotificationService init note: $e');
      }
      c.complete();
    }();
    return c.future;
  }

  /// Asks for permission to show notifications (iOS / Android 13+).
  static Future<void> requestPermission() async {
    await init();
    try {
      await plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission note: $e');
    }
  }

  static Future<void> show({required int id, String? title, String? body, String? route}) async {
    await init();
    await plugin.show(id: id, title: title, body: body, notificationDetails: details, payload: route);
  }

  /// Makes the pending set exactly [alerts]: cancels anything no longer wanted
  /// and (re)schedules the rest. Delivered notifications are left alone.
  static Future<void> sync(List<ScheduledAlert> alerts) async {
    await init();
    try {
      final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final exact = await android?.canScheduleExactNotifications() ?? true;
      final mode = exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

      final wanted = {for (final a in alerts) a.id: a};
      for (final p in await plugin.pendingNotificationRequests()) {
        if (!wanted.containsKey(p.id)) await plugin.cancel(id: p.id);
      }
      final now = DateTime.now();
      for (final a in wanted.values) {
        if (!a.at.isAfter(now)) continue;
        await plugin.zonedSchedule(
          id: a.id,
          title: a.title,
          body: a.body,
          scheduledDate: tz.TZDateTime.from(a.at.toUtc(), tz.UTC),
          notificationDetails: details,
          androidScheduleMode: mode,
          payload: a.route,
        );
      }
    } catch (e) {
      debugPrint('Scheduling notifications failed: $e');
    }
  }
}
