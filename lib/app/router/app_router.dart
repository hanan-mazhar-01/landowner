import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai/presentation/ask_portfolio_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/auth_screens.dart';
import '../../features/auth/presentation/location_setup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/leases/presentation/overdue_rent_screen.dart';
import '../../features/legal/presentation/legal_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/notifications/presentation/notification_center_screen.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../../features/properties/presentation/portfolio_screen.dart';
import '../../features/properties/presentation/property_detail_screen.dart';
import '../../features/reminders/presentation/reminder_detail_screen.dart';
import '../../features/shell/presentation/homely_shell.dart';
import '../../shared/forms/form_route.dart';
import 'ops_routes.dart';
import 'page_transitions.dart';
import 'routes.dart';

StatefulShellBranch _tab(String path, Widget screen) =>
    StatefulShellBranch(routes: [GoRoute(path: path, pageBuilder: (_, s) => NoTransitionPage(child: screen))]);

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  GoRoute page(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, parentNavigatorKey: rootKey, pageBuilder: (_, s) => homelyPage(s, build(s)));

  const unauthOnlyPaths = {
    Routes.welcome,
    Routes.signIn,
    Routes.signUp,
    Routes.forgot,
  };

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    // watch (not read): keeps the auth listener active — Riverpod pauses
    // providers that nobody listens to.
    refreshListenable: ref.watch(authRefreshProvider),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final uriPath = state.uri.path;
      final isLegal = loc == Routes.privacyPolicy ||
          loc == Routes.termsOfService ||
          loc.startsWith(Routes.privacyPolicy) ||
          loc.startsWith(Routes.termsOfService) ||
          uriPath == Routes.privacyPolicy ||
          uriPath == Routes.termsOfService ||
          uriPath.startsWith(Routes.privacyPolicy) ||
          uriPath.startsWith(Routes.termsOfService);

      if (isLegal) {
        debugPrint('[GoRouter redirect] Allow legal route: loc=$loc, uri=$uriPath');
        return null;
      }

      final auth = ref.read(authStateProvider);
      if (auth.isLoading && !auth.hasValue) return loc == Routes.splash ? null : Routes.splash;
      final signedIn = auth.value != null;
      if (!signedIn) {
        if (unauthOnlyPaths.contains(loc) || unauthOnlyPaths.contains(uriPath)) return null;
        debugPrint('[GoRouter redirect] Unauthenticated -> welcome (from $loc)');
        return Routes.welcome;
      }
      if (loc == Routes.locationSetup || uriPath == Routes.locationSetup) return null;
      if ((loc == Routes.signUp || uriPath == Routes.signUp) && signedIn) return Routes.locationSetup;
      if (unauthOnlyPaths.contains(loc) || unauthOnlyPaths.contains(uriPath) || loc == Routes.splash) {
        debugPrint('[GoRouter redirect] Authenticated on unauth/splash -> home (from $loc)');
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, pageBuilder: (_, s) => NoTransitionPage(child: const SplashScreen())),
      page(Routes.welcome, (_) => const WelcomeScreen()),
      page(Routes.signIn, (_) => const SignInScreen()),
      page(Routes.signUp, (_) => const SignUpScreen()),
      page(Routes.locationSetup, (_) => const LocationSetupScreen()),
      page(Routes.forgot, (_) => const ForgotPasswordScreen()),
      page(Routes.privacyPolicy, (_) => const LegalScreen(docType: LegalDocType.privacyPolicy)),
      page(Routes.termsOfService, (_) => const LegalScreen(docType: LegalDocType.termsOfService)),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomelyShell(shell: shell),
        branches: [
          _tab(Routes.home, const HomeScreen()),
          _tab(Routes.properties, const PortfolioScreen()),
          _tab(Routes.finance, const FinanceScreen()),
          _tab(Routes.more, const MoreScreen()),
        ],
      ),
      page('/properties/:id', (s) => PropertyDetailScreen(
            id: s.pathParameters['id']!,
            initialTab: switch (s.uri.queryParameters['tab']) { 'rent' => 1, 'costs' => 2, _ => 0 },
          )),
      page(Routes.notifications, (_) => const NotificationCenterScreen()),
      page(Routes.notificationSettings, (_) => const NotificationSettingsScreen()),
      page('/reminders/:id', (s) => ReminderDetailScreen(id: Uri.decodeComponent(s.pathParameters['id']!))),
      page('/overdue/:id', (s) => OverdueRentScreen(chargeId: s.pathParameters['id']!)),
      page(Routes.ai, (_) => const AskPortfolioScreen()),
      page('/add/:form', (s) => FormRoute(
            form: s.pathParameters['form']!,
            propertyId: s.uri.queryParameters['property'],
            editId: s.uri.queryParameters['edit'],
          )),
      ...opsRoutes(page),
    ],
  );
});
