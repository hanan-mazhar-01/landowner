import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../../leases/domain/rent_charge.dart';
import 'property_detail_vm.dart';

/// Tenancy card — tenant, rent status and lease progress; or the vacant state.
class TenancyCard extends StatelessWidget {
  const TenancyCard({super.key, required this.vm, required this.today, required this.onMarkRented, this.onOpen});
  final PropertyDetailVm vm;
  final DateTime today;
  final VoidCallback onMarkRented;

  /// Opens the tenant detail (tap anywhere on an occupied tenancy card).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final m = vm.m;
    return SurfaceCard(
      onTap: m.activeLeases.isEmpty ? null : onOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tenancy', style: AppType.cardTitle),
        const SizedBox(height: 14),
        if (m.activeLeases.isNotEmpty) ...[
          Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
              child: Text(vm.initials, style: AppType.num(15).copyWith(color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vm.tenantName, style: AppType.rowTitle),
                const SizedBox(height: 2),
                Text(vm.leaseLine, style: AppType.caption),
              ]),
            ),
            _rentPill(m.rentStatus),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(children: [
                const Positioned.fill(child: ColoredBox(color: AppColors.blue100)),
                FractionallySizedBox(
                  widthFactor: vm.leaseProgress.clamp(.02, 1),
                  child: Container(
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(3))),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text('Lease progress', style: AppType.caption),
            const Spacer(),
            Text(vm.leaseLeft, style: AppType.caption),
          ]),
        ] else ...[
          Text(
              m.vacantSince == null ? 'Vacant' : 'Vacant for ${today.difference(m.vacantSince!).inDays} days',
              style: AppType.rowTitle),
          const SizedBox(height: 6),
          Text(
            m.lastRent > 0
                ? 'Last rent ${Money.k(m.lastRent)}. Add a tenant when a lease is signed.'
                : 'Add a tenant when a lease is signed.',
            style: AppType.meta.copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          SolidButton(label: 'Mark as rented', height: 40, radius: 14, fontSize: 14, padding: 16, onTap: onMarkRented),
        ],
      ]),
    );
  }

  Widget _rentPill(RentStatus? s) => switch (s) {
        RentStatus.overdue => TonePill.tone('Overdue', Tone.bad),
        RentStatus.pending => TonePill.tone('Pending', Tone.warn),
        _ => TonePill.tone('Paid', Tone.ok),
      };
}

/// Vertical timeline used by "Rental timeline" and "Maintenance".
class TimelineCard extends StatelessWidget {
  const TimelineCard({super.key, required this.title, required this.children, this.action});
  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(title, style: AppType.cardTitle), const Spacer(), ?action]),
          const SizedBox(height: 14),
          ...children,
        ]),
      );
}

class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.title,
    required this.meta,
    required this.color,
    required this.last,
    this.hollow = false,
    this.dots = const [],
    this.trailing,
  });

  final String title, meta;
  final Color color;
  final bool last, hollow;
  final List<Color> dots;
  final String? trailing;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 12,
            child: Column(children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hollow ? AppColors.white : color,
                  border: hollow ? Border.all(color: color, width: 3) : null,
                ),
              ),
              Expanded(child: Container(width: 2, color: last ? AppColors.transparent : AppColors.divider)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: AppType.rowTitle.copyWith(height: 1.1)),
                      const SizedBox(height: 2),
                      Text(meta, style: AppType.caption),
                    ]),
                  ),
                  if (trailing != null && trailing!.isNotEmpty)
                    Text(trailing!, style: AppType.num(14, FontWeight.w700)),
                ]),
                if (dots.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    for (var i = 0; i < dots.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                            height: 8, decoration: BoxDecoration(color: dots[i], borderRadius: BorderRadius.circular(4))),
                      ),
                    ],
                  ]),
                ],
              ]),
            ),
          ),
        ]),
      );
}
