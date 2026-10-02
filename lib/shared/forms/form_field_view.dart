import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/controls.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../providers/collections.dart';
import 'fields/choice_fields.dart';
import 'fields/media_fields.dart';
import 'fields/picker_fields.dart';
import 'fields/text_fields.dart';
import 'form_spec.dart';

/// Renders one [FieldSpec]: label above the control, 8px gap.
class FormFieldView extends ConsumerWidget {
  const FormFieldView({super.key, required this.spec, required this.values, required this.onChanged});
  final FieldSpec spec;
  final FormValues values;
  final void Function(String key, Object? value) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void set(Object? v) => onChanged(spec.key, v);
    final Widget control = switch (spec.kind) {
      FieldKind.text => HomelyTextField(
          value: values.str(spec.key),
          onChanged: set,
          placeholder: spec.placeholder,
          keyboard: spec.keyboard,
          obscure: spec.obscure),
      FieldKind.note => HomelyTextField(value: values.str(spec.key), onChanged: set, placeholder: spec.placeholder, lines: 3),
      FieldKind.money => MoneyField(value: values.str(spec.key), onChanged: set),
      FieldKind.date => DateTimeField(value: values.date(spec.key), onChanged: set),
      FieldKind.time => DateTimeField(value: values.date(spec.key), onChanged: set, timeOnly: true),
      FieldKind.seg => SegField(options: spec.options, value: values.str(spec.key), onChanged: set),
      FieldKind.chips => SegField(options: spec.options, value: values.str(spec.key), onChanged: set, chips: true),
      FieldKind.property => Transform.translate(
          offset: const Offset(-24, 0),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: PropertyPicker(
              properties: ref.watch(propertiesProvider).value ?? const [],
              value: values.str(spec.key),
              onChanged: set,
            ),
          ),
        ),
      FieldKind.toggle => Align(
          alignment: Alignment.centerLeft,
          child: HomelyToggle(value: values.flag(spec.key), onChanged: set, semanticLabel: spec.label),
        ),
      FieldKind.upload => UploadField(files: values.files(spec.key), onChanged: set, multi: spec.multi),
      FieldKind.map => const MapPinField(),
      FieldKind.remind => TimingGrid(
          selected: values.set(spec.key),
          onToggle: (k) {
            final s = {...values.set(spec.key)};
            s.contains(k) ? s.remove(k) : s.add(k);
            set(s);
          },
        ),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(spec.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      control,
    ]);
  }
}
