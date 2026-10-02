import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_blocks.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/portfolio.dart';
import '../../../shared/widgets/ledger_row.dart';
import '../domain/finance_analytics.dart';
import 'finance_providers.dart';
import 'widgets/cash_flow_card.dart';

/// Finance command center.
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  static const _sections = {
    'Overview': null,
    'Income': Routes.income,
    'Expenses': Routes.expenses,
    'Payments': Routes.payments,
    'Cash flow': Routes.cashFlow,
    'Reports': Routes.reports,
  };
  FinanceRange _range = FinanceRange.m6;
  int? _sel;

  /// Finance shows a short preview; 'See all' opens the full list.
  static const _txPreview = 6;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(portfolioReadyProvider)) return const DashboardSkeleton();
    final today = ref.read(clockProvider).today();
    final series = ref.watch(financeSeriesProvider(_range));
    final month = ref.watch(thisMonthProvider);
    final last = ref.watch(lastMonthProvider);
    final hasPrev = last.net != 0;
    final change = hasPrev
        ? (month.net - last.net) / last.net.abs() * 100
        : 0.0;
    final prevMonth = Dates.month(DateTime(today.year, today.month - 1));
    final names = {
      for (final p in ref.watch(propertiesProvider).value ?? const [])
        p.id: p.name,
    };
    final tenants = {
      for (final t in ref.watch(tenantsProvider).value ?? const [])
        t.id: t.name,
    };
    final ledger = [...?ref.watch(ledgerProvider).value]
      ..sort((a, b) => b.date.compareTo(a.date));

    return CustomScrollView(
      slivers: [
        SliverList.list(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.paddingOf(context).top + 12,
                24,
                0,
              ),
              child: Row(
                children: [
                  Text('Finance', style: AppType.pageTitle),
                  const Spacer(),
                  InkSegments(
                    labels: [for (final r in FinanceRange.values) r.label],
                    index: _range.index,
                    onChanged: (i) => setState(() {
                      _range = FinanceRange.values[i];
                      _sel = null;
                    }),
                  ),
                ],
              ),
            ),
            // Finance sections — Overview is this dashboard; the rest open pages.
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: ChipRow(
                labels: _sections.keys.toList(),
                selected: 'Overview',
                onSelect: (k) =>
                    _sections[k] == null ? null : context.push(_sections[k]!),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net cash flow · ${Dates.month(today)}',
                    style: AppType.label13,
                  ),
                  const SizedBox(height: 8),
                  MoneyHero(
                    value: month.net.abs() < 1000
                        ? month.net.toDouble()
                        : month.net / 1000,
                    unit: month.net.abs() < 1000 ? '' : 'K',
                    decimals: month.net.abs() < 1000 || month.net % 1000 == 0
                        ? 0
                        : 1,
                    symbol: Money.symbol,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Only compare when last month actually has data.
                      if (hasPrev) ...[
                        TonePill.tone(
                          '${change >= 0 ? '+' : '−'}${change.abs().round()}%',
                          change >= 0 ? Tone.ok : Tone.bad,
                          fontSize: 13,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          [
                            hasPrev
                                ? 'vs $prevMonth'
                                : 'No $prevMonth data to compare',
                            if (month.income > 0)
                              '${month.keptPct.round()}% of income kept',
                          ].join(' · '),
                          overflow: TextOverflow.ellipsis,
                          style: AppType.meta,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            CashFlowCard(
              series: series,
              range: _range,
              selected: _sel ?? series.length - 1,
              onSelect: (i) => setState(() => _sel = i),
              monthName: Dates.month(today),
            ),
            SectionTitle(
              'Transactions',
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 6),
              trailing: ledger.isEmpty
                  ? null
                  : LinkText(
                      'See all',
                      onTap: () => context.push(Routes.transactions),
                    ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: ledger.length < _txPreview ? ledger.length : _txPreview,
            itemBuilder: (_, i) {
              final e = ledger[i];
              final prop = names[e.propertyId] ?? '';
              final isRent = e.isIncome && e.title == 'Rent';
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(
                  isRent && e.sourceRef != null
                      ? Routes.payment(e.sourceRef!)
                      : Routes.add(
                          e.isIncome ? 'income' : 'expense',
                          editId: e.id,
                        ),
                ),
                child: LedgerRow(
                  title: isRent ? 'Rent · $prop' : e.title,
                  subtitle:
                      '${isRent ? tenants[e.tenantId] ?? prop : prop} · ${Dates.dM(e.date)}',
                  amount: e.amount,
                  income: e.isIncome,
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              14,
              24,
              AppSpacing.navClearance,
            ),
            child: ledger.isEmpty
                ? const Text(
                    'No transactions yet.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
