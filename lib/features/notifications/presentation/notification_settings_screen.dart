import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/text_blocks.dart';
import '../../../app/router/routes.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/widgets/toast.dart';
import '../../leases/domain/lease.dart';
import '../data/notification_settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const _rows = [
    ('push', 'Notifications', 'Master switch for every alert on this device'),
    ('rent', 'Rent reminders', 'Before and on each due date'),
    ('pay', 'Payment updates', 'When rent is paid or becomes overdue'),
    ('lease', 'Lease reminders', 'Renewals and expirations'),
    ('maint', 'Maintenance', 'Scheduled visits and urgent issues'),
    ('docs', 'Document expiry', 'Files with an expiry date'),
    ('ins', 'Insurance', 'Policy renewals'),
    ('fin', 'Monthly summary', 'A nudge on the 1st to review last month'),
    ('quiet', 'Quiet hours', 'Hold automatic alerts 22:00 – 07:00'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(notificationSettingsProvider);
    final ctrl = ref.read(notificationSettingsProvider.notifier);
    final map = s.toMap();

    return ColoredBox(
      color: AppColors.background,
      child: ListView(padding: EdgeInsets.zero, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CircleIconButton(icon: HomelyIcons.back, onTap: () => context.pop(), semanticLabel: 'Back'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: PageTitle('Notification settings',
              subtitle: 'Choose what LandOwner tells you, and when.',
              style: AppType.title30.copyWith(letterSpacing: -1.1)),
        ),
        SurfaceCard(
          margin: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          radius: AppRadius.list,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            for (var i = 0; i < _rows.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                    border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.dividerSoft))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_rows[i].$2, style: AppType.rowTitle),
                      const SizedBox(height: 2),
                      Text(_rows[i].$3, style: AppType.caption),
                    ]),
                  ),
                  HomelyToggle(
                    value: map[_rows[i].$1] ?? false,
                    semanticLabel: _rows[i].$2,
                    onChanged: (_) => ctrl.toggle(_rows[i].$1),
                  ),
                ]),
              ),
          ]),
        ),
        const Overline('Default reminder timing'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TimingGrid(selected: s.defaultTiming, onToggle: ctrl.toggleTiming, showCheck: false),
        ),
        const Overline('Test Notification'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
          child: SurfaceCard(
            radius: AppRadius.card,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Test Alert on iPhone', style: AppType.rowTitle),
              const SizedBox(height: 4),
              Text('Test instant alert or schedule a reminder to arrive in 1 minute.', style: AppType.caption),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Pressable(
                    onTap: () async {
                      await LocalNotificationService.requestPermission();
                      await LocalNotificationService.show(
                        id: 99998,
                        title: 'LandOwner Immediate Test',
                        body: 'Push & alert system is active and working! 🔔',
                        route: Routes.notifications,
                      );
                      ref.read(toastProvider.notifier).show('Instant notification sent!');
                    },
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.blue200),
                      ),
                      child: const Text('Test Now',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientCta(
                    label: 'Schedule 1 Min',
                    height: 44,
                    padding: 12,
                    trailing: const HomelyIcon(HomelyIcons.bell, color: AppColors.white, size: 16),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white),
                    onTap: () async {
                      await LocalNotificationService.requestPermission();
                      final when = DateTime.now().add(const Duration(minutes: 1));
                      await LocalNotificationService.sync([
                        ScheduledAlert(
                          key: 'test:1min:${DateTime.now().millisecondsSinceEpoch}',
                          at: when,
                          title: 'LandOwner 1-Min Reminder',
                          body: 'Your 1-minute test alert arrived successfully! ⏰',
                          route: Routes.notifications,
                        ),
                      ]);
                      ref.read(toastProvider.notifier).show('Scheduled for 1 min! Lock screen to test.');
                    },
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// 2×2 grid of reminder offsets (7d, 3d, 1d, on due date).
class TimingGrid extends StatelessWidget {
  const TimingGrid({super.key, required this.selected, required this.onToggle, this.showCheck = true});
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final bool showCheck;

  static const _order = [ReminderOffset.oneDay, ReminderOffset.threeDays, ReminderOffset.sevenDays, ReminderOffset.dueDate];

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.3,
        children: [
          for (final o in _order)
            GestureDetector(
              onTap: () => onToggle(o.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: const Cubic(.2, .8, .2, 1),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected.contains(o.key) ? AppColors.blue100 : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected.contains(o.key) ? AppColors.blue300 : AppColors.border),
                ),
                child: Row(children: [
                  if (showCheck) ...[
                    Opacity(
                      opacity: selected.contains(o.key) ? 1 : 0,
                      child: const HomelyIcon(HomelyIcons.check, size: 16, strokeWidth: 2.4, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(o.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected.contains(o.key) ? AppColors.primary : AppColors.textMuted,
                        )),
                  ),
                ]),
              ),
            ),
        ],
      );
}
