import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../core/icons/homely_icons.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/text_blocks.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/portfolio.dart';
import '../../../shared/widgets/ledger_row.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../finance/presentation/widgets/finance_sections.dart';
import 'home_providers.dart';
import 'widgets/home_header.dart';
import 'widgets/month_glance_card.dart';

/// Home — the portfolio command center.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(portfolioReadyProvider)) return const DashboardSkeleton();
    final today = ref.read(clockProvider).today();
    final summary = ref.watch(portfolioSummaryProvider);
    final month = ref.watch(thisMonthProvider);
    final attention = ref.watch(attentionProvider);
    final activity = ref.watch(recentActivityProvider(4));
    final insights = ref.watch(financeInsightsProvider);
    final expenses = ref.watch(expenseBreakdownProvider);
    final hasLeases = (ref.watch(leasesProvider).value ?? const []).isNotEmpty;
    final hasLedger = (ref.watch(ledgerProvider).value ?? const []).isNotEmpty;

    return CustomScrollView(slivers: [
      SliverList.list(children: [
        const HomeHeader(),
        // This month's cash flow, then where the money went.
        MonthGlanceCard(
          month: today,
          totals: month,
          properties: summary.count,
          units: summary.units,
          occupied: summary.occupied,
          onTap: () => context.go(Routes.finance),
        ),
        if (expenses.isNotEmpty)
          ExpenseDonutCard(
            shares: expenses,
            title: '${Dates.month(today)} expenses',
            margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            onTap: () => context.push(Routes.expenses),
          ),
        // "What changed" — the computed portfolio insights.
        if (insights.isNotEmpty) ...[
          const SectionTitle('What changed', padding: EdgeInsets.fromLTRB(24, 30, 24, 12)),
          InsightCarousel(items: insights),
        ],
        if (attention.isNotEmpty) ...[
          SectionTitle('Needs your attention', badge: CountBadge(attention.length)),
          SurfaceCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 6),
            shadow: AppShadows.card,
            child: Column(children: [
              for (var i = 0; i < attention.length; i++)
                AlertRow(
                  first: i == 0,
                  icon: attention[i].icon,
                  tone: attention[i].tone,
                  title: attention[i].title,
                  subtitle: attention[i].subtitle,
                  trailing: attention[i].when,
                  onTap: () => context.push(attention[i].route),
                ),
            ]),
          ),
        ],
        // A brand-new portfolio still gets a clear first step on Home.
        if (summary.metrics.isEmpty)
          EmptyStateCard(
            title: 'Nothing here yet',
            message: 'Add your first property and it will appear with its value and income.',
            actionLabel: 'Add a property',
            onAction: () => context.push(Routes.add('property')),
            margin: const EdgeInsets.fromLTRB(16, 34, 16, 0),
          )
        // Properties added but nothing recorded yet — suggest the next steps.
        else if (!hasLeases && !hasLedger) ...[
          const SectionTitle('Next steps'),
          SurfaceCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 6),
            shadow: AppShadows.card,
            child: Column(children: [
              AlertRow(
                first: true,
                icon: HomelyIcons.users,
                tone: Tone.info,
                title: 'Add a tenant & lease',
                subtitle: 'Track rent, due dates and reminders',
                trailing: '',
                onTap: () => context.push(Routes.add('lease')),
              ),
              AlertRow(
                icon: HomelyIcons.coin,
                tone: Tone.ok,
                title: 'Record income',
                subtitle: 'Rent or any other money received',
                trailing: '',
                onTap: () => context.push(Routes.add('income')),
              ),
              AlertRow(
                icon: HomelyIcons.wallet,
                tone: Tone.warn,
                title: 'Record an expense',
                subtitle: 'Repairs, bills, taxes and fees',
                trailing: '',
                onTap: () => context.push(Routes.add('expense')),
              ),
            ]),
          ),
        ],
        if (activity.isNotEmpty) ...[
          const SectionTitle('Recent activity', padding: EdgeInsets.fromLTRB(24, 34, 24, 8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, AppSpacing.navClearance),
            child: Column(children: [
              for (final a in activity)
                LedgerRow(title: a.title, subtitle: a.subtitle, amount: a.amount, income: a.income),
            ]),
          ),
        ] else
          const SizedBox(height: AppSpacing.navClearance),
      ]),
    ]);
  }
}
