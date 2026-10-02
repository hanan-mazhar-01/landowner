import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/collections.dart';
import '../../../../shared/providers/portfolio.dart';
import '../../../ai/domain/insight_engine.dart';
import '../../../documents/domain/document_item.dart';
import '../../../leases/domain/lease.dart';
import '../../../leases/domain/rent_charge.dart';
import '../../domain/property_metrics.dart';

class TimelineEvent {
  const TimelineEvent(this.title, this.meta, this.color, [this.dots = const []]);
  final String title, meta;
  final Color color;
  final List<Color> dots;
}

class MaintRow {
  const MaintRow(this.title, this.meta, this.cost, this.color);
  final String title, meta, cost;
  final Color color;
}

class DocChip {
  const DocChip(this.name, this.meta, this.color, [this.id, this.kind = 'FILE']);
  final String name, meta;

  /// File badge — "PDF", "IMG", "FILE" or "NO FILE".
  final String kind;
  final Color color;
  final String? id;
}

/// Everything the property detail screen renders, derived in one place.
class PropertyDetailVm {
  const PropertyDetailVm({
    required this.m,
    required this.tenantName,
    required this.initials,
    required this.leaseLine,
    required this.leaseProgress,
    required this.leaseLeft,
    required this.timeline,
    required this.maintenance,
    required this.documents,
    required this.insight,
    this.focusCharge,
  });

  final PropertyMetrics m;
  final String tenantName, initials, leaseLine, leaseLeft, insight;
  final double leaseProgress;
  final List<TimelineEvent> timeline;
  final List<MaintRow> maintenance;
  final List<DocChip> documents;

  /// The overdue charge driving "Resolve overdue", if any.
  final RentCharge? focusCharge;
}

final propertyDetailProvider = Provider.autoDispose.family<PropertyDetailVm?, String>((ref, id) {
  final m = ref.watch(metricsForProvider(id));
  if (m == null) return null;
  final today = ref.read(clockProvider).today();
  final tenants = {for (final t in ref.watch(tenantsProvider).value ?? const []) t.id: t};
  final charges = ref.watch(chargesProvider).value ?? const <RentCharge>[];
  final ledger = ref.watch(ledgerProvider).value ?? const [];

  final active = [...m.activeLeases]..sort((a, b) => a.start.compareTo(b.start));
  final overdue = m.overdue.isEmpty ? null : m.overdue.first;
  final Lease? focus = overdue == null ? active.firstOrNull : active.where((l) => l.id == overdue.leaseId).firstOrNull;
  final tenant = focus == null ? null : tenants[focus.tenantId];
  final multi = active.length > 1;
  final nextEnd = active.isEmpty ? null : active.map((l) => l.end).reduce((a, b) => a.isBefore(b) ? a : b);
  final monthsLeft = focus == null ? 0 : ((focus.end.difference(today).inDays) / 30.4).round();

  final timeline = <TimelineEvent>[];
  if (focus != null) {
    final due = charges.where((c) => c.leaseId == focus.id && !c.dueDate.isAfter(today)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final last9 = due.length > 9 ? due.sublist(due.length - 9) : due;
    final paidCount = last9.where((c) => c.isPaid).length;
    final late = last9.where((c) => c.paidLate()).toList();
    final onTime = paidCount - late.length;
    final overdueCount = last9.where((c) => c.statusOn(today) == RentStatus.overdue).length;
    final onTimePart = onTime > 0 ? '$onTime on time · ' : '';
    final (String paymentsMeta, Color paymentsColor) = overdueCount > 0
        ? ('$onTimePart$overdueCount overdue', AppColors.overdue)
        : paidCount == 0
            ? ('No payments recorded yet', AppColors.blue300)
            : late.isNotEmpty
                ? ('$onTimePart${late.length} paid late (${Dates.mon(late.first.dueDate)})', AppColors.attention)
                : ('All paid on time', AppColors.positive);
    final next = m.nextDue;
    final unit = focus.unitLabel;
    final reminder = _reminderMeta(focus.reminderOffsets);
    timeline.addAll([
      TimelineEvent('Lease started', '${Dates.my(focus.start)} · ${tenant?.name ?? ''}', AppColors.accent),
      TimelineEvent('Rent payments', paymentsMeta, paymentsColor, [
        for (final c in last9)
          switch (c.statusOn(today)) {
            RentStatus.paid => c.paidLate() ? AppColors.attention : AppColors.positive,
            RentStatus.overdue => AppColors.overdue,
            RentStatus.pending => AppColors.blue200,
          },
      ]),
      if (overdue != null)
        TimelineEvent('Overdue${unit == null ? '' : ' · $unit'}',
            '${Money.full(overdue.amount)} · due ${Dates.dM(overdue.dueDate)} · ${overdue.daysLate(today)} days late',
            AppColors.overdue)
      else if (next != null)
        TimelineEvent('Next rent due', '${Dates.dMy(next.dueDate)}${reminder.isEmpty ? '' : ' · $reminder'}',
            AppColors.blue300),
      TimelineEvent('Renewal window',
          focus.renewalWindowOpens.isAfter(today) ? 'Opens ${Dates.my(focus.renewalWindowOpens)}' : 'Open now',
          AppColors.blue200),
      TimelineEvent('Lease ends', Dates.my(focus.end), AppColors.ink),
    ]);
  }

  final tickets = (ref.watch(maintenanceProvider).value ?? const []).where((t) => t.propertyId == id).toList()
    ..sort((a, b) => a.isDone == b.isDone ? b.scheduledFor.compareTo(a.scheduledFor) : (a.isDone ? 1 : -1));
  final maint = [
    for (final t in tickets.take(3))
      MaintRow(
        t.title,
        t.isDone
            ? 'Completed · ${Dates.ddM(t.scheduledFor)}'
            : t.priority.isSevere
                ? '${t.priority.label} priority · opened ${Dates.dM(t.createdAt)}'
                : t.status.label == 'In progress'
                    ? 'In progress · since ${Dates.dM(t.createdAt)}'
                    : 'Scheduled · ${Dates.ddM(t.scheduledFor)}',
        t.cost > 0 ? Money.k(t.cost) : '',
        t.isDone ? AppColors.positive : (t.priority.isSevere ? AppColors.overdue : AppColors.accent),
      ),
  ];

  final docs = [
    for (final d in (ref.watch(documentsProvider).value ?? const <DocumentItem>[]).where((d) => d.propertyId == id))
      _docChip(d, today),
  ];

  final all = ref.watch(propertyMetricsProvider);
  final paidHere = charges.where((c) => c.propertyId == id && c.isPaid);
  var insight = InsightEngine.forProperty(
      m: m, all: all, charges: charges, ledger: ledger, today: today, overdueUnit: focus?.unitLabel);
  if (m.overdue.isEmpty && m.activeLeases.isNotEmpty && paidHere.isEmpty) {
    // No payment history yet — never claim an on-time streak of "0 months".
    insight = m.yieldPct > 0
        ? 'At the current rent this property yields ${m.yieldPct.toStringAsFixed(1)}% on its value. '
            'Record the first rent payment to start tracking reliability.'
        : 'Record the first rent payment to start tracking reliability.';
  } else {
    insight = insight
        .replaceAll(RegExp(r' The other \S+ units have paid on time for 0 consecutive months\.'), '')
        .replaceAll('Rent has been paid on time for 0 months.', 'The most recent rent payment arrived after the grace period.')
        .replaceAll('paid on time for 1 months', 'paid on time for 1 month')
        .replaceAll('for 1 consecutive months', 'for 1 consecutive month');
  }

  return PropertyDetailVm(
    m: m,
    tenantName: tenant == null ? '' : '${tenant.name}${multi ? ' + ${active.length - 1} units' : ''}',
    initials: tenant?.initials ?? '',
    leaseLine: focus == null
        ? ''
        : multi
            ? '${active.length} leases · next renewal ${Dates.my(nextEnd!)}'
            : 'Lease · ${Dates.my(focus.start)} – ${Dates.my(focus.end)}',
    leaseProgress: focus?.progressOn(today) ?? 0,
    leaseLeft: overdue != null && focus?.unitLabel != null
        ? '${focus!.unitLabel} · ${Money.k(overdue.amount)} due'
        : '$monthsLeft months left',
    timeline: timeline,
    maintenance: maint,
    documents: docs,
    insight: insight,
    focusCharge: overdue,
  );
});

/// "reminder 3 days before" / "reminder on due date" from the lease's
/// earliest reminder offset; empty when reminders are off.
String _reminderMeta(Set<ReminderOffset> offsets) {
  if (offsets.isEmpty) return '';
  final first = offsets.reduce((a, b) => a.days >= b.days ? a : b);
  final label = first.label.toLowerCase();
  return 'reminder $label';
}

DocChip _docChip(DocumentItem d, DateTime today) {
  final days = d.daysToExpiry(today);
  if (d.verified) return DocChip(d.name, 'Verified', AppColors.positiveText, d.id, d.fileKindLabel);
  if (days != null && days < 0) return DocChip(d.name, 'Expired', AppColors.overdueText, d.id, d.fileKindLabel);
  if (d.type == DocumentType.insurance && days != null) {
    return days <= 30
        ? DocChip(d.name, 'Renew in $days days', AppColors.attentionText, d.id, d.fileKindLabel)
        : DocChip(d.name, 'Renews ${Dates.my(d.expiry!)}', AppColors.textMuted, d.id, d.fileKindLabel);
  }
  if (d.expiry != null) return DocChip(d.name, 'Expires ${Dates.my(d.expiry!)}', AppColors.textMuted, d.id, d.fileKindLabel);
  if (d.fileCount > 1) return DocChip(d.name, '${d.fileCount} files · ${d.date.year}', AppColors.textMuted, d.id, d.fileKindLabel);
  return DocChip(d.name, Dates.dMy(d.date), AppColors.textMuted, d.id, d.fileKindLabel);
}
