import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/toast.dart';
import '../core/services/local_notification_service.dart';
import '../core/services/push_notification_service.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/notifications/data/alert_scheduler.dart';
import '../features/auth/presentation/preferences_provider.dart';
import '../features/auth/presentation/widgets/app_lock_gate.dart';
import '../shared/services/ops_sync.dart';
import 'router/app_router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

// Each tap is tagged so tapping the same notification twice still navigates.
final _notificationTapsProvider = StreamProvider<(int, String)>(
    (_) => LocalNotificationService.taps.map((r) => (DateTime.now().microsecondsSinceEpoch, r)));

/// A tapped notification's route, held until the user is signed in.
String? _pendingRoute;

class HomelyApp extends ConsumerWidget {
  const HomelyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the reminder / alert engine alive for the whole session.
    ref.watch(opsSyncProvider);
    // Device-scheduled reminder notifications.
    ref.watch(alertSchedulerProvider);
    // Keep FCM push notifications and token sync active.
    ref.watch(pushNotificationServiceProvider);
    final router = ref.watch(routerProvider);

    void open(String route) {
      if (ref.read(currentUserProvider) == null) {
        _pendingRoute = route;
      } else {
        router.push(route);
      }
    }

    ref.listen(_notificationTapsProvider, (_, next) {
      final tap = next.value;
      if (tap != null) open(tap.$2);
    });
    ref.listen(currentUserProvider, (_, user) {
      final route = _pendingRoute;
      if (user == null || route == null) return;
      _pendingRoute = null;
      // Let the redirect to Home settle before opening the target.
      Future<void>.delayed(const Duration(milliseconds: 400), () => router.push(route));
    });
    // Currency / date format are read by static formatters, so rebuild the
    // tree when they change (rare, user-initiated).
    final prefs = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: 'LandOwner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: const Color(0x00000000)),
        child: Stack(children: [
          // Cap text scaling so large accessibility sizes don't break the
          // fixed-height design surfaces, while still honouring the setting.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            // Material surface supplies text defaults and ink for inputs.
            child: Material(
              color: AppColors.background,
              child: AppLockGate(
                child: KeyedSubtree(key: ValueKey('${prefs.currency}|${prefs.dateFormat}'), child: child ?? const SizedBox()),
              ),
            ),
          ),
          const ToastHost(),
        ]),
      ),
    );
  }
}
