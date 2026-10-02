import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/text_blocks.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/repositories.dart';
import '../domain/app_notification.dart';
import '../domain/usecases/notification_actions.dart';
import 'notification_widgets.dart';

final notificationActionsProvider = Provider((ref) => NotificationActions(ref.read(notificationRepoProvider)));

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  static const _cats = ['All', 'Rent', 'Lease', 'Maintenance', 'Documents', 'Finance', 'Property'];
  String _cat = 'All';
  int _shown = 30;

  @override
  Widget build(BuildContext context) {
    final clock = ref.read(clockProvider);
    final all = [...?ref.watch(notificationsProvider).value]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final list = all.where((n) => _cat == 'All' || n.category.label == _cat).toList();
    final unread = all.where((n) => n.unread).length;
    final names = {for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
    final now = DateTime.now();
    final upcoming = (ref.watch(remindersProvider).value ?? const []).where((r) => !r.done && r.at.isAfter(now)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    void open(AppNotification n) {
      ref.read(notificationActionsProvider).markRead(n.id);
      if (n.target != null) context.push(n.target!);
    }

    return ColoredBox(
      color: AppColors.background,
      child: CustomScrollView(slivers: [
        SliverList.list(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 0),
            child: Row(children: [
              CircleIconButton(icon: HomelyIcons.back, onTap: () => context.pop(), semanticLabel: 'Back'),
              const Spacer(),
              CircleIconButton(
                icon: HomelyIcons.sliders,
                iconSize: 19,
                strokeWidth: 1.9,
                semanticLabel: 'Notification settings',
                onTap: () => context.push(Routes.notificationSettings),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: PageTitle('Notifications', subtitle: '$unread unread')),
              if (unread > 0) LinkText('Mark all read', onTap: ref.read(notificationActionsProvider).markAllRead),
            ]),
          ),
          if (upcoming.isNotEmpty) ...[
            const Overline('Coming up', padding: EdgeInsets.fromLTRB(24, 22, 24, 10)),
            SizedBox(
              height: 142,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                itemCount: upcoming.length.clamp(0, 5),
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final r = upcoming[i];
                  return UpcomingCard(
                    type: r.type.label,
                    tag: Dates.dMy(r.at),
                    title: r.title,
                    property: names[r.propertyId] ?? '',
                    amount: r.amountLabel,
                    onTap: () => context.push(Routes.reminder(r.id)),
                  );
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 12),
            child: ChipRow(labels: _cats, selected: _cat, onSelect: (c) => setState(() => _cat = c)),
          ),
        ]),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: list.length.clamp(0, _shown),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              if (i == _shown - 1 && list.length > _shown) {
                WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? setState(() => _shown += 30) : null);
              }
              return NotificationTile(n: list[i], time: Dates.ago(list[i].createdAt, clock.now()), onTap: () => open(list[i]));
            },
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 32),
          sliver: SliverToBoxAdapter(
            child: list.isEmpty
                ? SurfaceCard(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('All quiet here', style: AppType.cardTitle),
                      const SizedBox(height: 6),
                      Text('Nothing in this category right now.', style: AppType.body),
                    ]),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ]),
    );
  }
}
