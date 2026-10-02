import 'package:flutter/foundation.dart';

enum PaymentFrequency {
  monthly('Monthly', 1),
  quarterly('Quarterly', 3),
  yearly('Yearly', 12),
  custom('Custom', 1);

  const PaymentFrequency(this.label, this.months);
  final String label;
  final int months;

  static PaymentFrequency fromLabel(String l) =>
      values.firstWhere((f) => f.label == l, orElse: () => monthly);
}

/// When rent reminders fire relative to the due date.
enum ReminderOffset {
  sevenDays('7d', '7 days before', 7),
  threeDays('3d', '3 days before', 3),
  oneDay('1d', '1 day before', 1),
  dueDate('due', 'On due date', 0);

  const ReminderOffset(this.key, this.label, this.days);
  final String key;
  final String label;
  final int days;
}

@immutable
class Lease {
  const Lease({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    this.unitLabel,
    required this.monthlyRent,
    this.deposit = 0,
    required this.start,
    required this.end,
    this.dueDay = 1,
    this.frequency = PaymentFrequency.monthly,
    this.graceDays = 3,
    this.reminderOffsets = const {ReminderOffset.threeDays, ReminderOffset.oneDay, ReminderOffset.dueDate},
    this.notes = '',
    this.renewalWindowDays = 60,
    required this.createdAt,
  });

  final String id;
  final String propertyId;
  final String tenantId;

  /// e.g. "Unit 3" for multi-unit properties.
  final String? unitLabel;
  final int monthlyRent;
  final int deposit;
  final DateTime start;
  final DateTime end;
  final int dueDay;
  final PaymentFrequency frequency;
  final int graceDays;
  final Set<ReminderOffset> reminderOffsets;
  final String notes;
  final int renewalWindowDays;
  final DateTime createdAt;

  bool isActiveOn(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

  double progressOn(DateTime d) {
    final total = end.difference(start).inDays;
    if (total <= 0) return 1;
    return (d.difference(start).inDays / total).clamp(0.0, 1.0);
  }

  DateTime get renewalWindowOpens => end.subtract(Duration(days: renewalWindowDays));

  Lease copyWith({
    String? propertyId,
    int? monthlyRent,
    int? deposit,
    DateTime? start,
    DateTime? end,
    int? dueDay,
    PaymentFrequency? frequency,
    int? graceDays,
    Set<ReminderOffset>? reminderOffsets,
    String? notes,
  }) =>
      Lease(
        id: id,
        propertyId: propertyId ?? this.propertyId,
        tenantId: tenantId,
        unitLabel: unitLabel,
        monthlyRent: monthlyRent ?? this.monthlyRent,
        deposit: deposit ?? this.deposit,
        start: start ?? this.start,
        end: end ?? this.end,
        dueDay: dueDay ?? this.dueDay,
        frequency: frequency ?? this.frequency,
        graceDays: graceDays ?? this.graceDays,
        reminderOffsets: reminderOffsets ?? this.reminderOffsets,
        notes: notes ?? this.notes,
        renewalWindowDays: renewalWindowDays,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'tenantId': tenantId,
        'unitLabel': unitLabel,
        'monthlyRent': monthlyRent,
        'deposit': deposit,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'dueDay': dueDay,
        'frequency': frequency.name,
        'graceDays': graceDays,
        'reminderOffsets': reminderOffsets.map((r) => r.key).toList(),
        'notes': notes,
        'renewalWindowDays': renewalWindowDays,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Lease.fromMap(Map<String, dynamic> map, [String? id]) => Lease(
        id: id ?? map['id']?.toString() ?? '',
        propertyId: map['propertyId']?.toString() ?? '',
        tenantId: map['tenantId']?.toString() ?? '',
        unitLabel: map['unitLabel']?.toString(),
        monthlyRent: (map['monthlyRent'] as num?)?.toInt() ?? 0,
        deposit: (map['deposit'] as num?)?.toInt() ?? 0,
        start: DateTime.tryParse(map['start']?.toString() ?? '') ?? DateTime.now(),
        end: DateTime.tryParse(map['end']?.toString() ?? '') ?? DateTime.now(),
        dueDay: (map['dueDay'] as num?)?.toInt() ?? 1,
        frequency: PaymentFrequency.values.firstWhere(
          (f) => f.name == map['frequency'] || f.label == map['frequency'],
          orElse: () => PaymentFrequency.monthly,
        ),
        graceDays: (map['graceDays'] as num?)?.toInt() ?? 3,
        reminderOffsets: (map['reminderOffsets'] as List<dynamic>?)
                ?.map((e) => ReminderOffset.values.firstWhere(
                      (r) => r.key == e || r.name == e,
                      orElse: () => ReminderOffset.dueDate,
                    ))
                .toSet() ??
            const {ReminderOffset.threeDays, ReminderOffset.oneDay, ReminderOffset.dueDate},
        notes: map['notes']?.toString() ?? '',
        renewalWindowDays: (map['renewalWindowDays'] as num?)?.toInt() ?? 60,
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
