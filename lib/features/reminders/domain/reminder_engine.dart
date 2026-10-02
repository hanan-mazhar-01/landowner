import '../../../core/utils/formatters.dart';
import '../../documents/domain/document_item.dart';
import '../../leases/domain/lease.dart';
import '../../leases/domain/rent_charge.dart';
import '../../maintenance/domain/maintenance_ticket.dart';
import '../../properties/domain/property.dart';
import '../../tenants/domain/tenant.dart';
import 'reminder.dart';

/// Everything the engine reads. Pure data, so the same engine can run on the
/// device or inside a Cloud Function.
class ReminderInputs {
  const ReminderInputs({
    required this.today,
    required this.properties,
    required this.tenants,
    required this.leases,
    required this.charges,
    required this.maintenance,
    required this.documents,
  });

  final DateTime today;
  final List<Property> properties;
  final List<Tenant> tenants;
  final List<Lease> leases;
  final List<RentCharge> charges;
  final List<MaintenanceTicket> maintenance;
  final List<DocumentItem> documents;
}

/// Centralised reminder derivation. Every auto reminder has a stable
/// `sourceKey`; [reconcile] merges by key so nothing is ever duplicated and
/// user state (done / snoozed / muted) survives re-derivation.
abstract final class ReminderEngine {
  static const _lookahead = 45;
  static const _leaseWindow = 120;
  static const _docWindow = 60;

  static List<Reminder> derive(ReminderInputs i) {
    final tenants = {for (final t in i.tenants) t.id: t};
    final leases = {for (final l in i.leases) l.id: l};
    final horizon = i.today.add(const Duration(days: _lookahead));
    final out = <Reminder>[];

    // Rent — one reminder per property per due date (multi-unit leases grouped).
    final groups = <String, List<RentCharge>>{};
    for (final c in i.charges) {
      if (c.isPaid || c.dueDate.isBefore(i.today) || c.dueDate.isAfter(horizon)) continue;
      final key = 'rent:${c.propertyId}:${c.dueDate.year}${c.dueDate.month}${c.dueDate.day}';
      groups.putIfAbsent(key, () => []).add(c);
    }
    groups.forEach((key, cs) {
      final c = cs.first;
      final lease = leases[c.leaseId];
      final t = tenants[c.tenantId];
      final total = cs.fold(0, (s, e) => s + e.amount);
      final timing = (lease?.reminderOffsets ?? const {}).map((o) => o.label.toLowerCase()).join(', ');
      out.add(Reminder(
        id: key,
        sourceKey: key,
        type: ReminderType.rent,
        title: 'Rent due',
        propertyId: c.propertyId,
        amountLabel: Money.full(total),
        at: c.dueDate.add(const Duration(hours: 9)),
        repeat: RepeatRule.monthly,
        sourceLabel: cs.length > 1
            ? 'Auto · from ${cs.length} leases'
            : 'Auto · from ${t?.name ?? 'tenant'}’s lease${timing.isEmpty ? '' : ' · $timing'}',
      ));
    });

    // Payment overdue — one per charge whose grace period has ended.
    for (final c in i.charges) {
      if (c.statusOn(i.today) != RentStatus.overdue) continue;
      final key = 'overdue:${c.id}';
      final t = tenants[c.tenantId];
      out.add(Reminder(
        id: key,
        sourceKey: key,
        type: ReminderType.rent,
        title: 'Payment overdue',
        propertyId: c.propertyId,
        amountLabel: Money.full(c.amount),
        at: DateTime(i.today.year, i.today.month, i.today.day, 9),
        sourceLabel: 'Auto · ${c.daysLate(i.today)} days late${t == null ? '' : ' · ${t.name}'}',
        target: '/overdue/${c.id}',
      ));
    }

    // Lease expirations inside the window.
    for (final l in i.leases) {
      final days = l.end.difference(i.today).inDays;
      if (days < 0 || days > _leaseWindow) continue;
      final key = 'lease:${l.id}';
      out.add(Reminder(
        id: key,
        sourceKey: key,
        type: ReminderType.lease,
        title: 'Lease expires',
        propertyId: l.propertyId,
        at: DateTime(l.end.year, l.end.month, l.end.day, 9),
        sourceLabel: 'Auto · from lease end date',
        notes: 'Discuss renewal terms with ${tenants[l.tenantId]?.firstName ?? 'the tenant'}.',
      ));
    }

    // Scheduled maintenance.
    for (final m in i.maintenance) {
      if (m.isDone || !m.remindBefore || m.scheduledFor.isBefore(i.today)) continue;
      final key = 'maint:${m.id}';
      out.add(Reminder(
        id: key,
        sourceKey: key,
        type: ReminderType.maintenance,
        title: m.title,
        propertyId: m.propertyId,
        amountLabel: m.estimatedCost > 0 ? 'Est. ${Money.k(m.estimatedCost)}' : '',
        at: DateTime(m.scheduledFor.year, m.scheduledFor.month, m.scheduledFor.day, 11),
        sourceLabel: 'Auto · from maintenance ticket',
      ));
    }

    // Document & insurance expiry.
    for (final d in i.documents) {
      final days = d.daysToExpiry(i.today);
      if (days == null || days < 0 || days > _docWindow || d.type == DocumentType.lease) continue;
      final key = 'doc:${d.id}';
      final insurance = d.type == DocumentType.insurance;
      out.add(Reminder(
        id: key,
        sourceKey: key,
        type: insurance ? ReminderType.insurance : ReminderType.document,
        title: insurance ? 'Insurance renewal' : '${d.type.label} expires',
        propertyId: d.propertyId,
        at: DateTime(d.expiry!.year, d.expiry!.month, d.expiry!.day, 10),
        repeat: insurance ? RepeatRule.yearly : RepeatRule.none,
        sourceLabel: insurance ? 'Auto · from policy expiry date' : 'Auto · from document expiry date',
      ));
    }

    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  /// Merge derived reminders into the stored set.
  /// Returns (toUpsert, idsToDelete).
  static (List<Reminder>, List<String>) reconcile(List<Reminder> stored, List<Reminder> derived) {
    final byKey = {for (final r in stored) if (r.sourceKey != null) r.sourceKey!: r};
    final derivedKeys = derived.map((r) => r.sourceKey!).toSet();
    final upserts = <Reminder>[];
    for (final d in derived) {
      final existing = byKey[d.sourceKey];
      if (existing == null) {
        upserts.add(d);
      } else if (existing.at != d.at && !existing.snoozed && !d.sourceKey!.startsWith('overdue:')) {
        upserts.add(d.copyWith(done: existing.done, notify: existing.notify, notes: existing.notes));
      }
    }
    final deletes = [
      for (final r in stored)
        if (r.sourceKey != null && !derivedKeys.contains(r.sourceKey) && !r.done) r.id,
    ];
    return (upserts, deletes);
  }
}
