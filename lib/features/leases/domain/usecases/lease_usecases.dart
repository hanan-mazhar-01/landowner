import '../../../../core/data/repository.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../finance/domain/ledger_entry.dart';
import '../../../notifications/domain/app_notification.dart';
import '../../../properties/domain/property.dart';
import '../../../tenants/domain/tenant.dart';
import '../lease.dart';
import '../rent_charge.dart';
import '../rent_schedule.dart';

class LeaseDraft {
  const LeaseDraft({
    required this.propertyId,
    required this.tenantName,
    this.phone = '',
    this.email = '',
    this.emergencyContact = '',
    required this.rent,
    required this.deposit,
    required this.start,
    required this.end,
    required this.dueDay,
    required this.frequency,
    required this.firstPayment,
    required this.graceDays,
    required this.offsets,
    this.notes = '',
  });

  final String propertyId, tenantName, phone, email, emergencyContact, notes;
  final int rent, deposit, dueDay, graceDays;
  final DateTime start, end;
  final PaymentFrequency frequency;
  final RentStatus firstPayment;
  final Set<ReminderOffset> offsets;
}

/// Property → Tenant → Lease → Rent schedule → (reminders via the engine)
/// → Notification. One call keeps the whole chain consistent.
class CreateLease {
  CreateLease(this._props, this._tenants, this._leases, this._charges, this._ledger, this._notifs, this._clock);

  final Repository<Property> _props;
  final Repository<Tenant> _tenants;
  final Repository<Lease> _leases;
  final Repository<RentCharge> _charges;
  final Repository<LedgerEntry> _ledger;
  final Repository<AppNotification> _notifs;
  final Clock _clock;

  Future<Lease> call(LeaseDraft d) async {
    final now = _clock.now();
    final tenant = Tenant(
      id: newId('t'),
      name: d.tenantName.trim().isEmpty ? 'New tenant' : d.tenantName.trim(),
      phone: d.phone,
      email: d.email,
      emergencyContact: d.emergencyContact,
      createdAt: now,
    );
    final lease = Lease(
      id: newId('l'),
      propertyId: d.propertyId,
      tenantId: tenant.id,
      monthlyRent: d.rent,
      deposit: d.deposit,
      start: d.start,
      end: d.end,
      dueDay: d.dueDay,
      frequency: d.frequency,
      graceDays: d.graceDays,
      reminderOffsets: d.offsets,
      notes: d.notes,
      createdAt: now,
    );
    await _tenants.upsert(tenant);
    await _leases.upsert(lease);

    final schedule = RentSchedule.build(lease);
    if (schedule.isNotEmpty && d.firstPayment == RentStatus.paid) {
      final first = schedule.first.markPaid(now, PaymentMethod.bank.label);
      schedule[0] = first;
      await _ledger.upsert(LedgerEntry(
        id: 'inc_${first.id}',
        kind: EntryKind.income,
        propertyId: lease.propertyId,
        tenantId: tenant.id,
        title: 'Rent',
        amount: first.amount,
        date: now,
        incomeType: IncomeType.rent,
        sourceRef: first.id,
      ));
    }
    await _charges.upsertAll(schedule);

    final p = _props.byId(d.propertyId);
    if (p != null && p.status != PropertyStatus.rented) {
      await _props.upsert(p.copyWith(status: PropertyStatus.rented));
    }
    await _notifs.upsert(AppNotification(
      id: newId('n'),
      category: NotificationCategory.lease,
      title: 'Rent reminders scheduled',
      body: '${p?.name ?? 'Property'} · ${tenant.name} · due ${Dates.ordinal(d.dueDay)} monthly',
      createdAt: now,
      target: '/properties/${d.propertyId}',
      propertyId: d.propertyId,
    ));
    return lease;
  }
}

/// Rent → Payment → Ledger income → cash flow & analytics.
class RecordRentPayment {
  RecordRentPayment(this._charges, this._ledger, this._props, this._notifs, this._clock);

  final Repository<RentCharge> _charges;
  final Repository<LedgerEntry> _ledger;
  final Repository<Property> _props;
  final Repository<AppNotification> _notifs;
  final Clock _clock;

  /// Marks the charge paid and records the income. [amount], [date], [notes]
  /// and [receiptUrl] come from the income form when rent is logged there.
  Future<void> call(
    String chargeId, {
    PaymentMethod method = PaymentMethod.bank,
    int? amount,
    DateTime? date,
    String notes = '',
    String? receiptUrl,
  }) async {
    final c = _charges.byId(chargeId);
    if (c == null || c.isPaid) return;
    final now = _clock.now();
    final paidOn = date ?? now;
    await _charges.upsert(c.markPaid(paidOn, method.label));
    await _ledger.upsert(LedgerEntry(
      id: 'inc_${c.id}',
      kind: EntryKind.income,
      propertyId: c.propertyId,
      tenantId: c.tenantId,
      title: 'Rent',
      amount: amount ?? c.amount,
      date: paidOn,
      incomeType: IncomeType.rent,
      method: method,
      notes: notes,
      receiptUrl: receiptUrl,
      sourceRef: c.id,
    ));
    await _notifs.upsert(AppNotification(
      id: newId('n'),
      category: NotificationCategory.rent,
      title: 'Payment recorded',
      body: '${_props.byId(c.propertyId)?.name ?? ''} · ${Money.full(amount ?? c.amount)} · ${method.label}',
      createdAt: now,
      unread: false,
      target: '/finance',
      propertyId: c.propertyId,
    ));
  }
}
