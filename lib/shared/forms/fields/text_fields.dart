import 'package:flutter/material.dart' show TextField, InputDecoration, OutlineInputBorder, InputBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/formatters.dart';

OutlineInputBorder _border(Color c) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide(color: c));

/// 50px text input — `#DDE3F3` border, `#4D6DFA` on focus.
class HomelyTextField extends StatefulWidget {
  const HomelyTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = '',
    this.keyboard,
    this.lines = 1,
    this.obscure = false,
    this.autofill,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final TextInputType? keyboard;
  final int lines;
  final bool obscure;
  final Iterable<String>? autofill;

  @override
  State<HomelyTextField> createState() => _HomelyTextFieldState();
}

class _HomelyTextFieldState extends State<HomelyTextField> {
  late final _c = TextEditingController(text: widget.value);

  /// Password fields start hidden; the eye button reveals / hides them.
  late bool _hidden = widget.obscure;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.lines > 1;
    return TextField(
      controller: _c,
      onChanged: widget.onChanged,
      keyboardType: multi ? TextInputType.multiline : widget.keyboard,
      minLines: widget.lines,
      maxLines: multi ? 6 : 1,
      obscureText: _hidden,
      autofillHints: widget.autofill,
      textCapitalization: widget.keyboard == null && !widget.obscure ? TextCapitalization.sentences : TextCapitalization.none,
      style: TextStyle(fontSize: multi ? 15 : 16, color: AppColors.ink),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        hintText: widget.placeholder,
        hintStyle: TextStyle(fontSize: multi ? 15 : 16, color: AppColors.textFaint),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: multi ? 14 : 15),
        suffixIcon: widget.obscure
            ? Semantics(
                button: true,
                label: _hidden ? 'Show password' : 'Hide password',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _hidden = !_hidden),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: HomelyIcon(
                        _hidden ? HomelyIcons.eye : HomelyIcons.eyeOff,
                        size: 20,
                        strokeWidth: 1.9,
                        color: _hidden ? AppColors.textFaint : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.accent),
        border: _border(AppColors.border),
      ),
    );
  }
}

/// 56px money input — faint "Rs" prefix, 22/800 Manrope digits, grouped as typed.
class MoneyField extends StatefulWidget {
  const MoneyField({super.key, required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final _c = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: _focus.hasFocus ? AppColors.accent : AppColors.border),
        ),
        child: Row(children: [
          Text(Money.symbol, style: AppType.num(16, FontWeight.w700).copyWith(color: AppColors.textFaint)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _c,
              focusNode: _focus,
              onChanged: widget.onChanged,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, const _Grouping()],
              style: AppType.num(22),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '0',
                hintStyle: AppType.num(22).copyWith(color: AppColors.textFaint),
              ),
            ),
          ),
        ]),
      );
}

class _Grouping extends TextInputFormatter {
  const _Grouping();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null) return oldValue;
    final t = Money.digits(n);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
