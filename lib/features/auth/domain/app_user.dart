import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.city = '',
    this.avatarUrl,
    this.currencySymbol = 'Rs',
    this.currencyCode = 'PKR',
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String? avatarUrl;
  final String currencySymbol;
  final String currencyCode;

  /// First word of the name only ("John Malik" → "John").
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? 'there' : parts.first;
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? city,
    String? avatarUrl,
    String? currencySymbol,
    String? currencyCode,
  }) =>
      AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        city: city ?? this.city,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        currencyCode: currencyCode ?? this.currencyCode,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'city': city,
        'avatarUrl': avatarUrl,
        'currencySymbol': currencySymbol,
        'currencyCode': currencyCode,
      };

  factory AppUser.fromMap(Map<String, dynamic> map, [String? uid]) => AppUser(
        uid: uid ?? map['uid']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        city: map['city']?.toString() ?? '',
        avatarUrl: map['avatarUrl']?.toString(),
        currencySymbol: map['currencySymbol']?.toString() ?? 'Rs',
        currencyCode: map['currencyCode']?.toString() ?? 'PKR',
      );
}
