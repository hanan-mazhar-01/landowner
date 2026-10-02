import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/text_blocks.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/widgets/ledger_row.dart';
import '../../../shared/widgets/sub_page.dart';
import '../domain/reminder.dart';

(HomelyIcons, Tone) reminderStyle(ReminderType t) => switch (t) {
      ReminderType.rent => (HomelyIcons.coin, Tone.ok),
      ReminderType.lease => (HomelyIcons.calendar, Tone.info),
      ReminderType.maintenance => (HomelyIcons.wrench, Tone.warn),
      ReminderType.insurance => (HomelyIcons.shield, Tone.info),
      ReminderType.document => (HomelyIcons.file, Tone.info),
      _ => (HomelyIcons.bell, Tone.info),
    };

/// Calendar — every open reminder grouped by day.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.read(clockProvider).today();
    final names = {for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
    final list = (ref.watch(remindersProvider).value ?? const <Reminder>[]).where((r) => !r.done).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final days = <DateTime, List<Reminder>>{};
    for (final r in list) {
      days.putIfAbsent(DateTime(r.at.year, r.at.month, r.at.day), () => []).add(r);
    }
    String label(DateTime d) {
      final n = d.difference(today).inDays;
      return n == 0 ? 'Today' : n == 1 ? 'Tomorrow' : Dates.longDay(d);
    }

    return SubPage(
      title: 'Calendar',
      subtitle: '${list.length} upcoming reminders',
      action: AddButton(onTap: () => context.push(Routes.add('reminder'))),
      slivers: [
        if (days.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyStateCard(title: 'All quiet here', message: 'Nothing scheduled.', icon: HomelyIcons.calendar),
          ),
        for (final e in days.entries)
          SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Overline(label(e.key), padding: const EdgeInsets.fromLTRB(24, 22, 24, 10)),
              SurfaceCard(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  for (final (i, r) in e.value.indexed)
                    AlertRow(
                      first: i == 0,
                      icon: reminderStyle(r.type).$1,
                      tone: r.at.isBefore(today) ? Tone.bad : reminderStyle(r.type).$2,
                      title: r.title,
                      subtitle: [names[r.propertyId] ?? '', r.amountLabel].where((s) => s.isNotEmpty).join(' · '),
                      trailing: Dates.hm(r.at),
                      onTap: () => context.push(Routes.reminder(r.id)),
                    ),
                ]),
              ),
            ]),
          ),
      ],
    );
  }
}
