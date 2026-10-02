import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/charts/bars.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../../../core/widgets/text_blocks.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../shared/providers/collections.dart';
import '../../../../shared/providers/portfolio.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/sub_page.dart';
import '../../domain/report_builder.dart';
import '../widgets/finance_sections.dart';
import 'report_exporter.dart';
import 'reports_screen.dart';

final reportProvider = Provider.autoDispose.family<ReportData, ReportType>((ref, type) {
  final f = ref.watch(reportFilterProvider);
  return ReportBuilder.build(
    type: type,
    period: f.period,
    propertyId: f.propertyId,
    metrics: ref.watch(propertyMetricsProvider),
    ledger: ref.watch(ledgerProvider).value ?? const [],
    charges: ref.watch(chargesProvider).value ?? const [],
    maintenance: ref.watch(maintenanceProvider).value ?? const [],
  );
});

/// Report detail — summary, chart, totals, breakdown, CSV / PDF export.
class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({super.key, required this.type});
  final ReportType type;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  int? _sel;
  bool _busy = false;

  Future<void> _export(Future<void> Function(ReportData) f, ReportData r) async {
    setState(() => _busy = true);
    try {
      await f(r);
    } catch (_) {
      ref.read(toastProvider.notifier).show('Couldn’t export on this device');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(reportProvider(widget.type));
    final s = r.series;
    final sel = (_sel ?? s.length - 1).clamp(0, s.length - 1);
    final soft = TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: .7));
    Widget fig(String l, String v, {bool big = false}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: soft),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(v, style: AppType.num(big ? 24 : 18).copyWith(color: AppColors.white)),
            ),
          ]),
        );
    final isRental = widget.type == ReportType.rental;

    return ColoredBox(
      color: AppColors.background,
      child: Column(children: [
        Expanded(
          child: SubPage(title: r.type.label, subtitle: '${r.period.label} · ${r.period.range}', slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverList.list(children: [
                GradientCard(
                  radius: AppRadius.hero,
                  shadow: AppShadows.heroCard,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    fig(isRental ? 'Collected' : 'Income', Money.compact(r.income)),
                    const SizedBox(width: 8),
                    fig(isRental ? 'Outstanding' : 'Expenses', Money.compact(r.expense)),
                    const SizedBox(width: 8),
                    fig(isRental ? 'Due' : 'Net cash flow', Money.compact(isRental ? r.income + r.expense : r.net), big: true),
                  ]),
                ),
                if (r.note.isNotEmpty)
                  Padding(padding: const EdgeInsets.fromLTRB(8, 10, 8, 0), child: Text(r.note, style: AppType.caption)),
                const SizedBox(height: 14),
                SurfaceCard(
                  radius: AppRadius.hero,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.fullLabels[sel], style: AppType.caption),
                    const SizedBox(height: 2),
                    Text(Money.compact(s.income[sel] - s.expense[sel]), style: AppType.num(18)),
                    const SizedBox(height: 16),
                    CashBars(income: s.income, expense: s.expense, labels: s.labels, selected: sel, onSelect: (i) => setState(() => _sel = i)),
                  ]),
                ),
              ]),
            ),
            if (r.categories.isNotEmpty) SliverToBoxAdapter(child: ExpenseDonutCard(shares: r.categories)),
            const SliverToBoxAdapter(child: Overline('Breakdown')),
            SliverToBoxAdapter(
              child: SurfaceCard(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                radius: AppRadius.list,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      const Expanded(flex: 5, child: SizedBox()),
                      for (final c in r.columns)
                        Expanded(flex: 3, child: Text(c, textAlign: TextAlign.right, style: AppType.micro11Bold.copyWith(color: AppColors.textMuted))),
                    ]),
                  ),
                  for (final row in r.rows)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.dividerSoft))),
                      child: Row(children: [
                        Expanded(
                          flex: 5,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(row.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.rowTitle),
                            if (row.sub.isNotEmpty) Text(row.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption),
                          ]),
                        ),
                        for (var i = 0; i < row.values.length; i++)
                          Expanded(
                            flex: 3,
                            child: Text(r.cell(i, row.values[i]),
                                textAlign: TextAlign.right,
                                style: i == row.values.length - 1
                                    ? AppType.num(14, FontWeight.w800).copyWith(color: AppColors.primary)
                                    : const TextStyle(fontSize: 13, color: AppColors.ink)),
                          ),
                      ]),
                    ),
                  if (r.rows.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: MetaText('Nothing recorded in this period.')),
                ]),
              ),
            ),
          ]),
        ),
        BottomActionBar(
          child: Row(children: [
            Expanded(
              child: SolidButton(
                label: 'Export CSV',
                height: 56,
                radius: AppRadius.cta,
                color: AppColors.surface,
                foreground: AppColors.ink,
                border: AppColors.border,
                onTap: _busy ? null : () => _export(ReportExporter.csv, r),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientCta(
                label: _busy ? 'Preparing…' : 'Export PDF',
                shadow: const [],
                onTap: _busy ? null : () => _export(ReportExporter.pdf, r),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
