import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/sheets.dart';
import '../../../core/widgets/states.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/widgets/ledger_row.dart';
import '../../../shared/widgets/sub_page.dart';
import '../domain/ledger_entry.dart';

/// Income, Expenses, or every transaction (`kind == null`) — with category,
/// period and search. Tapping a row opens its edit form (rent opens the payment).
class LedgerListScreen extends ConsumerStatefulWidget {
  const LedgerListScreen({super.key, this.kind});
  final EntryKind? kind;

  @override
  ConsumerState<LedgerListScreen> createState() => _LedgerListScreenState();
}

class _LedgerListScreenState extends ConsumerState<LedgerListScreen> {
  static const _periods = ['This month', 'Last month', 'Last 3 months', 'This year', 'All time'];
  String _cat = 'All', _q = '';
  late String _period = widget.kind == null ? 'All time' : 'This month';
  int _shown = 40;

  bool get _all => widget.kind == null;
  bool get _income => widget.kind == EntryKind.income;

  bool _inPeriod(DateTime d, DateTime t) => switch (_period) {
        'This month' => d.year == t.year && d.month == t.month,
        'Last month' => d.year == DateTime(t.year, t.month - 1).year && d.month == DateTime(t.year, t.month - 1).month,
        'Last 3 months' => !d.isBefore(DateTime(t.year, t.month - 2)),
        'This year' => d.year == t.year,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final today = ref.read(clockProvider).today();
    final names = {for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
    final tenants = {for (final t in ref.watch(tenantsProvider).value ?? const []) t.id: t.name};
    final cats = _all
        ? const ['All', 'Income', 'Expenses']
        : ['All', ...(_income ? IncomeType.values.map((e) => e.label) : ExpenseCategory.values.map((e) => e.label))];
    final list = (ref.watch(ledgerProvider).value ?? const <LedgerEntry>[]).where((e) {
      if ((!_all && e.kind != widget.kind) || !_inPeriod(e.date, today)) return false;
      if (_all) {
        if (_cat == 'Income' && !e.isIncome) return false;
        if (_cat == 'Expenses' && e.isIncome) return false;
      } else {
        final c = _income ? e.incomeType?.label : e.expenseCategory?.label;
        if (_cat != 'All' && c != _cat) return false;
      }
      return _q.isEmpty || '${e.title} ${names[e.propertyId]} ${tenants[e.tenantId]}'.toLowerCase().contains(_q);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final total = list.fold(0, (s, e) => s + (_all ? e.signed : e.amount));

    return SubPage(
      title: _all ? 'Transactions' : (_income ? 'Income' : 'Expenses'),
      subtitle: _all
          ? '${list.length} entries · ${Money.compact(total)} net · ${_period.toLowerCase()}'
          : '${Money.compact(total)} · ${_period.toLowerCase()}',
      action: _all ? null : AddButton(onTap: () => context.push(Routes.add(_income ? 'income' : 'expense'))),
      slivers: [
        SliverToBoxAdapter(child: HomelySearchField(placeholder: 'Search entries', onChanged: (q) => setState(() => _q = q))),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: ChipRow(labels: cats, selected: _cat, onSelect: (c) => setState(() => _cat = c)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              const Spacer(),
              SortButton(
                label: _period,
                onTap: () async {
                  final r = await showChoiceSheet(context, title: 'Period', options: _periods, selected: _period);
                  if (r != null) setState(() => _period = r);
                },
              ),
            ]),
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: EmptyStateCard(
              title: 'Nothing recorded',
              message: 'No ${_all ? 'transactions' : _income ? 'income' : 'expenses'} in this view.',
              icon: _income || _all ? HomelyIcons.trendUp : HomelyIcons.trendDown,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList.builder(
              itemCount: list.length.clamp(0, _shown),
              itemBuilder: (_, i) {
                if (i == _shown - 1) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? setState(() => _shown += 40) : null);
                final e = list[i];
                final rent = e.isIncome && e.sourceRef != null && e.incomeType == IncomeType.rent;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push(
                      rent ? Routes.payment(e.sourceRef!) : Routes.add(e.isIncome ? 'income' : 'expense', editId: e.id)),
                  child: LedgerRow(
                    title: rent ? 'Rent · ${names[e.propertyId] ?? ''}' : e.title,
                    subtitle: '${rent ? tenants[e.tenantId] ?? '' : names[e.propertyId] ?? ''} · ${Dates.dMy(e.date)}',
                    amount: e.amount,
                    income: e.isIncome,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
