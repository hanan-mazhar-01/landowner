import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../app/theme/app_motion.dart';

/// Plays once after [delay]: fades in while sliding from [from] (in logical
/// pixels) and growing from [scale]. Used to stagger the parts of a card.
/// Shows the final state immediately when reduced motion is on.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.from = const Offset(0, 12),
    this.scale = 1,
    this.curve = AppMotion.standard,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Duration delay, duration;
  final Offset from;
  final double scale;
  final Curve curve;
  final Alignment alignment;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: widget.curve);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (_, child) {
      final t = _t.value;
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: widget.from * (1 - t),
          child: widget.scale == 1
              ? child
              : Transform.scale(
                  scale: widget.scale + (1 - widget.scale) * t,
                  alignment: widget.alignment,
                  child: child,
                ),
        ),
      );
    },
  );
}

/// Grows its child horizontally from the left edge (bars, dividers).
class GrowIn extends StatelessWidget {
  const GrowIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget child;
  final Duration delay, duration;

  @override
  Widget build(BuildContext context) {
    final total = Motion.of(context, delay + duration);
    if (total == Duration.zero) return child;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: AppMotion.standard),
      child: child,
      builder: (_, t, c) => ClipRect(
        child: Align(alignment: Alignment.centerLeft, widthFactor: t, child: c),
      ),
    );
  }
}

/// Counts up from 0 on first build, then animates between values when the
/// number changes. [format] turns the in-between value into text.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.delay = Duration.zero,
    this.duration = AppMotion.counter,
    this.maxLines,
  });

  final num value;
  final String Function(num v) format;
  final TextStyle? style;
  final Duration delay, duration;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final total = Motion.of(context, delay + duration);
    if (total == Duration.zero) return Text(format(value), style: style, maxLines: maxLines);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: total,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: Curves.easeOutCubic),
      builder: (_, v, _) => Text(format(v == value ? value : v.round()), style: style, maxLines: maxLines),
    );
  }
}
