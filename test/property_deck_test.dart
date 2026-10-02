import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landowner/features/properties/presentation/widgets/carousel/deck_pose.dart';
import 'package:landowner/features/properties/presentation/widgets/carousel/property_stack_carousel.dart';

void main() {
  const layout = DeckLayout(viewportWidth: 390, cardWidth: 288, cardHeight: 369);

  group('DeckLayout', () {
    test('the active card sits flat and fully visible', () {
      final p = layout.pose(0);
      expect(p.dx, closeTo(0, 1e-9));
      expect(p.rotation, closeTo(0, 1e-9));
      expect(p.scale, closeTo(1, 1e-9));
      expect(p.opacity, closeTo(1, 1e-9));
    });

    test('cards further back are smaller and fainter; the 4th is hidden', () {
      final poses = [for (var d = 0; d <= 3; d++) layout.pose(d.toDouble())];
      for (var i = 1; i < poses.length; i++) {
        expect(poses[i].scale, lessThan(poses[i - 1].scale));
        expect(poses[i].opacity, lessThan(poses[i - 1].opacity));
      }
      expect(poses.last.opacity, 0);
    });

    test('poses are continuous through the active position (no jump on swipe)', () {
      final a = layout.pose(-0.0001), b = layout.pose(0.0001);
      expect(a.dx, closeTo(b.dx, 1));
      expect(a.scale, closeTo(b.scale, 0.01));
      expect(a.opacity, closeTo(b.opacity, 0.01));
    });
  });

  group('DeckSizing', () {
    for (final (w, h) in [(320.0, 568.0), (390.0, 844.0), (430.0, 932.0), (820.0, 1180.0)]) {
      test('card fits a ${w.toInt()}×${h.toInt()} screen', () {
        final s = DeckSizing.of(w, h);
        expect(s.cardWidth, lessThanOrEqualTo(w));
        expect(s.cardHeight, lessThanOrEqualTo(h * 0.5 + 0.01));
        expect(s.stageHeight, greaterThan(s.cardHeight));
      });
    }
  });

  group('DeckIndicator', () {
    Widget host(Widget child) => Directionality(textDirection: TextDirection.ltr, child: Center(child: child));

    testWidgets('hidden for a single card', (t) async {
      await t.pumpWidget(host(const DeckIndicator(count: 1, index: 0)));
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('dots for up to 7 cards', (t) async {
      await t.pumpWidget(host(const DeckIndicator(count: 4, index: 1)));
      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('a counter beyond 7 cards', (t) async {
      await t.pumpWidget(host(const DeckIndicator(count: 12, index: 2)));
      expect(find.text('03 / 12'), findsOneWidget);
    });
  });
}
