import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/forms/form_spec.dart';
import '../../../../shared/providers/usecases.dart';
import '../../domain/document_item.dart';

/// Add document — an expiry date creates a reminder via the engine.
FormSpec documentForm({required String propertyId, required DateTime today, DocumentItem? editing}) {
  final e = editing;
  return FormSpec(
      title: e == null ? 'Add document' : 'Edit document',
      hint: 'You’ll be reminded 30 days and 7 days before expiry, and on the day.',
      initial: FormValues({
        'dtype': e?.type.label ?? 'Insurance',
        'prop': e?.propertyId ?? propertyId,
        'name': e?.name ?? '',
        'file': <String>[?e?.fileUrl],
        'ddate': e?.date ?? today,
        'expiry': e?.expiry,
        'notes': e?.notes ?? '',
      }),
      onDelete: e == null ? null : (ref) => ref.read(recordEditsProvider).deleteDocument(e.id),
      deleteLabel: 'Delete document',
      steps: [
        StepSpec('Add to vault', fields: [
          FieldSpec('dtype', 'Type', FieldKind.chips, options: [for (final t in DocumentType.values) t.label]),
          const FieldSpec('prop', 'Property', FieldKind.property, required: true),
          const FieldSpec('name', 'Document name', FieldKind.text, placeholder: 'Building insurance 2026', required: true),
          const FieldSpec('file', 'File or photo', FieldKind.upload),
          const FieldSpec('ddate', 'Document date', FieldKind.date),
          const FieldSpec('expiry', 'Expiry date (optional)', FieldKind.date),
          const FieldSpec('notes', 'Notes', FieldKind.note, placeholder: 'Optional'),
        ]),
      ],
      onSave: (v, WidgetRef ref) async {
        final expiry = v.date('expiry');
        if (e != null) {
          await ref.read(recordEditsProvider).saveDocument(e.copyWith(
                propertyId: v.str('prop'),
                type: DocumentType.fromLabel(v.str('dtype')),
                name: v.str('name'),
                fileUrl: v.files('file').firstOrNull,
                date: v.date('ddate'),
                expiry: expiry,
                clearExpiry: expiry == null,
                notes: v.str('notes'),
              ));
          return const FormResult(toast: 'Document updated');
        }
        await ref.read(addDocumentProvider)(
          propertyId: v.str('prop'),
          type: DocumentType.fromLabel(v.str('dtype')),
          name: v.str('name'),
          date: v.date('ddate') ?? today,
          expiry: expiry,
          notes: v.str('notes'),
          fileUrl: v.files('file').firstOrNull,
          fileCount: v.files('file').isEmpty ? 1 : v.files('file').length,
        );
        return FormResult(
          toast: expiry != null ? 'Saved · expiry reminder created' : 'Saved to vault',
          replaceWith: Routes.property(v.str('prop')),
        );
      },
    );
}
