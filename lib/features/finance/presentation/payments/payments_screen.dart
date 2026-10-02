import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/sheets.dart';
import '../../../../core/widgets/states.dart';
import '../../../../shared/providers/collections.dart';
import '../../../../shared/widgets/status_row.dart';
import '../../../../shared/widgets/sub_page.dart';
import '../../../leases/domain/rent_charge.dart';

/// Payments — every rent charge, by state, with search and filters.
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key, this.propertyId});
  final String? propertyId;

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  static const _tabs = ['Upcoming', 'Paid', 'Pending', 'Overdue'];
  static const _dates = ['Any date', 'This month', 'Last month', 'Next 30 days', 'This year'];
  String _tab = 'Upcoming', _q = '', _date = 'Any date';
  late String? _prop = widget.propertyId;
  String? _tenant;
  int _shown = 40;

  bool _inDate(DateTime d, DateTime today) => switch (_date) {
        'This month' => d.year == today.year && d.month == today.month,
        'Last month' => d.year == DateTime(today.year, today.month - 1).year && d.month == DateTime(today.year, today.month - 1).month,
        'Next 30 days' => !d.isBefore(today) && d.difference(today).inDays <= 30,
        'This year' => d.year == today.year,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final today = ref.read(clockProvider).today();
    final props = <String, String>{for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
    final tenants = <String, String>{for (final t in ref.watch(tenantsProvider).value ?? const []) t.id: t.name};
    final units = {for (final l in ref.watch(leasesProvider).value ?? const []) l.id: l.unitLabel};
    final all = ref.watch(chargesProvider).value ?? const <RentCharge>[];

    bool inTab(RentCharge c) => switch (_tab) {
          'Paid' => c.isPaid,
          'Pending' => c.inGrace(today),
          'Overdue' => c.statusOn(today) == RentStatus.overdue,
          _ => !c.isPaid && !c.dueDate.isBefore(today) && c.dueDate.difference(today).inDays <= 45,
        };
    final list = all.where((c) {
      final q = _q.isEmpty || '${tenants[c.tenantId]} ${props[c.propertyId]}'.toLowerCase().contains(_q);
      return inTab(c) && q && (_prop == null || c.propertyId == _prop) && (_tenant == null || c.tenantId == _tenant) &&
          _inDate(c.dueDate, today);
    }).toList()
      ..sort((a, b) => _tab == 'Paid' ? b.dueDate.compareTo(a.dueDate) : a.dueDate.compareTo(b.dueDate));
    final total = list.fold(0, (s, c) => s + c.amount);

    Future<void> pick(String title, Map<String, String> options, String? current, void Function(String?) set) async {
      final all = ['All', ...options.values];
      final r = await showChoiceSheet(context, title: title, options: all, selected: current == null ? 'All' : options[current]);
      if (r == null) return;
      setState(() => set(r == 'All' ? null : options.entries.firstWhere((e) => e.value == r).key));
    }

    return SubPage(
      title: 'Payments',
      subtitle: '${list.length} ${_tab.toLowerCase()} · ${Money.compact(total)}',
      slivers: [
        SliverToBoxAdapter(child: HomelySearchField(placeholder: 'Search tenant or property', onChanged: (q) => setState(() => _q = q))),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: ChipRow(labels: _tabs, selected: _tab, onSelect: (t) => setState(() => _tab = t)),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 58,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), children: [
              SortButton(
                  label: _prop == null ? 'All properties' : props[_prop] ?? '',
                  onTap: () => pick('Property', props, _prop, (v) => _prop = v)),
              const SizedBox(width: 8),
              SortButton(
                  label: _tenant == null ? 'All tenants' : tenants[_tenant] ?? '',
                  onTap: () => pick('Tenant', tenants, _tenant, (v) => _tenant = v)),
              const SizedBox(width: 8),
              SortButton(
                label: _date,
                onTap: () async {
                  final r = await showChoiceSheet(context, title: 'Due date', options: _dates, selected: _date);
                  if (r != null) setState(() => _date = r);
                },
              ),
            ]),
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: EmptyStateCard(
              title: 'All quiet here',
              message: 'No ${_tab.toLowerCase()} payments match this view.',
              icon: HomelyIcons.coin,
              tone: Tone.ok,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: list.length.clamp(0, _shown),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i == _shown - 1) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? setState(() => _shown += 40) : null);
                final c = list[i];
                final s = c.statusOn(today);
                final tone = s == RentStatus.paid ? Tone.ok : s == RentStatus.overdue ? Tone.bad : Tone.warn;
                final unit = units[c.leaseId];
                return StatusRow(
                  icon: HomelyIcons.coin,
                  tone: tone,
                  title: tenants[c.tenantId] ?? 'Tenant',
                  subtitle: '${props[c.propertyId] ?? ''}${unit == null ? '' : ' · $unit'}',
                  meta: c.isPaid ? 'Paid ${Dates.dMy(c.paidAt!)}' : 'Due ${Dates.dMy(c.dueDate)}',
                  figure: Money.full(c.amount),
                  status: s == RentStatus.overdue ? 'Overdue ${c.daysLate(today)}d' : c.inGrace(today) ? 'Pending' : s == RentStatus.paid ? 'Paid' : 'Due',
                  onTap: () => context.push(Routes.payment(c.id)),
                );
              },
            ),
          ),
      ],
    );
  }
}
