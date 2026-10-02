import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/share_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../shared/providers/collections.dart';

String csvCell(Object? v) {
  final s = '${v ?? ''}';
  return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

String toCsv(List<List<Object?>> rows) => rows.map((r) => r.map(csvCell).join(',')).join('\n');

/// Exports the full ledger + properties as one CSV via the share sheet.
Future<void> exportAllData(WidgetRef ref) async {
  final props = ref.read(propertiesProvider).value ?? const [];
  final names = {for (final p in props) p.id: p.name};
  final ledger = [...?ref.read(ledgerProvider).value]..sort((a, b) => a.date.compareTo(b.date));
  final rows = <List<Object?>>[
    ['Section', 'Date', 'Property', 'Type', 'Title', 'Amount', 'Method', 'Notes'],
    for (final p in props) ['Property', Dates.dMy(p.createdAt), p.name, p.type.label, p.address, p.currentValue, '', p.notes],
    for (final e in ledger)
      [
        e.isIncome ? 'Income' : 'Expense',
        e.date.toIso8601String().substring(0, 10),
        names[e.propertyId] ?? '',
        e.isIncome ? e.incomeType?.label : e.expenseCategory?.label,
        e.title,
        e.amount,
        e.method.label,
        e.notes,
      ],
  ];
  try {
    await ShareService.bytes(utf8.encode(toCsv(rows)), 'landowner-export.csv', subject: 'LandOwner data export');
  } catch (_) {
    ref.read(toastProvider.notifier).show('Couldn’t export on this device');
  }
}
