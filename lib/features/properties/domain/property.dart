import 'package:flutter/foundation.dart';

enum PropertyType {
  house('House'),
  apartment('Apartment'),
  commercial('Commercial'),
  land('Land'),
  other('Other');

  const PropertyType(this.label);
  final String label;

  static PropertyType fromLabel(String l) =>
      values.firstWhere((t) => t.label == l, orElse: () => other);
}

enum PropertyStatus {
  owned('Owner occupied'),
  rented('Rented'),
  vacant('Vacant'),
  maintenance('Under maintenance');

  const PropertyStatus(this.label);
  final String label;

  static PropertyStatus fromLabel(String l) =>
      values.firstWhere((t) => t.label == l, orElse: () => vacant);
}

/// A point on a property's valuation history.
@immutable
class ValuePoint {
  const ValuePoint(this.date, this.value);
  final DateTime date;
  final int value;

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'value': value,
      };

  factory ValuePoint.fromMap(Map<String, dynamic> map) => ValuePoint(
        DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
        (map['value'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class Property {
  const Property({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.address,
    required this.area,
    required this.city,
    required this.country,
    this.postalCode = '',
    this.latitude,
    this.longitude,
    this.bedrooms,
    this.bathrooms,
    this.areaSqft,
    this.yearBuilt,
    this.furnished = false,
    required this.purchasePrice,
    required this.currentValue,
    this.mortgage = 0,
    this.monthlyExpenses = 0,
    this.unitCount = 1,
    this.photoUrls = const [],
    this.notes = '',
    this.valueHistory = const [],
    required this.createdAt,
  });

  final String id;
  final String name;
  final PropertyType type;
  final PropertyStatus status;

  /// Street line, e.g. "416 Oak Street, Sector J · DHA Phase 6".
  final String address;

  /// Neighbourhood, e.g. "DHA Phase 6".
  final String area;
  final String city;
  final String country;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final int? bedrooms;
  final int? bathrooms;
  final int? areaSqft;
  final int? yearBuilt;
  final bool furnished;
  final int purchasePrice;
  final int currentValue;
  final int mortgage;

  /// Owner-estimated fixed monthly running cost.
  final int monthlyExpenses;

  /// Lettable units (1 for a house, many for a block or plaza).
  final int unitCount;
  final List<String> photoUrls;
  final String notes;
  final List<ValuePoint> valueHistory;
  final DateTime createdAt;

  String get location => area.isEmpty ? city : '$area, $city';
  String? get coverUrl => photoUrls.isEmpty ? null : photoUrls.first;
  int get gain => currentValue - purchasePrice;
  double get gainPct => purchasePrice == 0 ? 0 : gain / purchasePrice * 100;

  Property copyWith({
    String? name,
    PropertyType? type,
    PropertyStatus? status,
    String? address,
    String? area,
    String? city,
    String? country,
    String? postalCode,
    int? bedrooms,
    int? bathrooms,
    int? areaSqft,
    int? yearBuilt,
    bool? furnished,
    int? purchasePrice,
    int? currentValue,
    int? mortgage,
    int? monthlyExpenses,
    int? unitCount,
    List<String>? photoUrls,
    String? notes,
    List<ValuePoint>? valueHistory,
  }) =>
      Property(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        status: status ?? this.status,
        address: address ?? this.address,
        area: area ?? this.area,
        city: city ?? this.city,
        country: country ?? this.country,
        postalCode: postalCode ?? this.postalCode,
        latitude: latitude,
        longitude: longitude,
        bedrooms: bedrooms ?? this.bedrooms,
        bathrooms: bathrooms ?? this.bathrooms,
        areaSqft: areaSqft ?? this.areaSqft,
        yearBuilt: yearBuilt ?? this.yearBuilt,
        furnished: furnished ?? this.furnished,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        currentValue: currentValue ?? this.currentValue,
        mortgage: mortgage ?? this.mortgage,
        monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
        unitCount: unitCount ?? this.unitCount,
        photoUrls: photoUrls ?? this.photoUrls,
        notes: notes ?? this.notes,
        valueHistory: valueHistory ?? this.valueHistory,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'status': status.name,
        'address': address,
        'area': area,
        'city': city,
        'country': country,
        'postalCode': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'areaSqft': areaSqft,
        'yearBuilt': yearBuilt,
        'furnished': furnished,
        'purchasePrice': purchasePrice,
        'currentValue': currentValue,
        'mortgage': mortgage,
        'monthlyExpenses': monthlyExpenses,
        'unitCount': unitCount,
        'photoUrls': photoUrls,
        'notes': notes,
        'valueHistory': valueHistory.map((v) => v.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Property.fromMap(Map<String, dynamic> map, [String? id]) => Property(
        id: id ?? map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        type: PropertyType.values.firstWhere(
          (t) => t.name == map['type'] || t.label == map['type'],
          orElse: () => PropertyType.other,
        ),
        status: PropertyStatus.values.firstWhere(
          (s) => s.name == map['status'] || s.label == map['status'],
          orElse: () => PropertyStatus.vacant,
        ),
        address: map['address']?.toString() ?? '',
        area: map['area']?.toString() ?? '',
        city: map['city']?.toString() ?? '',
        country: map['country']?.toString() ?? '',
        postalCode: map['postalCode']?.toString() ?? '',
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        bedrooms: (map['bedrooms'] as num?)?.toInt(),
        bathrooms: (map['bathrooms'] as num?)?.toInt(),
        areaSqft: (map['areaSqft'] as num?)?.toInt(),
        yearBuilt: (map['yearBuilt'] as num?)?.toInt(),
        furnished: map['furnished'] as bool? ?? false,
        purchasePrice: (map['purchasePrice'] as num?)?.toInt() ?? 0,
        currentValue: (map['currentValue'] as num?)?.toInt() ?? 0,
        mortgage: (map['mortgage'] as num?)?.toInt() ?? 0,
        monthlyExpenses: (map['monthlyExpenses'] as num?)?.toInt() ?? 0,
        unitCount: (map['unitCount'] as num?)?.toInt() ?? 1,
        photoUrls: (map['photoUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        notes: map['notes']?.toString() ?? '',
        valueHistory: (map['valueHistory'] as List<dynamic>?)
                ?.map((e) => ValuePoint.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
