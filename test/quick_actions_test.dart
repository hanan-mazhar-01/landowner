import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landowner/app/app.dart';
import 'package:landowner/core/widgets/net_image.dart';
import 'package:landowner/features/auth/data/local_auth_repository.dart';
import 'package:landowner/features/auth/presentation/auth_providers.dart';
import 'package:landowner/features/shell/presentation/quick_action_overlay.dart';
import 'package:landowner/features/shell/presentation/quick_actions_controller.dart';
import 'package:landowner/shared/data/seed/seed_ops.dart';
import 'package:landowner/shared/forms/form_screen.dart';

import 'test_fonts.dart';

/// Regression: the arc actions (Property, Lease, Income, Expense) must be
/// tappable where they are drawn, not where they started the animation.
void main() {
  setUpAll(() async {
    NetImage.enabled = false;
    await loadAppFonts();
  });

  for (final (label, route) in [
    ('Property', 'Add property'),
    ('Lease', 'Add rental / lease'),
    ('Income', 'Add income'),
    ('Expense', 'Add expense'),
    ('Tenant', 'Add tenant'),
    ('Reminder', 'Add reminder'),
  ]) {
    testWidgets('+ menu → $label opens "$route"', (t) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final auth = LocalAuthRepository(seedUser);
      await t.runAsync(() => auth.signIn(email: 'john@mail.com', password: 'secret1'));
      final c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(auth)]);
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const HomelyApp()));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(seconds: 2));

      c.read(quickActionsProvider.notifier).open();
      await t.pump(const Duration(milliseconds: 16));
      await t.pump(const Duration(seconds: 1));

      final target = find.descendant(of: find.byType(QuickActionOverlay), matching: find.text(label));
      expect(target, findsOneWidget);
      await t.tap(target, warnIfMissed: true);
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(seconds: 1));

      expect(find.byType(FormScreen), findsOneWidget);
      expect(find.text(route), findsOneWidget); // form title

      // Dispose inside the test so the sync engine's wake-up timers are
      // cancelled before the binding checks for pending timers.
      await t.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
