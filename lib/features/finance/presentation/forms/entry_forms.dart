import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/forms/form_spec.dart';
import '../../../../shared/providers/repositories.dart';
import '../../../../shared/providers/usecases.dart';
import '../../domain/ledger_entry.dart';

const _methods = ['Cash', 'Bank', 'Card', 'Other'];
const _hint = 'Cash flow and charts update when you save.';

/// Add / edit income — single quick-entry step.
FormSpec incomeForm({required String propertyId, required DateTime today, LedgerEntry? editing}) {
  final e = editing;
  return FormSpec(
    title: e == null ? 'Add income' : 'Edit income',
    hint: _hint,
    initial: FormValues({
      'itype': e?.incomeType?.label ?? 'Rent',
      'prop': e?.propertyId ?? propertyId,
      'amount': e == null ? '' : Money.digits(e.amount),
      'date': e?.date ?? today,
      'method': e?.method.label ?? 'Bank',
      'receipt': <String>[?e?.receiptUrl],
      'notes': e?.notes ?? '',
    }),
    steps: const [
      StepSpec('Record income', fields: [
        FieldSpec('itype', 'Income type', FieldKind.seg, options: ['Rent', 'Deposit', 'Parking', 'Utilities', 'Other']),
        FieldSpec('prop', 'Property', FieldKind.property, required: true),
        FieldSpec('amount', 'Amount', FieldKind.money, required: true),
        FieldSpec('date', 'Date', FieldKind.date),
        FieldSpec('method', 'Payment method', FieldKind.seg, options: _methods),
        FieldSpec('receipt', 'Receipt (optional)', FieldKind.upload),
        FieldSpec('notes', 'Notes', FieldKind.note, placeholder: 'Optional'),
      ]),
    ],
    onDelete: e == null ? null : (ref) => ref.read(recordEditsProvider).deleteEntry(e.id),
    deleteLabel: 'Delete income',
    onSave: (v, WidgetRef ref) async {
      final amount = Money.parse(v.str('amount'));
      final receipt = v.files('receipt').firstOrNull;
      if (e != null) {
        await ref.read(recordEditsProvider).saveEntry(e.copyWith(
              propertyId: v.str('prop'),
              amount: amount,
              date: v.date('date'),
              incomeType: IncomeType.fromLabel(v.str('itype')),
              method: PaymentMethod.fromLabel(v.str('method')),
              notes: v.str('notes'),
              receiptUrl: receipt,
            ));
        return const FormResult(toast: 'Income updated · cash flow recalculated');
      }
      final type = IncomeType.fromLabel(v.str('itype'));
      final date = v.date('date') ?? today;
      // Rent logged here settles the tenant's oldest unpaid charge, so the same
      // payment is never counted twice (once here, once from Payments).
      if (type == IncomeType.rent) {
        final due = ref.read(chargeRepoProvider).snapshot
            .where((c) =>
                c.propertyId == v.str('prop') && !c.isPaid && !c.dueDate.isAfter(date.add(const Duration(days: 15))))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        if (due.isNotEmpty) {
          final c = due.first;
          await ref.read(recordRentPaymentProvider)(
            c.id,
            method: PaymentMethod.fromLabel(v.str('method')),
            amount: amount,
            date: date,
            notes: v.str('notes'),
            receiptUrl: receipt,
          );
          return FormResult(
              toast: '${Dates.month(c.dueDate)} rent marked paid · ${Money.k(amount)}', goTab: Routes.finance);
        }
      }
      await ref.read(recordEntryProvider)(
        kind: EntryKind.income,
        propertyId: v.str('prop'),
        amount: amount,
        date: date,
        incomeType: type,
        method: PaymentMethod.fromLabel(v.str('method')),
        notes: v.str('notes'),
        receiptUrl: receipt,
      );
      return FormResult(toast: '+${Money.k(amount)} added · cash flow updated', goTab: Routes.finance);
    },
  );
}

/// Add / edit expense — single quick-entry step.
FormSpec expenseForm({required String propertyId, required DateTime today, LedgerEntry? editing}) {
  final e = editing;
  return FormSpec(
    title: e == null ? 'Add expense' : 'Edit expense',
    hint: _hint,
    initial: FormValues({
      'prop': e?.propertyId ?? propertyId,
      'cat': e?.expenseCategory?.label ?? 'Utilities',
      'title': e?.title ?? '',
      'amount': e == null ? '' : Money.digits(e.amount),
      'date': e?.date ?? today,
      'method': e?.method.label ?? 'Bank',
      'recur': e?.recurrence.label ?? 'Once',
      'receipt': <String>[?e?.receiptUrl],
      'notes': e?.notes ?? '',
    }),
    steps: [
      StepSpec('Record expense', fields: [
        const FieldSpec('prop', 'Property', FieldKind.property, required: true),
        FieldSpec('cat', 'Category', FieldKind.chips, options: [for (final c in ExpenseCategory.values) c.label]),
        const FieldSpec('amount', 'Amount', FieldKind.money, required: true),
        const FieldSpec('date', 'Date', FieldKind.date),
        const FieldSpec('method', 'Payment method', FieldKind.seg, options: _methods),
        const FieldSpec('recur', 'Repeats', FieldKind.seg, options: ['Once', 'Monthly', 'Quarterly', 'Yearly']),
        const FieldSpec('receipt', 'Receipt / invoice', FieldKind.upload),
        const FieldSpec('notes', 'Notes', FieldKind.note, placeholder: 'Optional'),
      ]),
    ],
    onDelete: e == null ? null : (ref) => ref.read(recordEditsProvider).deleteEntry(e.id),
    deleteLabel: 'Delete expense',
    onSave: (v, WidgetRef ref) async {
      final amount = Money.parse(v.str('amount'));
      final cat = ExpenseCategory.fromLabel(v.str('cat'));
      if (e != null) {
        await ref.read(recordEditsProvider).saveEntry(e.copyWith(
              propertyId: v.str('prop'),
              amount: amount,
              date: v.date('date'),
              expenseCategory: cat,
              method: PaymentMethod.fromLabel(v.str('method')),
              recurrence: Recurrence.fromLabel(v.str('recur')),
              notes: v.str('notes'),
              receiptUrl: v.files('receipt').firstOrNull,
            ));
        return const FormResult(toast: 'Expense updated · cash flow recalculated');
      }
      await ref.read(recordEntryProvider)(
        kind: EntryKind.expense,
        propertyId: v.str('prop'),
        amount: amount,
        date: v.date('date') ?? today,
        category: cat,
        method: PaymentMethod.fromLabel(v.str('method')),
        recurrence: Recurrence.fromLabel(v.str('recur')),
        notes: v.str('notes'),
        receiptUrl: v.files('receipt').firstOrNull,
      );
      return FormResult(toast: '−${Money.k(amount)} recorded · cash flow updated', goTab: Routes.finance);
    },
  );
}
