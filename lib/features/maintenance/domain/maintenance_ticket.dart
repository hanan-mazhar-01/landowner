import 'package:flutter/foundation.dart';

enum MaintenanceCategory {
  plumbing('Plumbing'),
  electrical('Electrical'),
  hvac('HVAC'),
  appliance('Appliance'),
  structural('Structural'),
  cleaning('Cleaning'),
  other('Other');

  const MaintenanceCategory(this.label);
  final String label;
  static MaintenanceCategory fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => other);
}

enum MaintenancePriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  const MaintenancePriority(this.label);
  final String label;
  bool get isSevere => this == high || this == urgent;
  static MaintenancePriority fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => medium);
}

enum MaintenanceStatus {
  open('Open'),
  scheduled('Scheduled'),
  inProgress('In progress'),
  completed('Completed');

  const MaintenanceStatus(this.label);
  final String label;
  static MaintenanceStatus fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => open);
}

@immutable
class MaintenanceTicket {
  const MaintenanceTicket({
    required this.id,
    required this.propertyId,
    required this.title,
    this.description = '',
    this.category = MaintenanceCategory.other,
    this.priority = MaintenancePriority.medium,
    required this.scheduledFor,
    this.estimatedCost = 0,
    this.actualCost,
    this.status = MaintenanceStatus.open,
    this.photoUrls = const [],
    this.receiptUrl,
    this.notes = '',
    this.remindBefore = true,
    required this.createdAt,
  });

  final String id;
  final String propertyId;
  final String title;
  final String description;
  final MaintenanceCategory category;
  final MaintenancePriority priority;
  final DateTime scheduledFor;
  final int estimatedCost;
  final int? actualCost;
  final MaintenanceStatus status;
  final List<String> photoUrls;
  final String? receiptUrl;
  final String notes;
  final bool remindBefore;
  final DateTime createdAt;

  bool get isDone => status == MaintenanceStatus.completed;
  int get cost => actualCost ?? estimatedCost;

  MaintenanceTicket copyWith({
    String? propertyId,
    String? title,
    String? description,
    MaintenanceCategory? category,
    MaintenancePriority? priority,
    DateTime? scheduledFor,
    int? estimatedCost,
    int? actualCost,
    bool clearActual = false,
    MaintenanceStatus? status,
    List<String>? photoUrls,
    String? receiptUrl,
    String? notes,
    bool? remindBefore,
  }) =>
      MaintenanceTicket(
        id: id,
        propertyId: propertyId ?? this.propertyId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        scheduledFor: scheduledFor ?? this.scheduledFor,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        actualCost: clearActual ? null : (actualCost ?? this.actualCost),
        status: status ?? this.status,
        photoUrls: photoUrls ?? this.photoUrls,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        notes: notes ?? this.notes,
        remindBefore: remindBefore ?? this.remindBefore,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'scheduledFor': scheduledFor.toIso8601String(),
        'estimatedCost': estimatedCost,
        'actualCost': actualCost,
        'status': status.name,
        'photoUrls': photoUrls,
        'receiptUrl': receiptUrl,
        'notes': notes,
        'remindBefore': remindBefore,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MaintenanceTicket.fromMap(Map<String, dynamic> map, [String? id]) => MaintenanceTicket(
        id: id ?? map['id']?.toString() ?? '',
        propertyId: map['propertyId']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        category: MaintenanceCategory.values.firstWhere(
          (c) => c.name == map['category'] || c.label == map['category'],
          orElse: () => MaintenanceCategory.other,
        ),
        priority: MaintenancePriority.values.firstWhere(
          (p) => p.name == map['priority'] || p.label == map['priority'],
          orElse: () => MaintenancePriority.medium,
        ),
        scheduledFor: DateTime.tryParse(map['scheduledFor']?.toString() ?? '') ?? DateTime.now(),
        estimatedCost: (map['estimatedCost'] as num?)?.toInt() ?? 0,
        actualCost: (map['actualCost'] as num?)?.toInt(),
        status: MaintenanceStatus.values.firstWhere(
          (s) => s.name == map['status'] || s.label == map['status'],
          orElse: () => MaintenanceStatus.open,
        ),
        photoUrls: (map['photoUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        receiptUrl: map['receiptUrl']?.toString(),
        notes: map['notes']?.toString() ?? '',
        remindBefore: map['remindBefore'] as bool? ?? true,
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
