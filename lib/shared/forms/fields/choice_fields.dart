import 'package:flutter/widgets.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/pressable.dart';
import '../../../features/properties/domain/property.dart';

/// Segmented choice — 42px tiles that wrap and stretch; ink when selected.
class SegField extends StatelessWidget {
  const SegField({super.key, required this.options, required this.value, required this.onChanged, this.chips = false});
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  /// Chip variant: 36px pills that don't stretch.
  final bool chips;

  @override
  Widget build(BuildContext context) {
    Widget tile(String o) {
      final on = o == value;
      return Pressable(
        onTap: () => onChanged(o),
        scale: .97,
        child: AnimatedContainer(
          duration: Motion.of(context, AppMotion.transition),
          curve: AppMotion.standard,
          height: chips ? 36 : 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(chips ? 18 : 14),
            border: Border.all(color: on ? AppColors.ink : AppColors.border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              o,
              maxLines: 1,
              style: TextStyle(
                fontSize: chips ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: on ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    if (chips) return Wrap(spacing: 6, runSpacing: 6, children: [for (final o in options) tile(o)]);
    // Stretch to fill each row, like `flex: 1 0 auto` in the design.
    return LayoutBuilder(builder: (context, c) {
      final rows = <List<String>>[[]];
      var used = 0.0;
      for (final o in options) {
        // Safe minimum width per option (char width + padding + margins)
        final w = o.length * 11.0 + 28.0;
        if (used + w > c.maxWidth && rows.last.isNotEmpty) {
          rows.add([]);
          used = 0;
        }
        rows.last.add(o);
        used += w;
      }
      return Column(children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 6),
          Row(children: [
            for (var i = 0; i < rows[r].length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                flex: (rows[r][i].length * 10).clamp(40, 160),
                child: tile(rows[r][i]),
              ),
            ],
          ]),
        ],
      ]);
    });
  }
}

/// Horizontal property picker — 118×80 photo tiles with a 3px blue ring.
class PropertyPicker extends StatelessWidget {
  const PropertyPicker({super.key, required this.properties, required this.value, required this.onChanged});
  final List<Property> properties;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 124,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: properties.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final p = properties[i];
            final on = p.id == value;
            return GestureDetector(
              onTap: () => onChanged(p.id),
              child: AnimatedOpacity(
                duration: Motion.of(context, AppMotion.colorShift),
                opacity: on ? 1 : .7,
                child: SizedBox(
                  width: 118,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AnimatedContainer(
                      duration: Motion.of(context, AppMotion.colorShift),
                      width: 118,
                      height: 80,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: on ? AppColors.accent : AppColors.transparent, spreadRadius: 3)],
                      ),
                      child: NetImage(p.coverUrl),
                    ),
                    const SizedBox(height: 6),
                    Text(p.name,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.25, color: AppColors.ink)),
                  ]),
                ),
              ),
            );
          },
        ),
      );
}
