import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/sheets.dart';
import '../../../core/widgets/states.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/widgets/status_row.dart';
import '../../../shared/widgets/sub_page.dart';
import '../domain/maintenance_ticket.dart';

Tone maintenanceTone(MaintenanceTicket t) => t.isDone
    ? Tone.ok
    : t.priority == MaintenancePriority.urgent || t.priority == MaintenancePriority.high
        ? Tone.bad
        : t.status == MaintenanceStatus.inProgress
            ? Tone.info
            : Tone.warn;

/// Maintenance — shared by More → Maintenance and Property → Maintenance.
class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key, this.propertyId});
  final String? propertyId;

  @override
  ConsumerState<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen> {
  static const _sorts = ['Scheduled date', 'Priority', 'Cost'];
  String _status = 'Active', _priority = 'Any priority', _sort = 'Scheduled date', _q = '';

  @override
  Widget build(BuildContext context) {
    final names = {for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
    final all = (ref.watch(maintenanceProvider).value ?? const <MaintenanceTicket>[])
        .where((t) => widget.propertyId == null || t.propertyId == widget.propertyId)
        .toList();
    final list = all.where((t) {
      final st = _status == 'All' || (_status == 'Active' ? !t.isDone : t.status.label == _status);
      final pr = _priority == 'Any priority' || t.priority.label == _priority;
      final q = _q.isEmpty || '${t.title} ${names[t.propertyId]} ${t.category.label}'.toLowerCase().contains(_q);
      return st && pr && q;
    }).toList()
      ..sort((a, b) => switch (_sort) {
            'Priority' => b.priority.index.compareTo(a.priority.index),
            'Cost' => b.cost.compareTo(a.cost),
            _ => a.scheduledFor.compareTo(b.scheduledFor),
          });

    return SubPage(
      title: 'Maintenance',
      subtitle: widget.propertyId == null
          ? '${all.where((t) => !t.isDone).length} open requests'
          : '${names[widget.propertyId]} · ${all.where((t) => !t.isDone).length} open',
      action: AddButton(onTap: () => context.push(Routes.add('maintenance', propertyId: widget.propertyId))),
      slivers: [
        SliverToBoxAdapter(child: HomelySearchField(placeholder: 'Search issue or property', onChanged: (q) => setState(() => _q = q))),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: ChipRow(
              labels: const ['Active', 'Open', 'Scheduled', 'In progress', 'Completed', 'All'],
              selected: _status,
              onSelect: (s) => setState(() => _status = s),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              SortButton(
                label: _priority,
                onTap: () async {
                  final r = await showChoiceSheet(context,
                      title: 'Priority',
                      options: ['Any priority', for (final p in MaintenancePriority.values) p.label],
                      selected: _priority);
                  if (r != null) setState(() => _priority = r);
                },
              ),
              const Spacer(),
              SortButton(
                label: 'Sort · $_sort',
                onTap: () async {
                  final r = await showChoiceSheet(context, title: 'Sort requests', options: _sorts, selected: _sort);
                  if (r != null) setState(() => _sort = r);
                },
              ),
            ]),
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: EmptyStateCard(
              title: 'All clear',
              message: 'No maintenance requests in this view.',
              icon: HomelyIcons.wrench,
              tone: Tone.ok,
              actionLabel: 'Log an issue',
              onAction: () => context.push(Routes.add('maintenance', propertyId: widget.propertyId)),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final t = list[i];
                return StatusRow(
                  icon: HomelyIcons.wrench,
                  tone: maintenanceTone(t),
                  title: t.title,
                  subtitle: '${names[t.propertyId] ?? ''} · ${t.category.label}',
                  meta: '${t.priority.label} priority · ${t.isDone ? 'done' : 'for'} ${Dates.dMy(t.scheduledFor)}',
                  figure: t.cost > 0 ? Money.k(t.cost) : '—',
                  status: t.status.label,
                  statusTone: t.isDone ? Tone.ok : (t.status == MaintenanceStatus.inProgress ? Tone.info : Tone.warn),
                  onTap: () => context.push(Routes.maintenanceItem(t.id)),
                );
              },
            ),
          ),
      ],
    );
  }
}
