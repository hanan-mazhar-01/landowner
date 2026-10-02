import 'package:flutter/cupertino.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_decor.dart';
import '../../app/theme/app_typography.dart';
import '../icons/homely_icon.dart';
import 'buttons.dart';
import 'pressable.dart';

/// Rounded white sheet shell (radius 30 top) used by every bottom sheet.
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
        padding: EdgeInsets.fromLTRB(24, 10, 24, MediaQuery.paddingOf(context).bottom + 20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 18),
          Text(title, style: AppType.title22),
          if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: AppType.body)],
          const SizedBox(height: 16),
          Flexible(child: child),
        ]),
      );
}

/// Single-choice sheet (sort, filters, preferences). Returns the picked value.
Future<String?> showChoiceSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
}) =>
    showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => _SheetShell(
        title: title,
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.list)),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 4), children: [
            for (var i = 0; i < options.length; i++)
              Pressable(
                onTap: () => Navigator.pop(ctx, options[i]),
                scale: .99,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  decoration: BoxDecoration(
                    border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.dividerSoft)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(options[i],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: options[i] == selected ? FontWeight.w700 : FontWeight.w500,
                            color: options[i] == selected ? AppColors.primary : AppColors.ink,
                          )),
                    ),
                    if (options[i] == selected)
                      const HomelyIcon(HomelyIcons.check, size: 18, strokeWidth: 2.4, color: AppColors.primary),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );

/// Confirmation sheet. Destructive actions use the overdue tone.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final r = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (ctx) => _SheetShell(
      title: title,
      subtitle: message,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 4),
        SolidButton(
          label: confirmLabel,
          height: 56,
          radius: AppRadius.cta,
          fontSize: 16,
          color: destructive ? AppColors.overdueText : AppColors.accent,
          onTap: () => Navigator.pop(ctx, true),
        ),
        const SizedBox(height: 10),
        SolidButton(
          label: 'Cancel',
          height: 56,
          radius: AppRadius.cta,
          fontSize: 16,
          color: AppColors.surface,
          foreground: AppColors.ink,
          border: AppColors.border,
          onTap: () => Navigator.pop(ctx, false),
        ),
      ]),
    ),
  );
  return r ?? false;
}

/// "Sort" pill button that opens a choice sheet.
class SortButton extends StatelessWidget {
  const SortButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: .96,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const HomelyIcon(HomelyIcons.sliders, size: 14, strokeWidth: 2, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ]),
        ),
      );
}
