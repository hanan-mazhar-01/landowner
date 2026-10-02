import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/sheets.dart';
import '../../../../core/widgets/states.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../shared/providers/collections.dart';
import '../../../../shared/providers/usecases.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/sub_page.dart';
import '../../../leases/domain/rent_charge.dart';
import '../../../tenants/presentation/tenant_payment_history.dart';
import '../../domain/ledger_entry.dart';

/// Payment detail — view, mark paid / unpaid, edit, delete.
class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = (ref.watch(chargesProvider).value ?? const <RentCharge>[]).where((x) => x.id == id).firstOrNull;
    if (c == null) {
      return const SubPage(title: 'Payment', slivers: [
        SliverToBoxAdapter(child: EmptyStateCard(title: 'Not found', message: 'This payment was deleted.')),
      ]);
    }
    final today = ref.read(clockProvider).today();
    final p = ref.watch(propertyByIdProvider(c.propertyId));
    final t = ref.watch(tenantByIdProvider(c.tenantId));
    final lease = (ref.watch(leasesProvider).value ?? const []).where((l) => l.id == c.leaseId).firstOrNull;
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
    Widget kv(String k, String v, {bool first = false, VoidCallback? onTap}) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: first ? null : const BoxDecoration(border: Border(top: BorderSide(color: AppColors.dividerSoft))),
            child: Row(children: [
              Text(k, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(v,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onTap == null ? AppColors.ink : AppColors.primary)),
              ),
            ]),
          ),
        );

    Future<void> markPaid() async {
      final m = await showChoiceSheet(context, title: 'Payment method', options: [for (final m in PaymentMethod.values) m.label], selected: 'Bank');
      if (m == null) return;
      await ref.read(recordRentPaymentProvider)(c.id, method: PaymentMethod.fromLabel(m));
      toast.show('${Money.full(c.amount)} recorded · cash flow updated');
    }

    return ColoredBox(
      color: AppColors.background,
      child: Column(children: [
        Expanded(
          child: SubPage(
            title: '${Dates.month(c.period)} rent',
            subtitle: '${t?.name ?? ''} · ${p?.name ?? ''}',
            action: SolidButton(
              label: 'Edit',
              height: 44,
              radius: 22,
              fontSize: 14,
              color: AppColors.surface,
              foreground: AppColors.primary,
              onTap: () => context.push(Routes.add('payment', editId: c.id)),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.list(children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [rentPill(c.statusOn(today), fontSize: 12)])),
                  const SizedBox(height: 14),
                  GradientCard(
                    child: Wrap(runSpacing: 16, children: [
                      fig('Amount', Money.full(c.amount)),
                      fig('Due date', Dates.dMy(c.dueDate)),
                      fig('Paid', c.isPaid ? Dates.dMy(c.paidAt!) : '—'),
                      fig('Method', c.paymentMethod ?? '—'),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  SurfaceCard(
                    radius: AppRadius.list,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Column(children: [
                      kv('Property', p?.name ?? '', first: true, onTap: p == null ? null : () => context.push(Routes.property(p.id))),
                      kv('Tenant', t?.name ?? '', onTap: lease == null ? null : () => context.push(Routes.tenant(lease.id))),
                      kv('Rent period', '${Dates.month(c.period)} ${c.period.year}'),
                      kv('Grace period ends', Dates.dMy(c.graceEnds)),
                      if (c.statusOn(today) == RentStatus.overdue) kv('Days late', '${c.daysLate(today)}'),
                      kv('Notes', c.notes.isEmpty ? '—' : c.notes),
                    ]),
                  ),
                  if (c.isPaid) ...[
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(children: [
                        HomelyIcon(HomelyIcons.chart, size: 14, color: AppColors.accent),
                        SizedBox(width: 6),
                        Expanded(child: Text('Recorded as income · included in cash flow and reports',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LinkText('Delete payment', color: AppColors.overdueText, onTap: () async {
                      final ok = await showConfirmSheet(context,
                          title: 'Delete this payment?',
                          message: 'The rent charge and any income recorded for it are removed from your ledger.',
                          confirmLabel: 'Delete payment');
                      if (!ok) return;
                      await ref.read(paymentActionsProvider).delete(c.id);
                      toast.show('Payment deleted');
                      if (context.mounted) context.pop();
                    }),
                  ),
                ]),
              ),
            ],
          ),
        ),
        BottomActionBar(
          child: c.isPaid
              ? SolidButton(
                  label: 'Mark as unpaid',
                  height: 56,
                  radius: AppRadius.cta,
                  color: AppColors.surface,
                  foreground: AppColors.ink,
                  border: AppColors.border,
                  onTap: () async {
                    await ref.read(paymentActionsProvider).markUnpaid(c.id);
                    toast.show('Marked unpaid · income removed');
                  },
                )
              : GradientCta(
                  label: 'Mark as paid',
                  shadow: const [],
                  trailing: Text(Money.full(c.amount), style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: .8))),
                  onTap: markPaid,
                ),
        ),
      ]),
    );
  }
}
