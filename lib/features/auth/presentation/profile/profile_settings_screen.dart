import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/sheets.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../../../core/widgets/text_blocks.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../shared/data/seed/firestore_seeder.dart';
import '../../../../shared/widgets/sub_page.dart';
import '../../../legal/presentation/legal_screen.dart';
import '../../../more/presentation/more_widgets.dart';
import '../../../notifications/data/notification_settings_provider.dart';
import '../auth_providers.dart';
import '../preferences_provider.dart';
import 'data_export.dart';

/// Profile & settings — Profile · Preferences · Notifications · Security ·
/// Data · About, all in the More screen's grouped-menu language.
class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(currentUserProvider);
    final prefs = ref.watch(preferencesProvider);
    final ctrl = ref.read(preferencesProvider.notifier);
    final toast = ref.read(toastProvider.notifier);

    Future<void> choose(String title, List<String> options, String current, Preferences Function(String) apply) async {
      final r = await showChoiceSheet(context, title: title, options: options, selected: current);
      if (r != null) ctrl.update(apply(r));
    }

    Future<void> toggleBiometric(bool on) async {
      if (on) {
        if (!await BiometricService.available()) return toast.show('Biometric unlock isn’t set up on this device');
        if (!await BiometricService.confirm('Confirm to turn on biometric unlock')) return;
      }
      ctrl.update(prefs.copyWith(biometric: on));
      toast.show(on ? 'Biometric unlock on' : 'Biometric unlock off');
    }

    return SubPage(
      title: 'Profile & settings',
      subtitle: 'Your account and how LandOwner behaves.',
      slivers: [
        SliverToBoxAdapter(
          child: SurfaceCard(
            margin: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              Row(children: [
                UserAvatar(name: u?.name ?? '', url: u?.avatarUrl, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      u?.name ?? '',
                      style: AppType.num(18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      u?.email ?? '',
                      style: AppType.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((u?.phone ?? '').isNotEmpty)
                      Text(
                        u!.phone,
                        style: AppType.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: SolidButton(
                    label: 'Edit profile',
                    height: 42,
                    radius: 14,
                    fontSize: 14,
                    color: AppColors.blue100,
                    foreground: AppColors.primary,
                    onTap: () => context.push(Routes.editProfile),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SolidButton(
                    label: 'Change password',
                    height: 42,
                    radius: 14,
                    fontSize: 14,
                    color: AppColors.blue50,
                    foreground: AppColors.primary,
                    onTap: () => context.push(Routes.changePassword),
                  ),
                ),
              ]),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: Overline('Preferences')),
        SliverToBoxAdapter(
          child: MenuGroup(items: [
            MenuItem(HomelyIcons.coin, 'Currency', value: prefs.currency,
                onTap: () => choose('Currency', Preferences.currencies, prefs.currency, (v) => prefs.copyWith(currency: v))),
            MenuItem(HomelyIcons.calendar, 'Date format', value: prefs.dateFormat,
                onTap: () => choose('Date format', Preferences.dateFormats, prefs.dateFormat, (v) => prefs.copyWith(dateFormat: v))),
          ]),
        ),
        const SliverToBoxAdapter(child: Overline('Notifications')),
        SliverToBoxAdapter(
          child: MenuGroup(items: [
            MenuItem(
              HomelyIcons.bell,
              'Notification settings',
              value: ref.watch(notificationSettingsProvider).push ? 'On' : 'Off',
              onTap: () => context.push(Routes.notificationSettings),
            ),
          ]),
        ),
        const SliverToBoxAdapter(child: Overline('Security')),
        SliverToBoxAdapter(
          child: SurfaceCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            radius: AppRadius.list,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(children: [
              const HomelyIcon(HomelyIcons.lock, size: 19, color: AppColors.primary, strokeWidth: 1.9),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Face ID / fingerprint unlock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  SizedBox(height: 2),
                  Text('Ask for biometrics when LandOwner opens', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ),
              HomelyToggle(value: prefs.biometric, semanticLabel: 'Biometric unlock', onChanged: toggleBiometric),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: Overline('Data')),
        SliverToBoxAdapter(
          child: MenuGroup(items: [
            MenuItem(HomelyIcons.upload, 'Export data', value: 'CSV', onTap: () => exportAllData(ref)),
            MenuItem(HomelyIcons.alert, 'Clear portfolio data', onTap: () async {
              final ok = await showConfirmSheet(
                context,
                title: 'Clear all portfolio data?',
                message: 'This will permanently remove all properties, leases, expenses, and tenant records from your account.',
                confirmLabel: 'Clear all data',
                destructive: true,
              );
              if (ok && u != null) {
                toast.show('Clearing portfolio data…');
                await FirestoreSeeder.clearUserData(u.uid);
                toast.show('All portfolio data cleared');
              }
            }),
            MenuItem(HomelyIcons.alert, 'Delete account', onTap: () => context.push(Routes.deleteAccount)),
          ]),
        ),
        const SliverToBoxAdapter(child: Overline('About')),
        SliverToBoxAdapter(
          child: MenuGroup(items: [
            MenuItem(HomelyIcons.home, 'Version', value: ref.watch(appVersionProvider).value ?? ''),
            MenuItem(HomelyIcons.shield, 'Privacy policy', onTap: () => context.push(Routes.privacyPolicy)),
            MenuItem(HomelyIcons.file, 'Terms of service', onTap: () => context.push(Routes.termsOfService)),
            MenuItem(HomelyIcons.help, 'Help & support', onTap: () => openSupportEmail(ref)),
          ]),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: LinkText('Sign out', color: AppColors.overdueText, onTap: () async {
                final ok = await showConfirmSheet(context,
                    title: 'Sign out?', message: 'You can sign back in any time.', confirmLabel: 'Sign out', destructive: false);
                if (ok) await ref.read(authRepositoryProvider).signOut();
              }),
            ),
          ),
        ),
      ],
    );
  }
}
