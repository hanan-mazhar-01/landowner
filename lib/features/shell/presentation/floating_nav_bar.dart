import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_motion.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/widgets/pressable.dart';
import 'quick_actions_controller.dart';

/// Floating pill navigation: Home · Properties · [+] · Finance · More.
class FloatingNavBar extends ConsumerWidget {
  const FloatingNavBar({super.key, required this.index, required this.onSelect, this.ink = false});

  /// Branch index 0..3 (Home, Properties, Finance, More).
  final int index;
  final ValueChanged<int> onSelect;

  /// `navTone: ink` variant from the design.
  final bool ink;

  static const _items = [
    ('assets/nav/home.png', 'Home'),
    ('assets/nav/properties.png', 'Properties'),
    ('assets/nav/finance.png', 'Finance'),
    ('assets/nav/more.png', 'More'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(quickActionsProvider);
    final on = ink ? AppColors.white : AppColors.primary;
    final off = ink ? AppColors.navOffInk : AppColors.textMuted;
    final slot = index >= 2 ? index + 1 : index; // skip the centre + slot

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: ink ? AppColors.ink : AppColors.navLight,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          ...AppShadows.nav,
          BoxShadow(color: ink ? const Color(0x0FFFFFFF) : const Color(0x0F14205A), spreadRadius: 1),
        ],
      ),
      child: LayoutBuilder(builder: (context, c) {
        final slotW = c.maxWidth / 5;
        return Stack(children: [
          AnimatedPositioned(
            duration: Motion.of(context, AppMotion.navIndicator),
            curve: AppMotion.standard,
            top: 9,
            left: slot * slotW + (slotW - 58) / 2,
            child: Container(
              width: 58,
              height: 52,
              decoration: BoxDecoration(
                color: ink ? const Color(0x474D6DFA) : AppColors.blue100,
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          Row(children: [
            for (var s = 0; s < 5; s++)
              Expanded(
                child: s == 2
                    ? Center(child: _PlusButton(open: open, onTap: ref.read(quickActionsProvider.notifier).toggle))
                    : _NavItem(
                        icon: _items[s > 2 ? s - 1 : s].$1,
                        label: _items[s > 2 ? s - 1 : s].$2,
                        selected: slot == s,
                        color: slot == s ? on : off,
                        onTap: () => onSelect(s > 2 ? s - 1 : s),
                      ),
              ),
          ]),
        ]);
      }),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  /// Unselected tabs: the artwork in a muted, desaturated blue-grey.
  static const _muted = ColorFilter.matrix([
    0.21, 0.62, 0.08, 0, 18, //
    0.21, 0.62, 0.08, 0, 24, //
    0.21, 0.62, 0.08, 0, 44, //
    0, 0, 0, 0.55, 0,
  ]);

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: .94,
        semanticLabel: label,
        child: SizedBox(
          height: 52,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: Motion.of(context, AppMotion.colorShift),
            builder: (_, c, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The selected icon pops slightly larger in full colour.
                AnimatedScale(
                  scale: selected ? 1.12 : 1,
                  duration: Motion.of(context, AppMotion.navIndicator),
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, AppMotion.colorShift),
                    child: selected
                        ? Image.asset(icon, key: const ValueKey(true), width: 24, height: 24)
                        : ColorFiltered(
                            key: const ValueKey(false),
                            colorFilter: _muted,
                            child: Image.asset(icon, width: 24, height: 24),
                          ),
                  ),
                ),
                const SizedBox(height: 3),
                // Scales down under large accessibility text instead of overflowing the 52px pill.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, maxLines: 1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        haptic: true,
        scale: .94,
        semanticLabel: 'Quick actions',
        child: AnimatedRotation(
          turns: open ? .125 : 0,
          duration: Motion.of(context, AppMotion.plusRotate),
          curve: AppMotion.standard,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppGradients.cta,
              borderRadius: BorderRadius.circular(21),
              boxShadow: AppShadows.plus,
            ),
            child: const Center(child: HomelyIcon(HomelyIcons.plus, size: 24, color: AppColors.white, strokeWidth: 2.4)),
          ),
        ),
      );
}
