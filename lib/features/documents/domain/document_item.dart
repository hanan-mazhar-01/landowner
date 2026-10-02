import 'package:flutter/foundation.dart';

enum DocumentType {
  lease('Lease'),
  ownership('Ownership'),
  insurance('Insurance'),
  tax('Tax'),
  receipt('Receipt'),
  invoice('Invoice'),
  maintenance('Maintenance'),
  other('Other');

  const DocumentType(this.label);
  final String label;
  static DocumentType fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => other);
}

@immutable
class DocumentItem {
  const DocumentItem({
    required this.id,
    required this.propertyId,
    required this.type,
    required this.name,
    this.fileUrl,
    this.fileCount = 1,
    required this.date,
    this.expiry,
    this.verified = false,
    this.notes = '',
  });

  final String id;
  final String propertyId;
  final DocumentType type;
  final String name;
  final String? fileUrl;
  final int fileCount;
  final DateTime date;
  final DateTime? expiry;
  final bool verified;
  final String notes;

  int? daysToExpiry(DateTime today) => expiry?.difference(DateTime(today.year, today.month, today.day)).inDays;

  /// True when the stored file is an image we can preview in-app.
  bool get isImage => fileKindLabel == 'IMG';

  /// Short badge for the stored file: "PDF", "IMG", "FILE", or "NO FILE".
  String get fileKindLabel {
    final url = fileUrl;
    if (url == null || url.isEmpty) return 'NO FILE';
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    final dot = path.lastIndexOf('.');
    final ext = dot < 0 ? '' : path.substring(dot + 1);
    if (ext == 'pdf') return 'PDF';
    if (const {'jpg', 'jpeg', 'png', 'heic', 'webp'}.contains(ext)) return 'IMG';
    return 'FILE';
  }

  DocumentItem copyWith({
    String? propertyId,
    DocumentType? type,
    String? name,
    String? fileUrl,
    int? fileCount,
    DateTime? date,
    DateTime? expiry,
    bool clearExpiry = false,
    String? notes,
  }) =>
      DocumentItem(
        id: id,
        propertyId: propertyId ?? this.propertyId,
        type: type ?? this.type,
        name: name ?? this.name,
        fileUrl: fileUrl ?? this.fileUrl,
        fileCount: fileCount ?? this.fileCount,
        date: date ?? this.date,
        expiry: clearExpiry ? null : (expiry ?? this.expiry),
        verified: verified,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'type': type.name,
        'name': name,
        'fileUrl': fileUrl,
        'fileCount': fileCount,
        'date': date.toIso8601String(),
        'expiry': expiry?.toIso8601String(),
        'verified': verified,
        'notes': notes,
      };

  factory DocumentItem.fromMap(Map<String, dynamic> map, [String? id]) => DocumentItem(
        id: id ?? map['id']?.toString() ?? '',
        propertyId: map['propertyId']?.toString() ?? '',
        type: DocumentType.values.firstWhere(
          (t) => t.name == map['type'] || t.label == map['type'],
          orElse: () => DocumentType.other,
        ),
        name: map['name']?.toString() ?? '',
        fileUrl: map['fileUrl']?.toString(),
        fileCount: (map['fileCount'] as num?)?.toInt() ?? 1,
        date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
        expiry: map['expiry'] != null ? DateTime.tryParse(map['expiry'].toString()) : null,
        verified: map['verified'] as bool? ?? false,
        notes: map['notes']?.toString() ?? '',
      );
}
