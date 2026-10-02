import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/notification_permission.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import 'floating_nav_bar.dart';
import 'quick_action_overlay.dart';
import 'quick_actions_controller.dart';

/// Tab shell: keeps each tab's state alive (indexed stack), replays the
/// screen entrance on tab change, and hosts the nav bar + quick actions.
class HomelyShell extends ConsumerWidget {
  const HomelyShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  /// Max width of the floating nav on tablets.
  static const _navMaxWidth = 460.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    // Float clear of the home indicator / gesture bar instead of sitting on it.
    final navBottom = math.max(media.padding.bottom + 10, 22.0);

    return ColoredBox(
      color: AppColors.background,
      child: Stack(children: [
        Positioned.fill(child: _TabEntrance(index: shell.currentIndex, child: shell)),
        const _AskNotificationsOnce(),
        QuickActionOverlay(
          navBottom: navBottom,
          onAction: (a) => context.push(Routes.add(a.name)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: navBottom,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _navMaxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FloatingNavBar(
                  index: shell.currentIndex,
                  onSelect: (i) {
                    ref.read(quickActionsProvider.notifier).close();
                    shell.goBranch(i, initialLocation: i == shell.currentIndex);
                  },
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Replays the design's `hIn` entrance whenever the tab changes, without
/// rebuilding (and so without losing) the tab's state.
class _TabEntrance extends StatefulWidget {
  const _TabEntrance({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_TabEntrance> createState() => _TabEntranceState();
}

class _TabEntranceState extends State<_TabEntrance> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: AppMotion.screenIn, value: 1);
  late final _t = CurvedAnimation(parent: _c, curve: AppMotion.standard);

  @override
  void didUpdateWidget(_TabEntrance old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !Motion.reduced(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (_, child) => Opacity(
          opacity: _t.value,
          child: Transform.translate(offset: Offset(0, 10 * (1 - _t.value)), child: child),
        ),
      );
}

/// Users who signed in without going through onboarding (e.g. on a new
/// device) are asked for notification permission once, after Home appears.
class _AskNotificationsOnce extends StatefulWidget {
  const _AskNotificationsOnce();

  @override
  State<_AskNotificationsOnce> createState() => _AskNotificationsOnceState();
}

class _AskNotificationsOnceState extends State<_AskNotificationsOnce> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), NotificationPermission.requestIfNeverAsked);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
