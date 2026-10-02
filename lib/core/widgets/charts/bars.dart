import 'package:flutter/widgets.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';

/// A bar that grows from the bottom (600ms) and animates height changes (450ms).
class GrowBar extends StatelessWidget {
  const GrowBar({super.key, required this.fraction, required this.color, this.width, this.radius = 8});

  final double fraction;
  final Color color;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final h = (c.maxHeight * fraction.clamp(0, 1)).toDouble();
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Motion.of(context, AppMotion.barGrow),
        curve: AppMotion.standard,
        builder: (_, g, child) => Align(
          alignment: Alignment.bottomCenter,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(1, g, 1),
            child: child,
          ),
        ),
        child: AnimatedContainer(
          duration: Motion.of(context, AppMotion.barResize),
          curve: AppMotion.standard,
          width: width,
          height: h,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
        ),
      );
    });
  }
}

/// Property detail Performance bars — 8 quarters, last one accented.
class QuarterBars extends StatelessWidget {
  const QuarterBars({super.key, required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final mx = values.fold<double>(0, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(children: [
                Expanded(
                  child: GrowBar(
                    key: ValueKey('q$i'),
                    fraction: mx == 0 || values[i] == 0 ? 0 : (values[i] / mx).clamp(.08, 1),
                    color: i == values.length - 1 ? AppColors.accent : AppColors.blue150,
                  ),
                ),
                const SizedBox(height: 6),
                Text(labels[i], style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Finance income (blue) vs expense (ink) grouped bars with tap-to-select.
class CashBars extends StatelessWidget {
  const CashBars({
    super.key,
    required this.income,
    required this.expense,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<int> income, expense;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final mx = income.fold<int>(1, (a, b) => b > a ? b : a).toDouble();
    final n = income.length;
    final bw = n > 8 ? 9.0 : n > 5 ? 14.0 : 20.0;
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: AnimatedOpacity(
                  duration: Motion.of(context, AppMotion.colorShift),
                  opacity: i == selected ? 1 : .38,
                  child: Column(children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GrowBar(key: ValueKey('i$n$i'), fraction: income[i] / mx, color: AppColors.accent, width: bw, radius: 7),
                          const SizedBox(width: 3),
                          GrowBar(key: ValueKey('e$n$i'), fraction: expense[i] / mx, color: AppColors.ink, width: bw, radius: 7),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: i == selected ? AppColors.ink : AppColors.textFaint,
                        )),
                  ]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
