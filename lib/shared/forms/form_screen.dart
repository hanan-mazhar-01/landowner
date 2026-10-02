import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/errors/app_failure.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_typography.dart';
import '../../core/icons/homely_icon.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/sheets.dart';
import '../../core/widgets/toast.dart';
import '../widgets/bottom_action_bar.dart';
import 'form_field_view.dart';
import 'form_spec.dart';

/// Shared shell for every entry flow: close · title · step count, progress
/// bars, step title, fields, reminder hint and Back / Continue / Save.
class FormScreen extends ConsumerStatefulWidget {
  const FormScreen({super.key, required this.spec});
  final FormSpec spec;

  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  late FormValues _v = widget.spec.initial;
  int _step = 0;
  bool _saving = false;

  FormSpec get _spec => widget.spec;
  bool get _last => _step == _spec.steps.length - 1;

  String? _missing() {
    for (final f in _spec.steps[_step].fields) {
      if (!f.required) continue;
      final v = _v[f.key];
      final empty = v == null || (v is String && v.trim().isEmpty);
      if (empty) return 'Add ${f.label.toLowerCase()} to continue';
    }
    return null;
  }

  Future<void> _next() async {
    final miss = _missing();
    if (miss != null) return ref.read(toastProvider.notifier).show(miss);
    if (!_last) return setState(() => _step++);
    setState(() => _saving = true);
    try {
      final r = await _spec.onSave(_v, ref);
      if (!mounted) return;
      if (r.toast != null) ref.read(toastProvider.notifier).show(r.toast!);
      if (r.goTab != null) {
        context.go(r.goTab!);
      } else if (r.replaceWith != null) {
        context.pushReplacement(r.replaceWith!);
      } else {
        context.pop();
      }
    } catch (e) {
      ref.read(toastProvider.notifier).show(e is AppFailure ? e.message : 'Couldn\u2019t save — please try again');
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmSheet(context,
        title: '${_spec.deleteLabel}?', message: 'This can\u2019t be undone.', confirmLabel: _spec.deleteLabel);
    if (!ok || !mounted) return;
    await _spec.onDelete!(ref);
    if (!mounted) return;
    ref.read(toastProvider.notifier).show('Deleted');
    // Pop the form and the (now stale) detail screen beneath it.
    context.pop();
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final step = _spec.steps[_step];
    final top = MediaQuery.paddingOf(context).top + 8;
    return ColoredBox(
      color: AppColors.background,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, top, 16, 0),
          child: Row(children: [
            SizedBox(
              width: 64,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton(icon: HomelyIcons.close, iconSize: 18, onTap: () => context.pop(), semanticLabel: 'Close'),
              ),
            ),
            Expanded(child: Center(child: Text(_spec.title, style: AppType.button15))),
            SizedBox(
              width: 64,
              child: Text(_spec.multiStep ? 'Step ${_step + 1} of ${_spec.steps.length}' : 'Quick entry',
                  textAlign: TextAlign.right, maxLines: 1, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ]),
        ),
        if (_spec.multiStep)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              for (var i = 0; i < _spec.steps.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: Motion.of(context, const Duration(milliseconds: 300)),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.accent : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        Expanded(
          child: Entrance(
            key: ValueKey(_step),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text(step.title, style: AppType.title28),
                for (final f in step.fields) ...[
                  const SizedBox(height: 20),
                  FormFieldView(spec: f, values: _v, onChanged: (k, v) => setState(() => _v = _v.put(k, v))),
                ],
                if (step.review != null) ...[const SizedBox(height: 20), step.review!(_v, ref)],
                if (_last && _spec.onDelete != null) ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LinkText(_spec.deleteLabel, color: AppColors.overdueText, onTap: _delete),
                  ),
                ],
              ],
            ),
          ),
        ),
        BottomActionBar(
          hint: _spec.hint.isEmpty
              ? null
              : Row(children: [
                  const HomelyIcon(HomelyIcons.bell, size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_spec.hint, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                ]),
          child: Row(children: [
            if (_step > 0) ...[
              Pressable(
                onTap: () => setState(() => _step--),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(child: HomelyIcon(HomelyIcons.back, size: 20, strokeWidth: 2.2)),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: GradientCta(
                label: _saving ? 'Saving…' : (_last ? _spec.saveLabel : 'Continue'),
                onTap: _saving ? null : _next,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
