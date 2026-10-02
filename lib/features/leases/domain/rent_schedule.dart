import '../../../core/utils/formatters.dart';
import 'lease.dart';
import 'rent_charge.dart';

/// Builds the full charge schedule for a lease. Ids are deterministic, so
/// re-running it for the same lease never creates duplicates.
abstract final class RentSchedule {
  static DateTime firstDue(Lease l) {
    var d = _clamped(l.start.year, l.start.month, l.dueDay);
    if (d.isBefore(DateTime(l.start.year, l.start.month, l.start.day))) {
      final n = Dates.addMonths(DateTime(l.start.year, l.start.month), 1);
      d = _clamped(n.year, n.month, l.dueDay);
    }
    return d;
  }

  static List<RentCharge> build(Lease l) {
    final out = <RentCharge>[];
    final step = l.frequency.months;
    final amount = l.monthlyRent * step;
    var due = firstDue(l);
    while (!due.isAfter(l.end)) {
      out.add(RentCharge(
        leaseId: l.id,
        propertyId: l.propertyId,
        tenantId: l.tenantId,
        dueDate: due,
        amount: amount,
        graceDays: l.graceDays,
      ));
      final n = Dates.addMonths(DateTime(due.year, due.month), step);
      due = _clamped(n.year, n.month, l.dueDay);
    }
    return out;
  }

  static DateTime _clamped(int y, int m, int day) {
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, day > last ? last : day);
  }
}
