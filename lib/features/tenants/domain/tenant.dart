import 'package:flutter/foundation.dart';

@immutable
class Tenant {
  const Tenant({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.photoUrl,
    this.emergencyContact = '',
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String? photoUrl;
  final String emergencyContact;
  final String notes;
  final DateTime createdAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(p[0]));
    final s = parts.map((p) => p[0]).join();
    return (s.isEmpty ? 'T' : s).substring(0, s.length.clamp(1, 2)).toUpperCase();
  }

  String get firstName => name.trim().split(' ').first;

  Tenant copyWith({
    String? name,
    String? phone,
    String? email,
    String? notes,
    String? photoUrl,
    String? emergencyContact,
  }) =>
      Tenant(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        emergencyContact: emergencyContact ?? this.emergencyContact,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'photoUrl': photoUrl,
        'emergencyContact': emergencyContact,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Tenant.fromMap(Map<String, dynamic> map, [String? id]) => Tenant(
        id: id ?? map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        photoUrl: map['photoUrl']?.toString(),
        emergencyContact: map['emergencyContact']?.toString() ?? '',
        notes: map['notes']?.toString() ?? '',
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
