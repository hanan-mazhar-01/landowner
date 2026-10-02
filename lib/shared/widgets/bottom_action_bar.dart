import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';

/// Fixed footer used by detail and form screens — hairline top, 12/24/34 padding.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child, this.hint});
  final Widget child;
  final Widget? hint;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final insets = media.viewInsets.bottom;
    final bottom = insets > 0 ? 12.0 : math.max(media.padding.bottom, 16.0);
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (hint != null) ...[hint!, const SizedBox(height: 10)],
        child,
      ]),
    );
  }
}
