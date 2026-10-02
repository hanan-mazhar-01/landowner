import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../shared/widgets/sub_page.dart';

enum LegalDocType { privacyPolicy, termsOfService }

/// The installed app version (e.g. "1.0.0 (3)"), read from the platform.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty ? info.version : '${info.version} (${info.buildNumber})';
});

class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key, required this.docType});

  final LegalDocType docType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivacy = docType == LegalDocType.privacyPolicy;
    final version = ref.watch(appVersionProvider).value;
    final title = isPrivacy ? 'Privacy Policy' : 'Terms of Service';
    final subtitle = isPrivacy
        ? 'How LandOwner collects, uses and protects your data.'
        : 'The agreement between you and LandOwner.';

    return SubPage(
      title: title,
      subtitle: subtitle,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.navClearance),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              isPrivacy ? _privacyPolicyContent(version) : _termsOfServiceContent(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _privacyPolicyContent(String? version) {
    return [
      _section(
        'Overview & Commitment',
        'LandOwner ("we", "us", "our") is committed to respecting your privacy and protecting the confidentiality of your property management records. We operate on a strict privacy-first model: your data belongs entirely to you and is never sold, rented, or monetized.',
      ),
      _section(
        'Information We Collect',
        '• Account Credentials: Full name, email address, password hash (via Firebase Authentication), and third-party authentication identifiers (Apple ID, Google ID).\n'
        '• Property & Real Estate Information: Property names, addresses, photos, unit counts, square footage, purchase costs, valuations, and mortgages.\n'
        '• Tenant & Lease Records: Tenant names, email addresses, phone numbers, emergency contact details, lease dates, rent amounts, and deposit amounts.\n'
        '• Financial Data: Rent payment receipts, operating expense records, income logs, and receipt images.\n'
        '• Documents & Maintenance: Uploaded inspection certificates, deeds, contracts, maintenance ticket logs, and contractor contact notes.\n'
        '• Device & Notifications: Firebase Cloud Messaging (FCM) tokens and Apple Push Notification service (APNs) device tokens used exclusively to deliver rent due, document expiration, and urgent maintenance alerts.',
      ),
      _section(
        'How Your Data Is Used',
        'We use your information exclusively to:\n'
        '1. Provide property management, rent tracking, ledger reporting, and notification services.\n'
        '2. Process automated payment reminders and lease expiration alerts.\n'
        '3. Secure your account and authenticate access (including optional local biometric authentication via Face ID / Touch ID).\n'
        '4. Generate downloadable PDF and CSV portfolio reports upon your explicit request.',
      ),
      _section(
        'Third-Party Service Providers',
        'To provide reliable cloud synchronization, we share data solely with trusted infrastructure providers governed by strict data processing agreements:\n'
        '• Google Cloud & Firebase: Cloud Firestore database hosting, Authentication, Cloud Functions, and Cloud Messaging.\n'
        '• Cloudinary: Encrypted storage and content delivery for uploaded property photos, receipt scans, and document attachments.\n'
        '• Apple: Sign in with Apple authentication and APNs push notification infrastructure.\n'
        '• Device location: Only if you allow it during setup, your approximate location is read once and turned into a city and country by your device\'s built-in geocoding service (Apple or Google) to suggest your currency. Only the city, country and currency you confirm are saved; your coordinates are not stored. You can choose them manually instead.',
      ),
      _section(
        'Data Security & Biometrics',
        'All communications between the LandOwner app and cloud backends are encrypted using industry-standard TLS 1.3 / HTTPS. When you enable Face ID / Touch ID, your biometric data is processed entirely within your device\'s Secure Enclave and is never transmitted to or stored on our servers.',
      ),
      _section(
        'Your Rights & Account Deletion',
        'You retain full ownership of your data at all times. You have the right to:\n'
        '• Export your complete data ledger and tenant directory to CSV at any time via Settings > Export Data.\n'
        '• Permanently delete your account and all associated records in-app via Settings > Delete Account. Account deletion permanently erases your authentication profile, all Firestore properties, leases, financial records, documents, and notifications immediately.',
      ),
      _section(
        'Contact Us',
        'If you have questions, feedback, or requests regarding this Privacy Policy, please contact our privacy compliance team at:\n'
        'Email: privacy@veradostudio.com\n'
        'Support: support@veradostudio.com\n'
        'Developer: Verado Studio',
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          version == null ? 'Last updated: September 30, 2026' : 'Last updated: September 30, 2026 · Version $version',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ),
    ];
  }

  List<Widget> _termsOfServiceContent() {
    return [
      _section(
        '1. Acceptance of Terms',
        'By downloading, accessing, or using LandOwner ("the Application"), you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the Application.',
      ),
      _section(
        '2. Permitted Use & Account Security',
        'LandOwner is designed as a private property operating system for landlords, real estate investors, and property managers. You are responsible for safeguarding your login credentials and ensuring all data entered regarding properties and tenants is accurate and lawful.',
      ),
      _section(
        '3. Financial & Accounting Disclaimer',
        'LandOwner provides tools for recording rent, logging expenses, and calculating estimated cash flows and yields. The Application is not a licensed financial advisor, chartered accountant, or bank. The calculations and reports provided are for informational purposes only.',
      ),
      _section(
        '4. Tenant Privacy Compliance',
        'You agree that when entering tenant personal details, contact information, and lease contracts into the Application, you have obtained all necessary consents required by local tenancy and data privacy laws in your jurisdiction.',
      ),
      _section(
        '5. Intellectual Property & User Content',
        'You retain full intellectual property ownership of all user content, images, and property data uploaded to LandOwner. You grant LandOwner a limited, non-exclusive license solely to host and display this content back to you as necessary to operate the service.',
      ),
      _section(
        '6. Account Termination',
        'You may terminate your account at any time using the in-app account deletion tool. We reserve the right to suspend or terminate accounts that violate applicable laws or abuse cloud resources.',
      ),
      _section(
        '7. Contact & Inquiries',
        'For terms, licensing, or legal inquiries, reach out to legal@veradostudio.com.',
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Effective Date: September 30, 2026',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ),
    ];
  }

  Widget _section(String heading, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SurfaceCard(
        radius: AppRadius.card,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
