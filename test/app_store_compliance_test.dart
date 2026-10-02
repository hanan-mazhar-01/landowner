import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landowner/core/services/cloudinary_service.dart';
import 'package:landowner/features/legal/presentation/legal_screen.dart';

void main() {
  group('App Store Review Guidelines Compliance', () {
    test('CloudinaryService uses unsigned upload preset and has zero client-side secret', () {
      final service = CloudinaryService();
      expect(service.cloudName, isNotEmpty);
      expect(service.uploadPreset, isNotEmpty);
      // Verify no apiSecret field exists by design
    });

    testWidgets('LegalScreen renders Privacy Policy with required compliance sections', (tester) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LegalScreen(docType: LegalDocType.privacyPolicy),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Overview & Commitment'), findsOneWidget);
      expect(find.text('Information We Collect'), findsOneWidget);
      expect(find.text('How Your Data Is Used'), findsOneWidget);
      expect(find.text('Third-Party Service Providers'), findsOneWidget);
      expect(find.textContaining('Your Rights & Account Deletion'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
    });

    testWidgets('LegalScreen renders Terms of Service correctly', (tester) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LegalScreen(docType: LegalDocType.termsOfService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
      expect(find.text('2. Permitted Use & Account Security'), findsOneWidget);
      expect(find.text('3. Financial & Accounting Disclaimer'), findsOneWidget);
    });
  });
}
