// Renders every major screen at iPhone 14 size (390×844 @3x) to PNGs under
// test/goldens/ for visual review against the Claude Design file.
//
//   PREVIEW=1 flutter test test/screens_preview_test.dart --update-goldens
//
// Skipped in normal runs: the images depend on today's date.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:landowner/app/app.dart';
import 'package:landowner/app/router/app_router.dart';
import 'package:landowner/core/widgets/net_image.dart';
import 'package:landowner/features/auth/data/local_auth_repository.dart';
import 'package:landowner/features/auth/presentation/auth_providers.dart';
import 'package:landowner/features/shell/presentation/quick_actions_controller.dart';
import 'package:landowner/shared/data/seed/seed_ops.dart';

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }

  await family('Manrope', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/Manrope-$w.ttf',
  ]);
  // Stand-in for SF Pro (body font) in previews only.
  const lato = '/usr/share/fonts/truetype/lato';
  final body = [for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) '$lato/Lato-$w.ttf'];
  await family('Roboto', body);
}

final _skip = !Platform.environment.containsKey('PREVIEW');

void main() {
  setUpAll(() async {
    if (_skip) return;
    NetImage.enabled = false;
    await _loadFonts();
  });

  Future<(ProviderContainer, GoRouter)> boot(WidgetTester t, {bool signedIn = true}) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(t.view.reset);
    final auth = LocalAuthRepository(seedUser);
    if (signedIn) await t.runAsync(() => auth.signIn(email: 'john@mail.com', password: 'secret1'));
    final c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(auth)]);
    addTearDown(c.dispose);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const HomelyApp()));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(seconds: 2));
    return (c, c.read(routerProvider));
  }

  Future<void> shot(WidgetTester t, GoRouter r, String route, String name, {bool push = false}) async {
    push ? r.push(route) : r.go(route);
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(seconds: 1));
    await expectLater(find.byType(HomelyApp), matchesGoldenFile('goldens/$name.png'));
    if (push && r.canPop()) {
      r.pop();
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('welcome', skip: _skip, (t) async {
    final (_, r) = await boot(t, signedIn: false);
    await t.pump(const Duration(seconds: 1));
    await expectLater(find.byType(HomelyApp), matchesGoldenFile('goldens/01_welcome.png'));
    r.push('/sign-in');
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(seconds: 1));
    if (find.byType(EditableText).evaluate().isNotEmpty) {
      await t.enterText(find.byType(EditableText).last, 'secret1');
      await t.pump(const Duration(milliseconds: 300));
    }
    await expectLater(find.byType(HomelyApp), matchesGoldenFile('goldens/02_sign_in.png'));
  });

  testWidgets('tabs and detail screens', skip: _skip, (t) async {
    final (c, r) = await boot(t);
    await shot(t, r, '/home', '07_home');
    await t.drag(find.byType(CustomScrollView).hitTestable().first, const Offset(0, -700));
    await t.pump(const Duration(seconds: 1));
    await expectLater(find.byType(HomelyApp), matchesGoldenFile('goldens/07_home_scrolled.png'));
    await shot(t, r, '/properties', '10_portfolio');
    // Deck mid-swipe frames (held gesture, no release).
    final deck = find.byType(PageView).first;
    final g = await t.startGesture(t.getCenter(deck));
    for (final (i, pct) in [(1, .3), (2, .6), (3, .9)]) {
      await g.moveTo(t.getCenter(deck) - Offset(288 * pct, 0));
      await t.pump(const Duration(milliseconds: 16));
      await expectLater(find.byType(HomelyApp), matchesGoldenFile('goldens/10d_deck_drag_$i.png'));
    }
    await g.up();
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.text('House').first);
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(seconds: 1));
    await expectLater(find.byType(HomelyApp), matchesGoldenFile('goldens/10b_portfolio_house.png'));
    await t.tap(find.text('All').first);
    await t.pump(const Duration(milliseconds: 400));
    await shot(t, r, '/finance', '21_finance');
    await shot(t, r, '/more', '46_more');
    c.read(quickActionsProvider.notifier).open();
    await t.pump(const Duration(milliseconds: 16));
    await t.pump(const Duration(seconds: 1));
    await expectLater(find.byType(HomelyApp), matchesGoldenFile('goldens/00_quick_actions.png'));
    c.read(quickActionsProvider.notifier).close();
    await t.pump(const Duration(seconds: 1));
    await shot(t, r, '/properties/p2', '12_detail_luxe', push: true);
    await shot(t, r, '/properties/p4', '12_detail_vacant', push: true);
    await shot(t, r, '/notifications', '08_notifications', push: true);
    await shot(t, r, '/notifications/settings', '47_nsettings', push: true);
    await shot(t, r, '/ai', '45_ai', push: true);
    await shot(t, r, '/add/property', '50_form_property', push: true);
    await shot(t, r, '/add/expense', '51_form_expense', push: true);
    await shot(t, r, '/tenants', '60_tenants', push: true);
    await shot(t, r, '/tenants/l2', '62_tenant_detail', push: true);
    await shot(t, r, '/finance/payments', '63_payments', push: true);
    await shot(t, r, '/finance/payments/l2_202609', '64_payment_detail', push: true);
    await shot(t, r, '/maintenance', '65_maintenance', push: true);
    await shot(t, r, '/maintenance/m5', '66_maintenance_detail', push: true);
    await shot(t, r, '/documents', '67_documents', push: true);
    await shot(t, r, '/documents/d_p2_ins', '68_document_detail', push: true);
    await shot(t, r, '/finance/reports', '69_reports', push: true);
    await shot(t, r, '/finance/reports/portfolio', '70_report_detail', push: true);
    await shot(t, r, '/profile', '71_profile', push: true);
    await shot(t, r, '/add/lease?edit=l1', '72_edit_lease', push: true);
    await shot(t, r, '/finance/cash-flow', '73_cash_flow', push: true);
    await shot(t, r, '/finance/transactions', '74_transactions', push: true);
    await shot(t, r, '/privacy-policy', '75_privacy_policy', push: true);
    await shot(t, r, '/terms-of-service', '76_terms_of_service', push: true);
    await shot(t, r, '/profile/delete', '77_delete_account', push: true);
    await shot(t, r, '/finance', '21_finance_chips');
  });
}
