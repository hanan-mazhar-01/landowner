import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_decor.dart';
import '../../app/theme/app_motion.dart';
import 'pressable.dart';

/// 52×32 toggle — `#4D6DFA` on, `#DDE3F3` off, 26px white knob.
class HomelyToggle extends StatelessWidget {
  const HomelyToggle({super.key, required this.value, required this.onChanged, this.semanticLabel});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: Motion.of(context, AppMotion.colorShift),
          width: 52,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AppColors.accent : AppColors.disabledTrack,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedAlign(
            duration: Motion.of(context, AppMotion.toggle),
            curve: AppMotion.standard,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: AppShadows.knob),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal chip row (filters, notification categories).
class ChipRow extends StatelessWidget {
  const ChipRow({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.activeBg = AppColors.ink,
    this.height = 34,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelect;
  final Color activeBg;
  final double height, fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: labels.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final on = labels[i] == selected;
            return Pressable(
              onTap: () => onSelect(labels[i]),
              scale: .96,
              child: AnimatedContainer(
                duration: Motion.of(context, AppMotion.transition),
                curve: AppMotion.standard,
                padding: EdgeInsets.symmetric(horizontal: height > 34 ? 16 : 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? activeBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: on ? AppColors.white : AppColors.textSecondary)),
              ),
            );
          },
        ),
      );
}

/// Inset segmented control — `#F1F3FF` track, white raised selection
/// (property Performance: Value / Rent / Costs).
class SoftSegments extends StatelessWidget {
  const SoftSegments({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: Motion.of(context, AppMotion.transition),
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == index ? AppColors.surface : AppColors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: i == index ? AppShadows.segment : null,
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i == index ? AppColors.ink : AppColors.textMuted)),
              ),
            ),
        ]),
      );
}

/// White track with a sliding ink thumb (Finance range: 1M 6M 1Y ALL).
class InkSegments extends StatelessWidget {
  const InkSegments({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  static const _w = 42.0, _h = 30.0;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.card,
        ),
        child: SizedBox(
          width: _w * labels.length,
          height: _h,
          child: Stack(children: [
            AnimatedPositioned(
              duration: Motion.of(context, AppMotion.transition),
              curve: AppMotion.standard,
              left: index * _w,
              top: 0,
              child: Container(
                width: _w,
                height: _h,
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(11)),
              ),
            ),
            Row(children: [
              for (var i = 0; i < labels.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: SizedBox(
                    width: _w,
                    height: _h,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: Motion.of(context, AppMotion.colorShift),
                        style: DefaultTextStyle.of(context).style.merge(TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: i == index ? AppColors.white : AppColors.textMuted)),
                        child: Text(labels[i]),
                      ),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      );
}
