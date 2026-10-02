import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/forms/form_spec.dart';
import '../../../../shared/providers/usecases.dart';
import '../../domain/maintenance_ticket.dart';

/// Add maintenance — single step; actual cost books an expense and the
/// reminder engine schedules a visit reminder when "Remind me" is on.
FormSpec maintenanceForm({required String propertyId, required DateTime today, MaintenanceTicket? editing}) {
  final e = editing;
  return FormSpec(
      title: e == null ? 'Add maintenance' : 'Edit maintenance',
      initial: FormValues({
        'prop': e?.propertyId ?? propertyId,
        'title': e?.title ?? '',
        'desc': e?.description ?? '',
        'cat': e?.category.label ?? 'HVAC',
        'prio': e?.priority.label ?? 'Medium',
        'date': e?.scheduledFor ?? today.add(const Duration(days: 3)),
        'est': e == null || e.estimatedCost == 0 ? '' : Money.digits(e.estimatedCost),
        'actual': e?.actualCost == null ? '' : Money.digits(e!.actualCost!),
        'mstatus': e?.status.label ?? 'Open',
        'photo': e?.photoUrls ?? <String>[],
        'receipt': <String>[?e?.receiptUrl],
        'notes': e?.notes ?? '',
        'mrem': e?.remindBefore ?? true,
      }),
      onDelete: e == null ? null : (ref) => ref.read(recordEditsProvider).deleteMaintenance(e.id),
      deleteLabel: 'Delete request',
      steps: [
        StepSpec('Log an issue', fields: [
          const FieldSpec('prop', 'Property', FieldKind.property, required: true),
          const FieldSpec('title', 'Issue', FieldKind.text, placeholder: 'AC service', required: true),
          const FieldSpec('desc', 'Description', FieldKind.note, placeholder: 'What needs doing?'),
          FieldSpec('cat', 'Category', FieldKind.chips, options: [for (final c in MaintenanceCategory.values) c.label]),
          FieldSpec('prio', 'Priority', FieldKind.seg, options: [for (final p in MaintenancePriority.values) p.label]),
          const FieldSpec('date', 'Scheduled for', FieldKind.date),
          const FieldSpec('est', 'Estimated cost', FieldKind.money),
          const FieldSpec('actual', 'Actual cost', FieldKind.money),
          FieldSpec('mstatus', 'Status', FieldKind.seg, options: [for (final s in MaintenanceStatus.values) s.label]),
          const FieldSpec('photo', 'Photos', FieldKind.upload, multi: true),
          const FieldSpec('receipt', 'Receipt', FieldKind.upload),
          const FieldSpec('notes', 'Notes', FieldKind.note, placeholder: 'Optional'),
          const FieldSpec('mrem', 'Remind me before', FieldKind.toggle),
        ]),
      ],
      onSave: (v, WidgetRef ref) async {
        final actual = Money.parse(v.str('actual'));
        final remind = v.flag('mrem');
        final status = MaintenanceStatus.fromLabel(v.str('mstatus'));
        if (e != null) {
          await ref.read(recordEditsProvider).saveMaintenance(e.copyWith(
                propertyId: v.str('prop'),
                title: v.str('title'),
                description: v.str('desc'),
                category: MaintenanceCategory.fromLabel(v.str('cat')),
                priority: MaintenancePriority.fromLabel(v.str('prio')),
                scheduledFor: v.date('date'),
                estimatedCost: Money.parse(v.str('est')),
                actualCost: actual == 0 ? null : actual,
                photoUrls: v.files('photo'),
                receiptUrl: v.files('receipt').firstOrNull,
                notes: v.str('notes'),
                remindBefore: remind,
              ));
          // Status changes go through the use case so completion books the expense.
          await ref.read(updateMaintenanceStatusProvider)(e.id, status, actualCost: actual == 0 ? null : actual);
          return const FormResult(toast: 'Request updated');
        }
        await ref.read(logMaintenanceProvider)(
          propertyId: v.str('prop'),
          title: v.str('title'),
          description: v.str('desc'),
          category: MaintenanceCategory.fromLabel(v.str('cat')),
          priority: MaintenancePriority.fromLabel(v.str('prio')),
          scheduledFor: v.date('date') ?? today,
          estimatedCost: Money.parse(v.str('est')),
          actualCost: actual == 0 ? null : actual,
          status: status,
          remindBefore: remind,
          notes: v.str('notes'),
          photoUrls: v.files('photo'),
          receiptUrl: v.files('receipt').firstOrNull,
        );
        return FormResult(
          toast: remind ? 'Logged · reminder set for the day before' : 'Maintenance logged',
          replaceWith: '/properties/${v.str('prop')}?tab=costs',
        );
      },
    );
}
