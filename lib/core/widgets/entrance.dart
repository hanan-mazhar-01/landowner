import 'package:flutter/widgets.dart';

import '../../app/theme/app_motion.dart';

/// The design's `hIn` (380ms, 10px rise) and `fadeUp` (260ms, 6px rise)
/// entrance. Plays once when first built.
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.duration = AppMotion.screenIn,
    this.offset = 10,
    this.curve = AppMotion.standard,
  });

  const Entrance.fadeUp({super.key, required this.child})
      : duration = AppMotion.fadeUp,
        offset = 6,
        curve = Curves.ease;

  final Widget child;
  final Duration duration;
  final double offset;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, duration);
    if (d == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: d,
      curve: curve,
      child: child,
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, offset * (1 - t)), child: c),
      ),
    );
  }
}
