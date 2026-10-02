import 'package:flutter/widgets.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/widgets/pressable.dart';
import '../domain/app_notification.dart';

/// Icon + tone per category (`CI` map in the design).
(HomelyIcons, Tone) categoryStyle(AppNotification n) {
  if (n.critical) return (HomelyIcons.alert, Tone.bad);
  return switch (n.category) {
    NotificationCategory.rent => (HomelyIcons.coin, Tone.ok),
    NotificationCategory.lease => (HomelyIcons.calendar, Tone.info),
    NotificationCategory.maintenance => (HomelyIcons.wrench, Tone.warn),
    NotificationCategory.documents => (HomelyIcons.file, Tone.info),
    NotificationCategory.finance => (HomelyIcons.chart, Tone.neutral),
    NotificationCategory.property => (HomelyIcons.home, Tone.info),
  };
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.n, required this.time, required this.onTap});
  final AppNotification n;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = categoryStyle(n);
    return Pressable(
      onTap: onTap,
      scale: .99,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: n.unread ? AppColors.surface : AppColors.readRow,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(14)),
            child: HomelyIcon(icon, size: 18, color: tone.fg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.title,
                  style: TextStyle(
                      fontSize: 15, fontWeight: n.unread ? FontWeight.w700 : FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(n.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textFaint)),
            const SizedBox(height: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: n.unread ? AppColors.accent : AppColors.transparent, shape: BoxShape.circle),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Dark "Coming up" reminder card.
class UpcomingCard extends StatelessWidget {
  const UpcomingCard({
    super.key,
    required this.type,
    required this.tag,
    required this.title,
    required this.property,
    required this.amount,
    required this.onTap,
  });

  final String type, tag, title, property, amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(type,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blue300, letterSpacing: .3)),
              const Spacer(),
              Text(tag, style: TextStyle(fontSize: 11, color: AppColors.white.withValues(alpha: .7))),
            ]),
            const SizedBox(height: 10),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.num(16).copyWith(color: AppColors.white)),
            const SizedBox(height: 2),
            Text(property,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: .75))),
            const SizedBox(height: 10),
            Text(amount.isEmpty ? ' ' : amount, style: AppType.num(14, FontWeight.w700).copyWith(color: AppColors.white)),
          ]),
        ),
      );
}
