import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/toast.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/usecases.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../domain/reminder.dart';

final reminderByIdProvider = Provider.autoDispose.family<Reminder?, String>((ref, id) {
  for (final r in ref.watch(remindersProvider).value ?? const <Reminder>[]) {
    if (r.id == id) return r;
  }
  return null;
});

class ReminderDetailScreen extends ConsumerWidget {
  const ReminderDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(reminderByIdProvider(id));
    final actions = ref.read(reminderActionsProvider);
    void toast(String m) => ref.read(toastProvider.notifier).show(m);
    final top = MediaQuery.paddingOf(context).top + 8;

    if (r == null) {
      return ColoredBox(
        color: AppColors.background,
        child: Center(
          child: EmptyStateCard(
            title: 'Reminder not found',
            message: 'It was completed or removed.',
            icon: HomelyIcons.bell,
            actionLabel: 'Back',
            onAction: () => context.pop(),
          ),
        ),
      );
    }
    final prop = r.propertyId == null ? null : ref.watch(propertyByIdProvider(r.propertyId!));
    final status = r.done ? 'Completed' : r.notify ? 'Scheduled' : 'Muted';
    final statusColor = r.done ? AppColors.positiveText : r.notify ? AppColors.primary : AppColors.textMuted;
    final soft = TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: .7));
    Widget fig(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: soft),
          const SizedBox(height: 3),
          Text(v, style: AppType.num(20).copyWith(color: AppColors.white)),
        ]);

    return ColoredBox(
      color: AppColors.background,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, top, 16, 0),
          child: Row(children: [
            CircleIconButton(icon: HomelyIcons.back, onTap: () => context.pop(), semanticLabel: 'Back'),
            const Spacer(),
            SolidButton(
              label: 'Edit',
              height: 44,
              radius: 22,
              fontSize: 14,
              color: AppColors.surface,
              foreground: AppColors.primary,
              onTap: () => context.push(Routes.add('reminder', editId: r.id, propertyId: r.propertyId)),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 20), children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TonePill(label: '${r.type.label} · $status', fg: statusColor, bg: AppColors.blue100),
                const SizedBox(height: 8),
                Text(r.title, style: AppType.detailTitle.copyWith(letterSpacing: -1.1)),
                if (prop != null) ...[
                  const SizedBox(height: 8),
                  LinkText('${prop.name} →', size: 15, onTap: () => context.push(Routes.property(prop.id))),
                ],
                if (r.target != null) ...[
                  const SizedBox(height: 4),
                  LinkText('Resolve payment →', size: 15, color: AppColors.overdueText, onTap: () => context.push(r.target!)),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            GradientCard(
              child: Wrap(runSpacing: 16, children: [
                for (final f in [
                  ('Date', Dates.dMy(r.at)),
                  ('Time', Dates.hm(r.at)),
                  if (r.amountLabel.isNotEmpty) ('Amount', r.amountLabel),
                  ('Repeats', r.repeat.label),
                ])
                  FractionallySizedBox(widthFactor: .5, child: fig(f.$1, f.$2)),
              ]),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              radius: AppRadius.list,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: r.notes.isEmpty
                      ? null
                      : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.dividerSoft))),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Notify me', style: AppType.rowTitle),
                        const SizedBox(height: 2),
                        Text(r.sourceLabel, style: AppType.caption),
                      ]),
                    ),
                    HomelyToggle(value: r.notify, semanticLabel: 'Notify me', onChanged: (_) => actions.toggleNotify(r.id)),
                  ]),
                ),
                if (r.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Notes', style: AppType.caption),
                      const SizedBox(height: 4),
                      Text(r.notes, style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.ink)),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: LinkText('Delete reminder', color: AppColors.overdueText, onTap: () async {
                  await actions.delete(r.id);
                  toast('Reminder deleted');
                  if (context.mounted) context.pop();
                }),
              ),
            ),
          ]),
        ),
        BottomActionBar(
          child: Row(children: [
            Expanded(
              flex: 10,
              child: SolidButton(
                label: 'Snooze',
                height: 56,
                radius: AppRadius.cta,
                color: AppColors.surface,
                foreground: AppColors.ink,
                border: AppColors.border,
                onTap: () async {
                  await actions.snooze(r.id);
                  toast('Snoozed · we’ll remind you again later');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 14,
              child: GradientCta(
                label: r.done ? 'Reopen' : 'Mark complete',
                centered: true,
                trailing: const SizedBox.shrink(),
                style: AppType.button15,
                shadow: const [],
                onTap: () async {
                  final done = await actions.toggleComplete(r.id);
                  toast(done ? 'Marked complete' : 'Reminder reopened');
                },
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
