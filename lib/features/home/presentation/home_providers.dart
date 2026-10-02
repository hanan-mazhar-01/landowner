import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/icons/homely_icons.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/portfolio.dart';
import '../../documents/domain/document_item.dart';
import '../../leases/domain/rent_charge.dart';

@immutable
class AttentionItem {
  const AttentionItem(this.title, this.subtitle, this.when, this.tone, this.icon, this.route);
  final String title, subtitle, when;
  final Tone tone;
  final HomelyIcons icon;
  final String route;
}

String _days(int d) => switch (d) { <= 0 => 'Today', 1 => 'Tomorrow', _ => '$d days' };

/// "Needs your attention": overdue rent, rent due soon, leases ending, urgent
/// maintenance, expiring insurance — all derived from live data.
final attentionProvider = Provider<List<AttentionItem>>((ref) {
  final today = ref.read(clockProvider).today();
  final summary = ref.watch(portfolioSummaryProvider);
  final tenants = {for (final t in ref.watch(tenantsProvider).value ?? const []) t.id: t};
  final leases = {for (final l in ref.watch(leasesProvider).value ?? const []) l.id: l};
  final names = {for (final m in summary.metrics) m.property.id: m.property.name};
  final out = <AttentionItem>[];
  String unitOf(String leaseId) {
    final u = leases[leaseId]?.unitLabel;
    return u == null ? '' : ' $u';
  }

  for (final c in summary.overdue) {
    out.add(AttentionItem(
      'Rent overdue',
      '${names[c.propertyId] ?? ''}${unitOf(c.leaseId)} · ${tenants[c.tenantId]?.name ?? ''} · ${Money.k(c.amount)}',
      '${c.daysLate(today)} days',
      Tone.bad,
      HomelyIcons.alert,
      Routes.overdue(c.id),
    ));
  }
  // Unpaid rent due within 3 days, or past due but still inside the grace period.
  int daysUntil(RentCharge c) => DateTime(c.dueDate.year, c.dueDate.month, c.dueDate.day).difference(today).inDays;
  final dueSoon = (ref.watch(chargesProvider).value ?? const <RentCharge>[])
      .where((c) => names.containsKey(c.propertyId) && c.statusOn(today) == RentStatus.pending && daysUntil(c) <= 3)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  for (final c in dueSoon) {
    final d = daysUntil(c);
    out.add(AttentionItem(
      d < 0 ? 'Rent not yet received' : (d == 0 ? 'Rent due today' : 'Rent due in $d ${d == 1 ? 'day' : 'days'}'),
      '${names[c.propertyId] ?? ''}${unitOf(c.leaseId)} · ${tenants[c.tenantId]?.name ?? ''} · ${Money.k(c.amount)}',
      d < 0 ? 'In grace' : _days(d),
      d < 0 ? Tone.warn : Tone.info,
      HomelyIcons.coin,
      Routes.payment(c.id),
    ));
  }
  for (final l in leases.values) {
    final d = l.end.difference(today).inDays;
    if (d < 0 || d > 100 || !l.isActiveOn(today)) continue;
    out.add(AttentionItem('Lease ends soon', '${names[l.propertyId] ?? ''} · ${tenants[l.tenantId]?.name ?? ''}',
        _days(d), Tone.warn, HomelyIcons.calendar, Routes.property(l.propertyId)));
  }
  for (final m in ref.watch(maintenanceProvider).value ?? const []) {
    if (m.isDone || !m.priority.isSevere) continue;
    out.add(AttentionItem(m.title,
        '${names[m.propertyId] ?? ''} · ${m.priority.label.toLowerCase()} priority',
        _days(m.scheduledFor.difference(today).inDays), Tone.warn, HomelyIcons.wrench, Routes.property(m.propertyId)));
  }
  for (final d in ref.watch(documentsProvider).value ?? const []) {
    final days = d.daysToExpiry(today);
    if (d.type != DocumentType.insurance || days == null || days < 0 || days > 30) continue;
    out.add(AttentionItem('Insurance renewal', '${names[d.propertyId] ?? ''} · ${d.name}', _days(days), Tone.info,
        HomelyIcons.shield, Routes.property(d.propertyId)));
  }
  return out;
});

@immutable
class ActivityItem {
  const ActivityItem(this.title, this.subtitle, this.amount, this.income);
  final String title, subtitle;
  final int amount;
  final bool income;
}

/// Latest ledger movements.
final recentActivityProvider = Provider.family<List<ActivityItem>, int>((ref, count) {
  final today = ref.read(clockProvider).today();
  final ledger = [...?ref.watch(ledgerProvider).value]..sort((a, b) => b.date.compareTo(a.date));
  final names = {for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
  final tenants = {for (final t in ref.watch(tenantsProvider).value ?? const []) t.id: t.name};
  return [
    for (final e in ledger.take(count))
      ActivityItem(
        e.isIncome && e.title == 'Rent' ? 'Rent received' : e.title,
        '${e.isIncome && e.tenantId != null ? tenants[e.tenantId] ?? '' : names[e.propertyId] ?? ''} · ${Dates.relativeDay(e.date, today)}',
        e.amount,
        e.isIncome,
      ),
  ];
});
