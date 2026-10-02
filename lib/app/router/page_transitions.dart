import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_motion.dart';

/// Every screen enters with the design's `hIn`: 380ms fade + 10px rise on
/// `cubic-bezier(.2,.8,.2,1)`.
CustomTransitionPage<void> homelyPage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.screenIn,
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, _, child) {
        if (Motion.reduced(context)) return child;
        final t = CurvedAnimation(parent: animation, curve: AppMotion.standard);
        return FadeTransition(
          opacity: t,
          child: AnimatedBuilder(
            animation: t,
            child: child,
            builder: (_, c) => Transform.translate(offset: Offset(0, 10 * (1 - t.value)), child: c),
          ),
        );
      },
    );
