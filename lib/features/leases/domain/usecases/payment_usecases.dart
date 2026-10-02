import '../../../../core/data/repository.dart';
import '../../../../core/utils/clock.dart';
import '../../../finance/domain/ledger_entry.dart';
import '../../../tenants/domain/tenant.dart';
import '../lease.dart';
import '../rent_charge.dart';
import '../rent_schedule.dart';

/// Edit / delete a rent payment. The linked ledger income (id `inc_{charge}`)
/// is kept in step so cash flow and reports stay correct.
class PaymentActions {
  PaymentActions(this._charges, this._ledger);

  final Repository<RentCharge> _charges;
  final Repository<LedgerEntry> _ledger;

  Future<void> edit(
    String id, {
    required int amount,
    required DateTime dueDate,
    DateTime? paidAt,
    PaymentMethod? method,
    String notes = '',
  }) async {
    final c = _charges.byId(id);
    if (c == null) return;
    final updated = c.copyWith(
      amount: amount,
      dueDate: dueDate,
      paidAt: paidAt,
      paymentMethod: method?.label,
      notes: notes,
    );
    await _charges.upsert(updated);
    final entry = _ledger.byId('inc_$id');
    if (entry != null) {
      await _ledger.upsert(entry.copyWith(amount: amount, date: paidAt ?? entry.date, method: method));
    }
  }

  /// Reverts a paid charge to unpaid and removes its income entry.
  Future<void> markUnpaid(String id) async {
    final c = _charges.byId(id);
    if (c == null) return;
    await _charges.upsert(c.copyWith(clearPaid: true));
    await _ledger.delete('inc_$id');
  }

  Future<void> delete(String id) async {
    await _charges.delete(id);
    await _ledger.delete('inc_$id');
  }
}

/// Edit a lease: saves terms and rebuilds only the *future unpaid* charges,
/// so paid history is never rewritten.
class UpdateLease {
  UpdateLease(this._leases, this._tenants, this._charges, this._clock);

  final Repository<Lease> _leases;
  final Repository<Tenant> _tenants;
  final Repository<RentCharge> _charges;
  final Clock _clock;

  Future<void> call(Lease updated, {Tenant? tenant}) async {
    await _leases.upsert(updated);
    if (tenant != null) await _tenants.upsert(tenant);
    final today = _clock.today();
    final existing = _charges.snapshot.where((c) => c.leaseId == updated.id).toList();
    for (final c in existing) {
      if (!c.isPaid && !c.dueDate.isBefore(today)) await _charges.delete(c.id);
    }
    final keep = {for (final c in _charges.snapshot.where((c) => c.leaseId == updated.id)) c.id};
    final fresh = RentSchedule.build(updated).where((c) => !c.dueDate.isBefore(today) && !keep.contains(c.id));
    await _charges.upsertAll(fresh);
  }
}
