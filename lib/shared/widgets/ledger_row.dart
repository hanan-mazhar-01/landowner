import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../core/icons/homely_icon.dart';
import '../../core/utils/formatters.dart';

/// Income / expense line: round tinted arrow, title + meta, signed amount.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.income,
  });

  final String title;
  final String subtitle;
  final int amount;
  final bool income;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: income ? AppColors.positiveTint : AppColors.neutralTint,
              shape: BoxShape.circle,
            ),
            child: HomelyIcon(
              HomelyIcons.arrowUpRight,
              size: 16,
              strokeWidth: 2.2,
              color: income ? AppColors.positiveText : AppColors.textSecondary,
              rotation: income ? 1.5708 : 0,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
          const SizedBox(width: 10),
          Text(
            Money.signed(income ? amount : -amount),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: income ? AppColors.positiveText : AppColors.ink,
            ),
          ),
        ]),
      );
}

/// Tinted-icon list row inside a white card ("Needs your attention").
class AlertRow extends StatelessWidget {
  const AlertRow({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.first = false,
  });

  final HomelyIcons icon;
  final Tone tone;
  final String title, subtitle, trailing;
  final VoidCallback? onTap;
  final bool first;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            border: first ? null : const Border(top: BorderSide(color: AppColors.dividerSoft)),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(14)),
              child: HomelyIcon(icon, size: 19, color: tone.fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ]),
            ),
            const SizedBox(width: 10),
            Text(trailing, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tone.fg)),
          ]),
        ),
      );
}
