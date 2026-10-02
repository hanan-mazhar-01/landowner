import '../../../app/theme/app_colors.dart';
import '../../leases/domain/lease.dart';
import '../../leases/domain/rent_charge.dart';

enum TenancyStatus {
  active('Active', Tone.ok),
  paymentDue('Payment due', Tone.warn),
  overdue('Overdue', Tone.bad),
  leaseEnding('Lease ending', Tone.info),
  former('Former', Tone.neutral);

  const TenancyStatus(this.label, this.tone);
  final String label;
  final Tone tone;
}

/// One tenancy (tenant + lease) with its derived status.
class Tenancy {
  const Tenancy({required this.lease, required this.status, this.nextDue, this.overdue = const []});
  final Lease lease;
  final TenancyStatus status;
  final RentCharge? nextDue;
  final List<RentCharge> overdue;

  static const dueWindowDays = 7;
  static const endingWindowDays = 60;

  static Tenancy of(Lease l, List<RentCharge> charges, DateTime today) {
    final mine = charges.where((c) => c.leaseId == l.id).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final overdue = mine.where((c) => c.statusOn(today) == RentStatus.overdue).toList();
    final unpaid = mine.where((c) => !c.isPaid && c.statusOn(today) != RentStatus.overdue);
    final next = unpaid.isEmpty ? null : unpaid.first;
    final TenancyStatus status;
    if (!l.isActiveOn(today) && today.isAfter(l.end)) {
      status = overdue.isEmpty ? TenancyStatus.former : TenancyStatus.overdue;
    } else if (overdue.isNotEmpty) {
      status = TenancyStatus.overdue;
    } else if (next != null && next.dueDate.difference(today).inDays <= dueWindowDays) {
      status = TenancyStatus.paymentDue;
    } else if (l.end.difference(today).inDays <= endingWindowDays) {
      status = TenancyStatus.leaseEnding;
    } else {
      status = TenancyStatus.active;
    }
    return Tenancy(lease: l, status: status, nextDue: next, overdue: overdue);
  }
}
