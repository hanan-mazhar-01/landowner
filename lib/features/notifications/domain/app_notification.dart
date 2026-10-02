import 'package:flutter/foundation.dart';

enum NotificationCategory {
  rent('Rent'),
  lease('Lease'),
  maintenance('Maintenance'),
  documents('Documents'),
  finance('Finance'),
  property('Property');

  const NotificationCategory(this.label);
  final String label;
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.unread = true,
    this.target,
    this.propertyId,
    this.critical = false,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool unread;

  /// App route opened when tapped.
  final String? target;
  final String? propertyId;

  /// Rendered with the overdue tone (e.g. "Rent overdue").
  final bool critical;

  AppNotification copyWith({bool? unread, bool? critical}) => AppNotification(
        id: id,
        category: category,
        title: title,
        body: body,
        createdAt: createdAt,
        unread: unread ?? this.unread,
        target: target,
        propertyId: propertyId,
        critical: critical ?? this.critical,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'unread': unread,
        'target': target,
        'propertyId': propertyId,
        'critical': critical,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map, [String? id]) => AppNotification(
        id: id ?? map['id']?.toString() ?? '',
        category: NotificationCategory.values.firstWhere(
          (c) => c.name == map['category'] || c.label == map['category'],
          orElse: () => NotificationCategory.property,
        ),
        title: map['title']?.toString() ?? '',
        body: map['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
        unread: map['unread'] as bool? ?? true,
        target: map['target']?.toString(),
        propertyId: map['propertyId']?.toString(),
        critical: map['critical'] as bool? ?? false,
      );
}

@immutable
class NotificationSettings {
  const NotificationSettings({
    this.push = true,
    this.rent = true,
    this.payments = true,
    this.lease = true,
    this.maintenance = true,
    this.documents = true,
    this.insurance = true,
    this.monthlySummary = false,
    this.quietHours = true,
    this.defaultTiming = const {'1d', '3d', 'due'},
  });

  final bool push, rent, payments, lease, maintenance, documents, insurance, monthlySummary, quietHours;

  /// Keys of [ReminderOffset] applied to new leases.
  final Set<String> defaultTiming;

  Map<String, bool> toMap() => {
        'push': push,
        'rent': rent,
        'pay': payments,
        'lease': lease,
        'maint': maintenance,
        'docs': documents,
        'ins': insurance,
        'fin': monthlySummary,
        'quiet': quietHours,
      };

  NotificationSettings toggle(String key) {
    final m = toMap()..[key] = !(toMap()[key] ?? false);
    return NotificationSettings(
      push: m['push']!,
      rent: m['rent']!,
      payments: m['pay']!,
      lease: m['lease']!,
      maintenance: m['maint']!,
      documents: m['docs']!,
      insurance: m['ins']!,
      monthlySummary: m['fin']!,
      quietHours: m['quiet']!,
      defaultTiming: defaultTiming,
    );
  }

  NotificationSettings toggleTiming(String key) {
    final t = {...defaultTiming};
    t.contains(key) ? t.remove(key) : t.add(key);
    return NotificationSettings(
      push: push,
      rent: rent,
      payments: payments,
      lease: lease,
      maintenance: maintenance,
      documents: documents,
      insurance: insurance,
      monthlySummary: monthlySummary,
      quietHours: quietHours,
      defaultTiming: t,
    );
  }
}
