import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../shared/widgets/contact_tiles.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/portfolio.dart';
import '../../../shared/providers/usecases.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../domain/rent_charge.dart';

class OverdueRentScreen extends ConsumerWidget {
  const OverdueRentScreen({super.key, required this.chargeId});
  final String chargeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charges = ref.watch(chargesProvider).value ?? const <RentCharge>[];
    final c = charges.where((x) => x.id == chargeId).firstOrNull;
    final top = MediaQuery.paddingOf(context).top + 8;
    final back = Padding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircleIconButton(icon: HomelyIcons.back, onTap: () => context.pop(), semanticLabel: 'Back'),
      ),
    );
    if (c == null) {
      return ColoredBox(
        color: AppColors.background,
        child: Column(children: [
          back,
          const Expanded(child: Center(child: EmptyStateCard(title: 'Nothing overdue', message: 'This rent charge no longer exists.'))),
        ]),
      );
    }

    final today = ref.read(clockProvider).today();
    final prop = ref.watch(propertyByIdProvider(c.propertyId));
    final tenant = ref.watch(tenantByIdProvider(c.tenantId));
    final lease = (ref.watch(leasesProvider).value ?? const []).where((l) => l.id == c.leaseId).firstOrNull;
    final history = charges.where((x) => x.leaseId == c.leaseId && x.isPaid).toList();
    final onTime = history.where((x) => !x.paidLate()).length;
    final reliability = history.isEmpty
        ? 'no payment history yet'
        : onTime / history.length >= .85
            ? 'usually pays on time'
            : 'has paid late before';
    final place = '${prop?.name ?? ''}${lease?.unitLabel == null ? '' : ' · ${lease!.unitLabel}'}';
    final month = ref.watch(thisMonthProvider);
    final firstName = tenant?.firstName ?? 'there';
    final note = 'Hi $firstName, a reminder that ${Dates.month(c.dueDate)} rent of ${Money.full(c.amount)}'
        '${lease?.unitLabel == null ? '' : ' for ${lease!.unitLabel}'} was due on ${Dates.dM(c.dueDate)}.';

    Widget cell(String l, String v, {Color? color}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: AppType.micro),
            const SizedBox(height: 2),
            Text(v, style: AppType.num(14, FontWeight.w700).copyWith(color: color ?? AppColors.ink)),
          ]),
        );
    final open = !c.isPaid;
    return ColoredBox(
      color: AppColors.background,
      child: Column(children: [
        back,
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 20), children: [
            if (open) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TonePill.tone('Overdue · ${c.daysLate(today)} days', Tone.bad, dot: true),
                  const SizedBox(height: 8),
                  Text('Rent overdue', style: AppType.title30),
                  const SizedBox(height: 8),
                  Text(place, style: AppType.body15),
                ]),
              ),
              const SizedBox(height: 14),
              SurfaceCard(
                radius: AppRadius.review,
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Amount due', style: AppType.caption),
                  const SizedBox(height: 2),
                  FittedBox(child: Text(Money.full(c.amount), style: AppType.value44)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.dividerSoft))),
                    child: Row(children: [
                      cell('Due date', Dates.dMy(c.dueDate)),
                      cell('Grace ended', Dates.dM(c.graceEnds)),
                      cell('Days late', '${c.daysLate(today)}', color: AppColors.overdueText),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              SurfaceCard(
                radius: AppRadius.review,
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
                      child: Text(tenant?.initials ?? '', style: AppType.num(15).copyWith(color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tenant?.name ?? 'Tenant', style: AppType.rowTitle),
                        const SizedBox(height: 2),
                        Text(
                          'Tenant since ${Dates.my(lease?.start ?? c.dueDate)} · $reliability',
                          style: AppType.caption,
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  ContactTiles(phone: tenant?.phone ?? '', message: note),
                  const SizedBox(height: 16),
                  Text('Opens your phone, Messages or WhatsApp with a drafted note. Nothing is sent until you tap send.',
                      style: AppType.caption.copyWith(height: 1.45)),
                ]),
              ),
            ] else
              Entrance.fadeUp(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 40, 8, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: AppColors.positiveTint, shape: BoxShape.circle),
                        child: const Center(
                            child: HomelyIcon(HomelyIcons.check, size: 30, strokeWidth: 2.4, color: AppColors.positiveText)),
                      ),
                      const SizedBox(height: 12),
                      Text('${Money.full(c.amount)} recorded', style: AppType.title30),
                      const SizedBox(height: 12),
                      Text(
                        '$place is paid for ${Dates.month(c.dueDate)}. Income, property financials and portfolio cash flow have been updated.',
                        style: AppType.body15,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  SurfaceCard(
                    radius: AppRadius.list,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Column(children: [
                      _kv('${Dates.month(today)} income', Money.compact(month.income), border: true),
                      _kv('Net cash flow', Money.compact(month.net), color: AppColors.primary),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
        BottomActionBar(
          child: open
              ? GradientCta(
                  label: 'Mark as paid',
                  shadow: const [],
                  trailing: Text(Money.full(c.amount),
                      style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: .8))),
                  onTap: () => ref.read(recordRentPaymentProvider)(c.id),
                )
              : Pressable(
                  onTap: () => context.go(Routes.finance),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.cta)),
                    child: Row(children: [
                      Text('See updated cash flow', style: AppType.buttonSm.copyWith(color: AppColors.white)),
                      const Spacer(),
                      const HomelyIcon(HomelyIcons.arrowRight, size: 20, color: AppColors.white),
                    ]),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _kv(String k, String v, {bool border = false, Color color = AppColors.ink}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: border ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.dividerSoft))) : null,
        child: Row(children: [
          Text(k, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          const Spacer(),
          Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}
