import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/sheets.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/toast.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/usecases.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/ledger_row.dart';
import '../../../shared/widgets/sub_page.dart';
import '../domain/maintenance_ticket.dart';
import 'maintenance_list_screen.dart';

class MaintenanceDetailScreen extends ConsumerWidget {
  const MaintenanceDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = (ref.watch(maintenanceProvider).value ?? const <MaintenanceTicket>[]).where((x) => x.id == id).firstOrNull;
    if (t == null) {
      return const SubPage(title: 'Maintenance', slivers: [
        SliverToBoxAdapter(child: EmptyStateCard(title: 'Not found', message: 'This request was removed.')),
      ]);
    }
    final p = ref.watch(propertyByIdProvider(t.propertyId));
    final expenses = (ref.watch(ledgerProvider).value ?? const []).where((e) => e.sourceRef == t.id && !e.isIncome).toList();
    final toast = ref.read(toastProvider.notifier);
    final soft = TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: .7));
    Widget fig(String l, String v) => FractionallySizedBox(
          widthFactor: .5,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: soft),
            const SizedBox(height: 3),
            Text(v, style: AppType.num(20).copyWith(color: AppColors.white)),
          ]),
        );
    Future<void> set(MaintenanceStatus s, String msg) async {
      await ref.read(updateMaintenanceStatusProvider)(t.id, s);
      toast.show(msg);
    }

    final photos = [...t.photoUrls, ?t.receiptUrl];
    return ColoredBox(
      color: AppColors.background,
      child: Column(children: [
        Expanded(
          child: SubPage(
            title: t.title,
            subtitle: '${p?.name ?? ''} · ${t.category.label}',
            action: SolidButton(
              label: 'Edit',
              height: 44,
              radius: 22,
              fontSize: 14,
              color: AppColors.surface,
              foreground: AppColors.primary,
              onTap: () => context.push(Routes.add('maintenance', editId: t.id)),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.list(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(children: [
                      TonePill.tone('${t.status.label} · ${t.priority.label}', maintenanceTone(t), dot: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: p == null
                              ? const SizedBox.shrink()
                              : LinkText('${p.name} →', onTap: () => context.push(Routes.property(p.id))),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  GradientCard(
                    child: Wrap(runSpacing: 16, children: [
                      fig('Scheduled', Dates.dMy(t.scheduledFor)),
                      fig('Priority', t.priority.label),
                      fig('Estimated', t.estimatedCost == 0 ? '—' : Money.k(t.estimatedCost)),
                      fig('Actual', t.actualCost == null ? '—' : Money.k(t.actualCost!)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  SurfaceCard(
                    radius: AppRadius.list,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Description', style: AppType.caption),
                      const SizedBox(height: 4),
                      Text(t.description.isEmpty ? 'No description.' : t.description,
                          style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.ink)),
                      if (t.notes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text('Notes', style: AppType.caption),
                        const SizedBox(height: 4),
                        Text(t.notes, style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.ink)),
                      ],
                    ]),
                  ),
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox.square(dimension: 84, child: NetImage(photos[i])),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SurfaceCard(
                    radius: AppRadius.list,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Linked expense', style: AppType.cardTitle),
                      const SizedBox(height: 4),
                      if (expenses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Completing this request records its cost as a maintenance expense for the property.',
                              style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textMuted)),
                        ),
                      for (final e in expenses)
                        GestureDetector(
                          onTap: () => context.push(Routes.add('expense', editId: e.id)),
                          child: LedgerRow(
                              title: e.title, subtitle: '${p?.name ?? ''} · ${Dates.dMy(e.date)}', amount: e.amount, income: false),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LinkText('Delete request', color: AppColors.overdueText, onTap: () async {
                      final ok = await showConfirmSheet(context,
                          title: 'Delete this request?',
                          message: 'Any expense already recorded for it stays in your ledger.',
                          confirmLabel: 'Delete request');
                      if (!ok) return;
                      await ref.read(recordEditsProvider).deleteMaintenance(t.id);
                      toast.show('Request deleted');
                      if (context.mounted) context.pop();
                    }),
                  ),
                ]),
              ),
            ],
          ),
        ),
        if (!t.isDone)
          BottomActionBar(
            child: Row(children: [
              if (t.status != MaintenanceStatus.inProgress) ...[
                Expanded(
                  flex: 10,
                  child: SolidButton(
                    label: 'Mark in progress',
                    height: 56,
                    radius: AppRadius.cta,
                    color: AppColors.surface,
                    foreground: AppColors.ink,
                    border: AppColors.border,
                    onTap: () => set(MaintenanceStatus.inProgress, 'Marked in progress'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 12,
                child: GradientCta(
                  label: 'Mark completed',
                  shadow: const [],
                  onTap: () => set(MaintenanceStatus.completed, 'Completed · expense recorded'),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}
