import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../shared/forms/fields/text_fields.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/sub_page.dart';
import '../auth_providers.dart';
import 'data_export.dart';

/// Delete account — explains what goes, offers export, then requires the
/// user to type DELETE before the destructive button enables.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  String _typed = '';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final apple = ref.watch(authRepositoryProvider).signInMethod == 'apple.com';
    final ready = _typed.trim().toUpperCase() == 'DELETE' && !_busy;
    Widget item(String t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: HomelyIcon(HomelyIcons.close, size: 14, strokeWidth: 2.4, color: AppColors.overdueText),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink))),
          ]),
        );

    return ColoredBox(
      color: AppColors.background,
      child: Column(children: [
        Expanded(
          child: SubPage(title: 'Delete account', subtitle: 'This permanently removes your LandOwner account.', slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverList.list(children: [
                SurfaceCard(
                  radius: AppRadius.list,
                  color: AppColors.overdueTint,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('What will be deleted', style: AppType.cardTitle.copyWith(color: AppColors.overdueText)),
                    const SizedBox(height: 8),
                    item('All properties, tenants and leases'),
                    item('Rent payments, income and expenses'),
                    item('Maintenance, documents, reminders and notifications'),
                    item('Uploaded photos and files'),
                    item('Your profile, settings on this device and sign-in'),
                  ]),
                ),
                const SizedBox(height: 14),
                SurfaceCard(
                  radius: AppRadius.list,
                  onTap: () => exportAllData(ref),
                  child: const Row(children: [
                    HomelyIcon(HomelyIcons.upload, size: 19, color: AppColors.primary, strokeWidth: 1.9),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text('Export your data first (CSV)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                    HomelyIcon(HomelyIcons.chevronRight, size: 16, color: AppColors.chevron),
                  ]),
                ),
                const SizedBox(height: 22),
                const Text('Type DELETE to confirm',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                HomelyTextField(value: '', placeholder: 'DELETE', onChanged: (v) => setState(() => _typed = v)),
                if (apple) ...[
                  const SizedBox(height: 12),
                  const Text('Apple will ask you to confirm, so LandOwner\u2019s access to your Apple ID is removed too.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],
              ]),
            ),
          ]),
        ),
        BottomActionBar(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: ready ? 1 : .4,
            child: SolidButton(
              label: _busy ? 'Deleting…' : 'Delete my account',
              height: 56,
              radius: AppRadius.cta,
              fontSize: 16,
              color: AppColors.overdueText,
              onTap: ready
                  ? () async {
                      final router = GoRouter.of(context);
                      final toast = ref.read(toastProvider.notifier);
                      setState(() => _busy = true);
                      try {
                        await ref.read(authRepositoryProvider).deleteAccount();
                        // Device-side settings belong to the deleted account too.
                        try {
                          await (await SharedPreferences.getInstance()).clear();
                        } catch (_) {}
                        if (mounted) {
                          toast.show('Account permanently deleted.');
                          router.go(Routes.welcome);
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _busy = false);
                          toast.show(e.toString().replaceAll('AuthFailure: ', ''));
                        }
                      }
                    }
                  : null,
            ),
          ),
        ),
      ]),
    );
  }
}
