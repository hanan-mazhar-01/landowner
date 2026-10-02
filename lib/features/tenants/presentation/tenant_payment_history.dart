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
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/toast.dart';
import '../../../shared/providers/usecases.dart';
import '../../leases/domain/rent_charge.dart';

TonePill rentPill(RentStatus s, {double fontSize = 11}) => switch (s) {
      RentStatus.overdue => TonePill.tone('Overdue', Tone.bad, fontSize: fontSize),
      RentStatus.pending => TonePill.tone('Pending', Tone.warn, fontSize: fontSize),
      RentStatus.paid => TonePill.tone('Paid', Tone.ok, fontSize: fontSize),
    };

/// Payment history card: period, amount, due, paid, method, status.
/// Tap opens Payment detail (view / edit); unpaid rows offer Mark paid.
class TenantPaymentHistory extends ConsumerStatefulWidget {
  const TenantPaymentHistory({super.key, required this.charges});
  final List<RentCharge> charges;

  @override
  ConsumerState<TenantPaymentHistory> createState() => _TenantPaymentHistoryState();
}

class _TenantPaymentHistoryState extends ConsumerState<TenantPaymentHistory> {
  int _shown = 6;

  @override
  Widget build(BuildContext context) {
    final today = ref.read(clockProvider).today();
    final list = widget.charges.where((c) => !c.dueDate.isAfter(today.add(const Duration(days: 35)))).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return SurfaceCard(
      radius: AppRadius.card,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Payment history', style: AppType.cardTitle),
        const SizedBox(height: 8),
        for (final (i, c) in list.take(_shown).indexed)
          Pressable(
            onTap: () => context.push(Routes.payment(c.id)),
            scale: .99,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.dividerSoft))),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${Dates.month(c.period)} ${c.period.year}', style: AppType.rowTitle),
                    const SizedBox(height: 2),
                    Text(
                      c.isPaid
                          ? 'Due ${Dates.dM(c.dueDate)} · paid ${Dates.dM(c.paidAt!)} · ${c.paymentMethod ?? 'Bank'}'
                          : 'Due ${Dates.dM(c.dueDate)}',
                      style: AppType.caption,
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(Money.k(c.amount), style: AppType.num(15, FontWeight.w700)),
                  const SizedBox(height: 5),
                  if (c.isPaid || c.dueDate.isAfter(today))
                    rentPill(c.statusOn(today))
                  else
                    LinkText('Mark paid', size: 12, onTap: () async {
                      await ref.read(recordRentPaymentProvider)(c.id);
                      ref.read(toastProvider.notifier).show('${Money.full(c.amount)} recorded · cash flow updated');
                    }),
                ]),
              ]),
            ),
          ),
        if (list.length > _shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: LinkText('Show ${list.length - _shown} more', onTap: () => setState(() => _shown += 12)),
          ),
        if (list.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('No payments yet.')),
      ]),
    );
  }
}
