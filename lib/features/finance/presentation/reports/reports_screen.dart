import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/sheets.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../../../shared/forms/fields/picker_fields.dart';
import '../../../../shared/providers/collections.dart';
import '../../../../shared/widgets/sub_page.dart';
import '../../domain/report_builder.dart';

/// Selected period + property for reports (shared by list and detail).
class ReportFilter {
  const ReportFilter(this.period, this.propertyId);
  final ReportPeriod period;
  final String? propertyId;
}

class ReportFilterController extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => ReportFilter(ReportPeriod.preset('This month', ref.read(clockProvider).today()), null);
  void set(ReportFilter f) => state = f;
}

final reportFilterProvider = NotifierProvider<ReportFilterController, ReportFilter>(ReportFilterController.new);

/// Reports — seven report types over a period and property.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static const _presets = ['This month', 'Last month', 'This year', 'Last year', 'Custom'];

  Future<void> _custom(BuildContext context, WidgetRef ref) async {
    final f = ref.read(reportFilterProvider);
    var from = f.period.from, to = f.period.to.subtract(const Duration(days: 1));
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.paddingOf(ctx).bottom + 20),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Custom range', style: AppType.title22),
            const SizedBox(height: 16),
            const Text('From', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            DateTimeField(value: from, onChanged: (d) => set(() => from = d)),
            const SizedBox(height: 14),
            const Text('To', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            DateTimeField(value: to, onChanged: (d) => set(() => to = d)),
            const SizedBox(height: 20),
            GradientCta(label: 'Apply', onTap: () => Navigator.pop(ctx, true)),
          ]),
        ),
      ),
    );
    if (ok == true && !to.isBefore(from)) {
      ref.read(reportFilterProvider.notifier).set(ReportFilter(
            ReportPeriod('Custom', DateTime(from.year, from.month, from.day), DateTime(to.year, to.month, to.day + 1)),
            f.propertyId,
          ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(reportFilterProvider);
    final props = <String, String>{for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
    final today = ref.read(clockProvider).today();

    return SubPage(
      title: 'Reports',
      subtitle: '${f.period.label} · ${f.propertyId == null ? 'All properties' : props[f.propertyId]}',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ChipRow(
              labels: _presets,
              selected: f.period.label,
              onSelect: (p) => p == 'Custom'
                  ? _custom(context, ref)
                  : ref.read(reportFilterProvider.notifier).set(ReportFilter(ReportPeriod.preset(p, today), f.propertyId)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              SortButton(
                label: f.propertyId == null ? 'All properties' : props[f.propertyId] ?? '',
                onTap: () async {
                  final r = await showChoiceSheet(context,
                      title: 'Property', options: ['All properties', ...props.values], selected: props[f.propertyId] ?? 'All properties');
                  if (r == null) return;
                  final id = props.entries.where((e) => e.value == r).map((e) => e.key).firstOrNull;
                  ref.read(reportFilterProvider.notifier).set(ReportFilter(f.period, id));
                },
              ),
              const Spacer(),
              Text(f.period.range, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverList.separated(
            itemCount: ReportType.values.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final t = ReportType.values[i];
              return Pressable(
                onTap: () => context.push(Routes.report(t.name)),
                scale: .99,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: i == 0 ? null : AppColors.surface,
                    gradient: i == 0 ? AppGradients.heroAlt : null,
                    borderRadius: BorderRadius.circular(AppRadius.list),
                  ),
                  child: Row(children: [
                    IconTile(
                      size: 44,
                      color: i == 0 ? AppColors.white.withValues(alpha: .16) : AppColors.blue50,
                      child: HomelyIcon(t.icon, size: 20, color: i == 0 ? AppColors.white : AppColors.primary, strokeWidth: 1.9),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t.label, style: AppType.cardTitle.copyWith(color: i == 0 ? AppColors.white : AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(t.description,
                            style: TextStyle(fontSize: 12, color: i == 0 ? AppColors.white.withValues(alpha: .8) : AppColors.textMuted)),
                      ]),
                    ),
                    HomelyIcon(HomelyIcons.chevronRight, size: 18, color: i == 0 ? AppColors.white : AppColors.chevron),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
