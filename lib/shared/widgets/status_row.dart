import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/icons/homely_icon.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/pressable.dart';

/// Rounded list card (notification-row language) with a leading tile or
/// avatar, title/meta, and a trailing figure over a status pill.
class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    this.icon,
    this.initials,
    required this.tone,
    required this.title,
    required this.subtitle,
    this.meta,
    this.figure,
    this.status,
    this.statusTone,
    this.onTap,
  });

  final HomelyIcons? icon;
  final String? initials;
  final Tone tone;
  final String title, subtitle;
  final String? meta, figure, status;
  final Tone? statusTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: .99,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            if (initials != null)
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
                child: Text(initials!, style: AppType.num(15).copyWith(color: AppColors.primary)),
              )
            else
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(14)),
                child: HomelyIcon(icon ?? HomelyIcons.file, size: 18, color: tone.fg),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.rowTitle),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(meta!,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textFaint)),
                ],
              ]),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (figure != null) Text(figure!, style: AppType.num(15)),
              if (status != null) ...[
                const SizedBox(height: 5),
                TonePill.tone(status!, statusTone ?? tone, fontSize: 11),
              ],
            ]),
          ]),
        ),
      );
}
