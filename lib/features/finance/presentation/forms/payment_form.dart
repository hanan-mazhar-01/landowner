import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/forms/form_spec.dart';
import '../../../../shared/providers/usecases.dart';
import '../../../leases/domain/rent_charge.dart';
import '../../domain/ledger_entry.dart';

/// Edit payment — same form language as Add income.
FormSpec paymentForm(RentCharge c) => FormSpec(
      title: 'Edit payment',
      hint: 'Cash flow and charts update when you save.',
      initial: FormValues({
        'amount': Money.digits(c.amount),
        'due': c.dueDate,
        'paid': c.paidAt,
        'method': c.paymentMethod?.split(' ').first ?? 'Bank',
        'notes': c.notes,
      }),
      steps: const [
        StepSpec('Rent payment', fields: [
          FieldSpec('amount', 'Amount', FieldKind.money, required: true),
          FieldSpec('due', 'Due date', FieldKind.date),
          FieldSpec('paid', 'Paid on (leave empty if unpaid)', FieldKind.date),
          FieldSpec('method', 'Payment method', FieldKind.seg, options: ['Cash', 'Bank', 'Card', 'Other']),
          FieldSpec('notes', 'Notes', FieldKind.note, placeholder: 'Optional'),
        ]),
      ],
      onDelete: (ref) => ref.read(paymentActionsProvider).delete(c.id),
      deleteLabel: 'Delete payment',
      onSave: (v, WidgetRef ref) async {
        final paid = v.date('paid');
        await ref.read(paymentActionsProvider).edit(
              c.id,
              amount: Money.parse(v.str('amount')),
              dueDate: v.date('due') ?? c.dueDate,
              paidAt: paid,
              method: PaymentMethod.fromLabel(v.str('method')),
              notes: v.str('notes'),
            );
        if (paid != null && !c.isPaid) {
          await ref.read(recordRentPaymentProvider)(c.id, method: PaymentMethod.fromLabel(v.str('method')));
        }
        return const FormResult(toast: 'Payment updated');
      },
    );
