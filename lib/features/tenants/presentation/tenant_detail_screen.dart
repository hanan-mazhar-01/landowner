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
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/widgets/contact_tiles.dart';
import '../../../shared/widgets/sub_page.dart';
import '../../leases/domain/rent_charge.dart';
import '../../properties/presentation/detail/detail_extras.dart';
import '../../properties/presentation/detail/property_detail_vm.dart';
import '../../properties/presentation/detail/tenancy_cards.dart';
import 'tenant_payment_history.dart';
import 'tenant_providers.dart';

/// Tenant detail — profile, contact, lease, payments, documents, notes.
class TenantDetailScreen extends ConsumerWidget {
  const TenantDetailScreen({super.key, required this.leaseId});
  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref.watch(tenancyRowProvider(leaseId));
    if (row == null) {
      return const SubPage(title: 'Tenant', slivers: [
        SliverToBoxAdapter(child: EmptyStateCard(title: 'Not found', message: 'This tenancy no longer exists.')),
      ]);
    }
    final today = ref.read(clockProvider).today();
    final l = row.lease, t = row.tenant, st = row.tenancy.status;
    final charges = (ref.watch(chargesProvider).value ?? const <RentCharge>[]).where((c) => c.leaseId == l.id).toList();
    final paidOk = row.tenancy.overdue.isEmpty;
    final docs = (ref.watch(documentsProvider).value ?? const [])
        .where((d) => d.propertyId == l.propertyId && d.type.label == 'Lease')
        .map((d) => DocChip(d.name, d.expiry == null ? Dates.dMy(d.date) : 'Expires ${Dates.my(d.expiry!)}', AppColors.textMuted))
        .toList();
    Widget cell(String label, String value, {Color? color}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppType.caption),
              const SizedBox(height: 4),
              Text(value, style: AppType.num(19).copyWith(color: color ?? AppColors.ink)),
            ]),
          ),
        );

    return SubPage(
      title: t?.name ?? 'Tenant',
      subtitle: row.place,
      action: SolidButton(
        label: 'Edit',
        height: 44,
        radius: 22,
        fontSize: 14,
        color: AppColors.surface,
        foreground: AppColors.primary,
        onTap: () => context.push(Routes.add('tenant', editId: t?.id)),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverList.list(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                TonePill.tone(st.label, st.tone, dot: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: row.property == null
                        ? const SizedBox.shrink()
                        : LinkText('${row.property!.name} →', onTap: () => context.push(Routes.property(l.propertyId))),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            ContactTiles(phone: t?.phone ?? '', message: 'Hi ${t?.firstName ?? ''}, '),
            const SizedBox(height: 14),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    cell('Monthly rent', Money.k(l.monthlyRent)),
                    const Hairline(vertical: true),
                    cell('Security deposit', Money.k(l.deposit)),
                  ]),
                ),
                const Hairline(),
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    cell('Rent due', '${Dates.ordinal(l.dueDay)} monthly'),
                    const Hairline(vertical: true),
                    cell('Payment status', paidOk ? (row.tenancy.nextDue == null ? 'Paid' : 'Up to date') : 'Overdue',
                        color: paidOk ? AppColors.positiveText : AppColors.overdueText),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            TimelineCard(
              title: 'Lease',
              action: LinkText('Edit lease', onTap: () => context.push(Routes.add('lease', editId: l.id))),
              children: [
                TimelineRow(title: 'Lease start', meta: Dates.dMy(l.start), color: AppColors.accent, last: false),
                TimelineRow(
                    title: 'Renewal window',
                    meta: l.renewalWindowOpens.isAfter(today) ? 'Opens ${Dates.dMy(l.renewalWindowOpens)}' : 'Open now',
                    color: AppColors.blue200,
                    last: false),
                TimelineRow(title: 'Lease end', meta: Dates.dMy(l.end), color: AppColors.ink, last: true),
              ],
            ),
            const SizedBox(height: 14),
            TenantPaymentHistory(charges: charges),
            const SizedBox(height: 14),
            DocumentsStrip(docs: docs, onAdd: () => context.push(Routes.add('document', propertyId: l.propertyId))),
            const SizedBox(height: 14),
            SurfaceCard(
              radius: AppRadius.list,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Notes', style: AppType.cardTitle),
                  const Spacer(),
                  LinkText('Edit', onTap: () => context.push(Routes.add('tenant', editId: t?.id))),
                ]),
                const SizedBox(height: 8),
                Text(
                  [t?.notes ?? '', l.notes, if ((t?.emergencyContact ?? '').isNotEmpty) 'Emergency: ${t!.emergencyContact}']
                          .where((s) => s.isNotEmpty)
                          .join('\n\n')
                          .ifEmpty('No notes yet.'),
                  style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.ink),
                ),
              ]),
            ),
          ]),
        ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
