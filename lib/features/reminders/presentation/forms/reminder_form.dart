import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/forms/form_spec.dart';
import '../../../../shared/providers/usecases.dart';
import '../../domain/reminder.dart';

/// Add / edit reminder.
FormSpec reminderForm({required String propertyId, required DateTime today, Reminder? editing}) {
  final e = editing;
  final at = e?.at ?? DateTime(today.year, today.month, today.day + 2, 10);
  return FormSpec(
    title: e == null ? 'Add reminder' : 'Edit reminder',
    initial: FormValues({
      'title': e?.title ?? '',
      'prop': e?.propertyId ?? propertyId,
      'rtype': e?.type.label ?? 'Inspection',
      'date': at,
      'time': at,
      'repeat': e?.repeat.label ?? 'None',
      'notify': e?.notify ?? true,
      'notes': e?.notes ?? '',
    }),
    steps: [
      StepSpec(e == null ? 'New reminder' : 'Edit reminder', fields: [
        const FieldSpec('title', 'Title', FieldKind.text, placeholder: 'Annual inspection', required: true),
        const FieldSpec('prop', 'Related property', FieldKind.property),
        FieldSpec('rtype', 'Type', FieldKind.chips, options: [for (final t in ReminderType.values) t.label]),
        const FieldSpec('date', 'Date', FieldKind.date),
        const FieldSpec('time', 'Time', FieldKind.time),
        FieldSpec('repeat', 'Repeat', FieldKind.seg, options: [for (final r in RepeatRule.values) r.label]),
        const FieldSpec('notify', 'Notify me', FieldKind.toggle),
        const FieldSpec('notes', 'Notes', FieldKind.note, placeholder: 'Optional'),
      ]),
    ],
    onSave: (v, WidgetRef ref) async {
      final d = v.date('date') ?? at, t = v.date('time') ?? at;
      final r = await ref.read(reminderActionsProvider).create(
            title: v.str('title'),
            propertyId: v.str('prop').isEmpty ? null : v.str('prop'),
            type: ReminderType.fromLabel(v.str('rtype')),
            at: DateTime(d.year, d.month, d.day, t.hour, t.minute),
            repeat: RepeatRule.fromLabel(v.str('repeat')),
            notify: v.flag('notify'),
            notes: v.str('notes'),
            editingId: e?.id,
          );
      return FormResult(toast: 'Reminder saved', replaceWith: e == null ? Routes.reminder(r.id) : null);
    },
  );
}
