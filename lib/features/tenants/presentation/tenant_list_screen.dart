import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/sheets.dart';
import '../../../core/widgets/states.dart';
import '../../../shared/widgets/status_row.dart';
import '../../../shared/widgets/sub_page.dart';
import '../domain/tenancy_status.dart';
import 'tenant_providers.dart';

/// Tenants — every tenancy with rent status, lease status and next due date.
class TenantListScreen extends ConsumerStatefulWidget {
  const TenantListScreen({super.key});
  @override
  ConsumerState<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends ConsumerState<TenantListScreen> {
  static const _filters = ['All', 'Active', 'Payment due', 'Overdue', 'Lease ending', 'Former'];
  static const _sorts = ['Name', 'Next rent due', 'Monthly rent', 'Lease end'];
  String _filter = 'All', _sort = 'Name', _q = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(tenancyRowsProvider);
    final rows = all.where((r) {
      final f = _filter == 'All' ||
          r.tenancy.status.label == _filter ||
          (_filter == 'Active' && r.tenancy.status != TenancyStatus.former);
      final q = _q.isEmpty || '${r.tenant?.name} ${r.place}'.toLowerCase().contains(_q);
      return f && q;
    }).toList()
      ..sort((a, b) => switch (_sort) {
            'Next rent due' => (a.tenancy.nextDue?.dueDate ?? DateTime(2999)).compareTo(b.tenancy.nextDue?.dueDate ?? DateTime(2999)),
            'Monthly rent' => b.lease.monthlyRent.compareTo(a.lease.monthlyRent),
            'Lease end' => a.lease.end.compareTo(b.lease.end),
            _ => (a.tenant?.name ?? '').compareTo(b.tenant?.name ?? ''),
          });
    final active = all.where((r) => r.tenancy.status != TenancyStatus.former).length;

    return SubPage(
      title: 'Tenants',
      subtitle: '$active active · ${all.length - active} former',
      action: AddButton(label: 'Add tenant', onTap: () => context.push(Routes.add('tenant'))),
      slivers: [
        SliverToBoxAdapter(child: HomelySearchField(placeholder: 'Search tenant or property', onChanged: (q) => setState(() => _q = q))),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: ChipRow(labels: _filters, selected: _filter, onSelect: (f) => setState(() => _filter = f)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              const Spacer(),
              SortButton(
                label: 'Sort · $_sort',
                onTap: () async {
                  final s = await showChoiceSheet(context, title: 'Sort tenants', options: _sorts, selected: _sort);
                  if (s != null) setState(() => _sort = s);
                },
              ),
            ]),
          ),
        ),
        if (rows.isEmpty)
          SliverToBoxAdapter(
            child: EmptyStateCard(
              title: all.isEmpty ? 'No tenants yet' : 'Nothing here',
              message: all.isEmpty
                  ? 'Add a lease and the tenant appears here with rent status and history.'
                  : 'No tenants match this view.',
              icon: HomelyIcons.users,
              actionLabel: all.isEmpty ? 'Add tenant' : null,
              onAction: () => context.push(Routes.add('tenant')),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = rows[i];
                final next = r.tenancy.nextDue;
                return StatusRow(
                  initials: r.tenant?.initials ?? '',
                  tone: r.tenancy.status.tone,
                  title: r.tenant?.name ?? 'Tenant',
                  subtitle: r.place,
                  meta: r.tenancy.status == TenancyStatus.former
                      ? 'Lease ended ${Dates.my(r.lease.end)}'
                      : '${next == null ? 'No rent due' : 'Next due ${Dates.dM(next.dueDate)}'} · lease to ${Dates.my(r.lease.end)}',
                  figure: Money.k(r.lease.monthlyRent),
                  status: r.tenancy.status.label,
                  onTap: () => context.push(Routes.tenant(r.lease.id)),
                );
              },
            ),
          ),
      ],
    );
  }
}
