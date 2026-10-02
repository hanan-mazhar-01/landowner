import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Field kinds from the design's form system.
enum FieldKind { text, money, date, time, note, seg, chips, property, toggle, upload, map, remind }

@immutable
class FieldSpec {
  const FieldSpec(
    this.key,
    this.label,
    this.kind, {
    this.options = const [],
    this.placeholder = '',
    this.multi = false,
    this.required = false,
    this.keyboard,
    this.obscure = false,
  });

  final String key;
  final String label;
  final FieldKind kind;
  final List<String> options;
  final String placeholder;
  final bool multi;
  final bool required;
  final TextInputType? keyboard;
  final bool obscure;
}

/// A step: title + fields, or a review summary built from the values.
@immutable
class StepSpec {
  const StepSpec(this.title, {this.fields = const [], this.review});
  final String title;
  final List<FieldSpec> fields;
  final Widget Function(FormValues values, WidgetRef ref)? review;
}

/// Mutable-by-copy value bag for a form in progress.
@immutable
class FormValues {
  const FormValues(this._m);
  final Map<String, Object?> _m;

  Object? operator [](String k) => _m[k];
  String str(String k) => (_m[k] as String?) ?? '';
  bool flag(String k) => (_m[k] as bool?) ?? false;
  DateTime? date(String k) => _m[k] as DateTime?;
  List<String> files(String k) => (_m[k] as List<String>?) ?? const [];
  Set<String> set(String k) => (_m[k] as Set<String>?) ?? const {};

  FormValues put(String k, Object? v) => FormValues({..._m, k: v});
}

/// Outcome of saving: where to go and what to say.
class FormResult {
  const FormResult({this.toast, this.replaceWith, this.goTab});
  final String? toast;

  /// Route to replace the form with (e.g. the new property's detail).
  final String? replaceWith;

  /// Tab route to jump to instead (e.g. Finance after an expense).
  final String? goTab;
}

@immutable
class FormSpec {
  const FormSpec({
    required this.title,
    required this.steps,
    required this.initial,
    required this.onSave,
    this.hint = '',
    this.saveLabel = 'Save',
    this.onDelete,
    this.deleteLabel = 'Delete',
  });

  final String title;
  final List<StepSpec> steps;
  final FormValues initial;
  final String hint;
  final String saveLabel;
  final Future<FormResult> Function(FormValues v, WidgetRef ref) onSave;

  /// Edit mode only — shows a destructive link under the last step.
  final Future<void> Function(WidgetRef ref)? onDelete;
  final String deleteLabel;

  bool get multiStep => steps.length > 1;
}
