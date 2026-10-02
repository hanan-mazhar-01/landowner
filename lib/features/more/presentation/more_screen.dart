import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/text_blocks.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/portfolio.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/preferences_provider.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../notifications/data/notification_settings_provider.dart';
import 'more_widgets.dart';

/// "Operating System" — everything that keeps the portfolio running.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.read(clockProvider).today();
    final user = ref.watch(currentUserProvider);
    final summary = ref.watch(portfolioSummaryProvider);
    final tickets = (ref.watch(maintenanceProvider).value ?? const []).where((t) => !t.isDone).toList();
    final docs = ref.watch(documentsProvider).value ?? const [];
    final reminders = ref.watch(remindersProvider).value ?? const [];
    final week = reminders.where((r) => !r.done && r.at.difference(today).inDays.clamp(-1, 99) < 7 && !r.at.isBefore(today));
    final expiring = docs.where((d) => (d.daysToExpiry(today) ?? 999) <= 60 && (d.daysToExpiry(today) ?? -1) >= 0);
    final urgent = tickets.where((t) => t.priority.isSevere).length;
    final insights = ref.watch(financeInsightsProvider).length;
    final tenantCount = (ref.watch(tenantsProvider).value ?? const []).length;
    final pushOn = ref.watch(notificationSettingsProvider).push;

    return CustomScrollView(slivers: [
      SliverList.list(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 12, 24, 0),
          child: const PageTitle('Operating System', subtitle: 'Everything that keeps your portfolio running.'),
        ),
        SurfaceCard(
          margin: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          radius: AppRadius.card,
          padding: const EdgeInsets.all(14),
          onTap: () => context.push(Routes.profile),
          child: Row(children: [
            UserAvatar(name: user?.name ?? '', url: user?.avatarUrl, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name ?? '', style: AppType.num(18)),
                const SizedBox(height: 2),
                Text('Owner · ${summary.count} ${summary.count == 1 ? 'property' : 'properties'}${user?.city.isNotEmpty == true ? ' · ${user!.city}' : ''}',
                    style: AppType.meta),
              ]),
            ),
            const HomelyIcon(HomelyIcons.chevronRight, size: 18, color: AppColors.textFaint),
          ]),
        ),
        const Overline('Operations'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: OpsTile(
                  icon: HomelyIcons.users,
                  count: '$tenantCount',
                  label: 'Tenants',
                  sub: 'Leases & payments',
                  flag: summary.overdue.isEmpty ? '' : '${summary.overdue.length} overdue',
                  flagColor: AppColors.overdueText,
                  onTap: () => context.push(Routes.tenants),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OpsTile(
                  icon: HomelyIcons.wrench,
                  count: '${tickets.length}',
                  label: 'Maintenance',
                  sub: 'Open requests',
                  flag: urgent == 0 ? '' : '$urgent urgent',
                  flagColor: AppColors.attentionText,
                  onTap: () => context.push(Routes.maintenance),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OpsTile(
                  icon: HomelyIcons.calendar,
                  count: '${week.length}',
                  label: 'Calendar',
                  sub: 'This week',
                  onTap: () => context.push(Routes.calendar),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OpsTile(
                  icon: HomelyIcons.file,
                  count: '${docs.length}',
                  label: 'Documents',
                  sub: 'In your vault',
                  flag: expiring.isEmpty ? '' : '${expiring.length} expiring',
                  flagColor: AppColors.attentionText,
                  onTap: () => context.push(Routes.documents),
                ),
              ),
            ]),
          ]),
        ),
        const Overline('Intelligence'),
        IntelligenceEntry(subtitle: '$insights ${insights == 1 ? 'insight' : 'insights'} · Ask your portfolio', onTap: () => context.push(Routes.ai)),
        const Overline('Records'),
        MenuGroup(items: [
          MenuItem(HomelyIcons.chart, 'Reports & export', value: 'PDF · CSV', onTap: () => context.push(Routes.reports)),
          MenuItem(HomelyIcons.compare, 'Compare properties', onTap: () => context.push(Routes.report('performance'))),
          MenuItem(HomelyIcons.coin, 'Payments', onTap: () => context.push(Routes.payments)),
        ]),
        const Overline('Account'),
        MenuGroup(items: [
          MenuItem(HomelyIcons.bell, 'Notifications',
              value: pushOn ? 'On' : 'Off',
              onTap: () => context.push(Routes.notificationSettings)),
          MenuItem(HomelyIcons.lock, 'Profile & settings', onTap: () => context.push(Routes.profile)),
          MenuItem(HomelyIcons.coin, 'Currency', value: ref.watch(preferencesProvider).currency, onTap: () => context.push(Routes.profile)),
          MenuItem(HomelyIcons.shield, 'Privacy policy', onTap: () => context.push(Routes.privacyPolicy)),
          MenuItem(HomelyIcons.file, 'Terms of service', onTap: () => context.push(Routes.termsOfService)),
          MenuItem(HomelyIcons.help, 'Help & support', onTap: () => openSupportEmail(ref)),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, AppSpacing.navClearance),
          child: Align(
            alignment: Alignment.centerLeft,
            child: LinkText('Sign out', color: AppColors.overdueText, onTap: () => ref.read(authRepositoryProvider).signOut()),
          ),
        ),
      ]),
    ]);
  }
}
