import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../shared/widgets/bottom_action_bar.dart';

/// Shared layout for sign-in, sign-up and reset: back button, 28px title,
/// fields, error line, and a footer CTA — built from the form screen's parts.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.cta,
    this.error,
    this.footer,
  });

  final String title, subtitle;
  final List<Widget> fields;
  final Widget cta;
  final String? error;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.background,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CircleIconButton(
                icon: HomelyIcons.back,
                semanticLabel: 'Back',
                onTap: () => context.canPop() ? context.pop() : context.go(Routes.welcome),
              ),
            ),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 22, 24, 24), children: [
              Text(title, style: AppType.title28),
              const SizedBox(height: 10),
              Text(subtitle, style: AppType.body15),
              for (final f in fields) ...[const SizedBox(height: 20), f],
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(error!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.overdueText)),
                      ),
              ),
            ]),
          ),
          BottomActionBar(child: Column(mainAxisSize: MainAxisSize.min, children: [cta, ?footer])),
        ]),
      );
}

/// Label + control pair matching the form system.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.trailing});
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const Spacer(),
          ?trailing,
        ]),
        const SizedBox(height: 8),
        child,
      ]);
}
