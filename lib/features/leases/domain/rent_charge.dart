import 'package:flutter/foundation.dart';

enum RentStatus { paid, pending, overdue }

/// One rent period owed under a lease. The id is deterministic
/// (`{leaseId}_{yyyy}{mm}`) so charges can never be duplicated.
@immutable
class RentCharge {
  const RentCharge({
    String? id,
    required this.leaseId,
    required this.propertyId,
    required this.tenantId,
    required this.dueDate,
    required this.amount,
    this.graceDays = 3,
    this.paidAt,
    this.paymentMethod,
    this.notes = '',
  }) : _id = id; // ignore: prefer_initializing_formals

  final String? _id;

  final String leaseId;
  final String propertyId;
  final String tenantId;
  final DateTime dueDate;
  final int amount;
  final int graceDays;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String notes;

  static String idFor(String leaseId, DateTime due) =>
      '${leaseId}_${due.year}${due.month.toString().padLeft(2, '0')}';

  /// Stable once created (editing the due date keeps the same id).
  String get id => _id ?? idFor(leaseId, dueDate);

  /// "September 2026" style period label.
  DateTime get period => DateTime(dueDate.year, dueDate.month);
  bool get isPaid => paidAt != null;
  DateTime get graceEnds => dueDate.add(Duration(days: graceDays));

  /// Paid · Pending (not yet due, or inside the grace period) · Overdue
  /// (grace period has ended — "Grace ended 29 Sep" in the design).
  RentStatus statusOn(DateTime today) {
    if (isPaid) return RentStatus.paid;
    final d = DateTime(today.year, today.month, today.day);
    return d.isAfter(dueDate) && !d.isBefore(graceEnds) ? RentStatus.overdue : RentStatus.pending;
  }

  /// Past the due date but still inside the grace period.
  bool inGrace(DateTime today) {
    final d = DateTime(today.year, today.month, today.day);
    return !isPaid && d.isAfter(dueDate) && d.isBefore(graceEnds);
  }

  int daysLate(DateTime today) {
    final d = DateTime(today.year, today.month, today.day);
    return d.difference(dueDate).inDays.clamp(0, 9999);
  }

  bool paidLate() => paidAt != null && paidAt!.isAfter(graceEnds);

  RentCharge markPaid(DateTime at, String method) => copyWith(paidAt: at, paymentMethod: method);

  RentCharge copyWith({
    DateTime? dueDate,
    int? amount,
    DateTime? paidAt,
    bool clearPaid = false,
    String? paymentMethod,
    String? notes,
  }) =>
      RentCharge(
        id: id,
        leaseId: leaseId,
        propertyId: propertyId,
        tenantId: tenantId,
        dueDate: dueDate ?? this.dueDate,
        amount: amount ?? this.amount,
        graceDays: graceDays,
        paidAt: clearPaid ? null : (paidAt ?? this.paidAt),
        paymentMethod: clearPaid ? null : (paymentMethod ?? this.paymentMethod),
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'leaseId': leaseId,
        'propertyId': propertyId,
        'tenantId': tenantId,
        'dueDate': dueDate.toIso8601String(),
        'amount': amount,
        'graceDays': graceDays,
        'paidAt': paidAt?.toIso8601String(),
        'paymentMethod': paymentMethod,
        'notes': notes,
      };

  factory RentCharge.fromMap(Map<String, dynamic> map, [String? id]) => RentCharge(
        id: id ?? map['id']?.toString(),
        leaseId: map['leaseId']?.toString() ?? '',
        propertyId: map['propertyId']?.toString() ?? '',
        tenantId: map['tenantId']?.toString() ?? '',
        dueDate: DateTime.tryParse(map['dueDate']?.toString() ?? '') ?? DateTime.now(),
        amount: (map['amount'] as num?)?.toInt() ?? 0,
        graceDays: (map['graceDays'] as num?)?.toInt() ?? 3,
        paidAt: map['paidAt'] != null ? DateTime.tryParse(map['paidAt'].toString()) : null,
        paymentMethod: map['paymentMethod']?.toString(),
        notes: map['notes']?.toString() ?? '',
      );
}
