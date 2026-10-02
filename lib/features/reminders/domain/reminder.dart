import 'package:flutter/foundation.dart';

enum ReminderType {
  rent('Rent'),
  lease('Lease'),
  maintenance('Maintenance'),
  insurance('Insurance'),
  document('Document'),
  inspection('Inspection'),
  tax('Tax'),
  custom('Custom');

  const ReminderType(this.label);
  final String label;
  static ReminderType fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => custom);
}

enum RepeatRule {
  none('None'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const RepeatRule(this.label);
  final String label;
  static RepeatRule fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => none);
}

/// A reminder. Auto reminders carry a deterministic [sourceKey]
/// (e.g. `rent:{chargeId}`); the engine upserts by key, so the same event can
/// never create two reminders.
@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    this.propertyId,
    this.amountLabel = '',
    required this.at,
    this.repeat = RepeatRule.none,
    this.notes = '',
    this.notify = true,
    this.done = false,
    this.snoozed = false,
    this.sourceKey,
    this.sourceLabel = 'Added by you',
    this.target,
  });

  final String id;
  final ReminderType type;
  final String title;
  final String? propertyId;
  final String amountLabel;
  final DateTime at;
  final RepeatRule repeat;
  final String notes;
  final bool notify;
  final bool done;
  final bool snoozed;
  final String? sourceKey;
  final String sourceLabel;

  /// Route to open for the underlying record (e.g. an overdue charge).
  final String? target;

  bool get isAuto => sourceKey != null;

  Reminder copyWith({
    String? title,
    ReminderType? type,
    String? propertyId,
    String? amountLabel,
    DateTime? at,
    RepeatRule? repeat,
    String? notes,
    bool? notify,
    bool? done,
    bool? snoozed,
    String? sourceLabel,
    String? target,
  }) =>
      Reminder(
        id: id,
        type: type ?? this.type,
        title: title ?? this.title,
        propertyId: propertyId ?? this.propertyId,
        amountLabel: amountLabel ?? this.amountLabel,
        at: at ?? this.at,
        repeat: repeat ?? this.repeat,
        notes: notes ?? this.notes,
        notify: notify ?? this.notify,
        done: done ?? this.done,
        snoozed: snoozed ?? this.snoozed,
        sourceKey: sourceKey,
        sourceLabel: sourceLabel ?? this.sourceLabel,
        target: target ?? this.target,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        'propertyId': propertyId,
        'amountLabel': amountLabel,
        'at': at.toIso8601String(),
        'repeat': repeat.name,
        'notes': notes,
        'notify': notify,
        'done': done,
        'snoozed': snoozed,
        'sourceKey': sourceKey,
        'sourceLabel': sourceLabel,
        'target': target,
      };

  factory Reminder.fromMap(Map<String, dynamic> map, [String? id]) => Reminder(
        id: id ?? map['id']?.toString() ?? '',
        type: ReminderType.values.firstWhere(
          (t) => t.name == map['type'] || t.label == map['type'],
          orElse: () => ReminderType.custom,
        ),
        title: map['title']?.toString() ?? '',
        propertyId: map['propertyId']?.toString(),
        amountLabel: map['amountLabel']?.toString() ?? '',
        at: DateTime.tryParse(map['at']?.toString() ?? '') ?? DateTime.now(),
        repeat: RepeatRule.values.firstWhere(
          (r) => r.name == map['repeat'] || r.label == map['repeat'],
          orElse: () => RepeatRule.none,
        ),
        notes: map['notes']?.toString() ?? '',
        notify: map['notify'] as bool? ?? true,
        done: map['done'] as bool? ?? false,
        snoozed: map['snoozed'] as bool? ?? false,
        sourceKey: map['sourceKey']?.toString(),
        sourceLabel: map['sourceLabel']?.toString() ?? 'Added by you',
        target: map['target']?.toString(),
      );
}
