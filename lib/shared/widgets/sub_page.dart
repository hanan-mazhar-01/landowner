import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/icons/homely_icon.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/text_blocks.dart';

/// Pushed list page in the design's language: back button, optional action,
/// 32px title + subtitle, then slivers.
class SubPage extends StatelessWidget {
  const SubPage({super.key, required this.title, this.subtitle, required this.slivers, this.action, this.maxWidth = 720});
  final String title;
  final String? subtitle;
  final List<Widget> slivers;
  final Widget? action;

  /// Content width cap so lists don't stretch edge-to-edge on iPad.
  final double maxWidth;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.background,
        child: LayoutBuilder(builder: (context, c) {
          final side = c.maxWidth > maxWidth ? (c.maxWidth - maxWidth) / 2 : 0.0;
          return CustomScrollView(slivers: [
            for (final s in _all(context)) SliverPadding(padding: EdgeInsets.symmetric(horizontal: side), sliver: s),
          ]);
        }),
      );

  List<Widget> _all(BuildContext context) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 0),
              child: Row(children: [
                CircleIconButton(icon: HomelyIcons.back, onTap: () => context.pop(), semanticLabel: 'Back'),
                const Spacer(),
                ?action,
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: PageTitle(title, subtitle: subtitle),
            ),
          ),
          ...slivers,
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ];
}

/// Round "+" action used in sub-page headers.
class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.onTap, this.label = 'Add'});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => CircleIconButton(
        icon: HomelyIcons.plus,
        color: AppColors.blue100,
        iconColor: AppColors.primary,
        semanticLabel: label,
        onTap: onTap,
      );
}
