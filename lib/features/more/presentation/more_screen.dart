import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/text_blocks.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/portfolio.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../finance/presentation/finance_providers.dart';
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
                Text(
                  user?.name ?? '',
                  style: AppType.num(18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Owner · ${summary.count} ${summary.count == 1 ? 'property' : 'properties'}${user?.city.isNotEmpty == true ? ' · ${user!.city}' : ''}',
                  style: AppType.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
        const Overline('Settings'),
        MenuGroup(items: [
          MenuItem(
            HomelyIcons.lock,
            'Profile & settings',
            value: 'Account, preferences & security',
            onTap: () => context.push(Routes.profile),
          ),
        ]),
        const SizedBox(height: AppSpacing.navClearance),
      ]),
    ]);
  }
}
