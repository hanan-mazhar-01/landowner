import 'package:flutter/foundation.dart';

enum EntryKind { income, expense }

enum IncomeType {
  rent('Rent'),
  deposit('Deposit'),
  parking('Parking'),
  utilities('Utilities'),
  other('Other');

  const IncomeType(this.label);
  final String label;
  static IncomeType fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => other);
}

enum ExpenseCategory {
  maintenance('Maintenance'),
  utilities('Utilities'),
  insurance('Insurance'),
  tax('Tax'),
  management('Management'),
  renovation('Renovation'),
  mortgage('Mortgage'),
  repairs('Repairs'),
  other('Other');

  const ExpenseCategory(this.label);
  final String label;
  static ExpenseCategory fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => other);
}

enum PaymentMethod {
  cash('Cash'),
  bank('Bank'),
  card('Card'),
  other('Other');

  const PaymentMethod(this.label);
  final String label;
  static PaymentMethod fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => other);
}

enum Recurrence {
  once('Once'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly');

  const Recurrence(this.label);
  final String label;
  static Recurrence fromLabel(String l) => values.firstWhere((e) => e.label == l, orElse: () => once);
}

/// A single income or expense line. Everything financial — rent payments,
/// maintenance costs, manual entries — lands here, so analytics have one source.
@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.kind,
    required this.propertyId,
    this.tenantId,
    required this.title,
    required this.amount,
    required this.date,
    this.incomeType,
    this.expenseCategory,
    this.method = PaymentMethod.bank,
    this.recurrence = Recurrence.once,
    this.notes = '',
    this.receiptUrl,
    this.sourceRef,
  });

  final String id;
  final EntryKind kind;
  final String propertyId;
  final String? tenantId;
  final String title;
  final int amount;
  final DateTime date;
  final IncomeType? incomeType;
  final ExpenseCategory? expenseCategory;
  final PaymentMethod method;
  final Recurrence recurrence;
  final String notes;
  final String? receiptUrl;

  /// Link to what produced this entry (rent charge id, maintenance id…).
  final String? sourceRef;

  bool get isIncome => kind == EntryKind.income;
  int get signed => isIncome ? amount : -amount;

  LedgerEntry copyWith({
    String? propertyId,
    String? title,
    int? amount,
    DateTime? date,
    IncomeType? incomeType,
    ExpenseCategory? expenseCategory,
    PaymentMethod? method,
    Recurrence? recurrence,
    String? notes,
    String? receiptUrl,
  }) =>
      LedgerEntry(
        id: id,
        kind: kind,
        propertyId: propertyId ?? this.propertyId,
        tenantId: tenantId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        incomeType: incomeType ?? this.incomeType,
        expenseCategory: expenseCategory ?? this.expenseCategory,
        method: method ?? this.method,
        recurrence: recurrence ?? this.recurrence,
        notes: notes ?? this.notes,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        sourceRef: sourceRef,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'propertyId': propertyId,
        'tenantId': tenantId,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'incomeType': incomeType?.name,
        'expenseCategory': expenseCategory?.name,
        'method': method.name,
        'recurrence': recurrence.name,
        'notes': notes,
        'receiptUrl': receiptUrl,
        'sourceRef': sourceRef,
      };

  factory LedgerEntry.fromMap(Map<String, dynamic> map, [String? id]) => LedgerEntry(
        id: id ?? map['id']?.toString() ?? '',
        kind: EntryKind.values.firstWhere(
          (k) => k.name == map['kind'],
          orElse: () => EntryKind.expense,
        ),
        propertyId: map['propertyId']?.toString() ?? '',
        tenantId: map['tenantId']?.toString(),
        title: map['title']?.toString() ?? '',
        amount: (map['amount'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
        incomeType: map['incomeType'] != null
            ? IncomeType.values.firstWhere(
                (t) => t.name == map['incomeType'] || t.label == map['incomeType'],
                orElse: () => IncomeType.other,
              )
            : null,
        expenseCategory: map['expenseCategory'] != null
            ? ExpenseCategory.values.firstWhere(
                (c) => c.name == map['expenseCategory'] || c.label == map['expenseCategory'],
                orElse: () => ExpenseCategory.other,
              )
            : null,
        method: PaymentMethod.values.firstWhere(
          (m) => m.name == map['method'] || m.label == map['method'],
          orElse: () => PaymentMethod.bank,
        ),
        recurrence: Recurrence.values.firstWhere(
          (r) => r.name == map['recurrence'] || r.label == map['recurrence'],
          orElse: () => Recurrence.once,
        ),
        notes: map['notes']?.toString() ?? '',
        receiptUrl: map['receiptUrl']?.toString(),
        sourceRef: map['sourceRef']?.toString(),
      );
}
