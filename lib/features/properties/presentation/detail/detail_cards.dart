import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/charts/bars.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../../../shared/providers/collections.dart';
import '../../../finance/domain/finance_analytics.dart';
import '../../domain/property_metrics.dart';
import '../widgets/property_cards.dart';

/// "Current value" row with gain pill.
class ValueRow extends StatelessWidget {
  const ValueRow({super.key, required this.m});
  final PropertyMetrics m;

  @override
  Widget build(BuildContext context) {
    final p = m.property;
    final up = p.gain >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Current value', style: AppType.label13),
            const SizedBox(height: 4),
            FittedBox(child: Text(Money.m(p.currentValue), style: AppType.value40)),
          ]),
        ),
        // No purchase price recorded → nothing to compare against.
        if (p.purchasePrice > 0) ...[
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            TonePill.tone('${up ? '+' : '−'}${p.gainPct.abs().toStringAsFixed(1)}%', up ? Tone.ok : Tone.bad,
                fontSize: 13),
            const SizedBox(height: 4),
            Text('vs ${Money.m(p.purchasePrice)} paid', style: AppType.caption),
          ]),
        ],
      ]),
    );
  }
}

/// 2×2 grid: rent, expenses, net, yield.
class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.m});
  final PropertyMetrics m;

  @override
  Widget build(BuildContext context) {
    Widget cell(String l, String v, {Color? c, bool right = true, bool bottom = true}) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                right: right ? const BorderSide(color: AppColors.divider) : BorderSide.none,
                bottom: bottom ? const BorderSide(color: AppColors.divider) : BorderSide.none,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l, style: AppType.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(v, style: AppType.num(21).copyWith(color: c ?? AppColors.ink), maxLines: 1),
              ),
            ]),
          ),
        );
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            cell('Monthly rent', m.monthlyRent == 0 ? '—' : Money.k(m.monthlyRent)),
            cell('Monthly expenses', Money.k(m.monthlyExpenses), right: false),
          ]),
        ),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            cell('Net income', Money.k(m.net), c: AppColors.primary, bottom: false),
            cell('Rental yield', yieldLabel(m), c: AppColors.positiveText, right: false, bottom: false),
          ]),
        ),
      ]),
    );
  }
}

/// Performance card — Value / Rent / Costs over 8 quarters.
class PerformanceCard extends ConsumerStatefulWidget {
  const PerformanceCard({super.key, required this.m, this.initialTab = 0});
  final PropertyMetrics m;
  final int initialTab;

  @override
  ConsumerState<PerformanceCard> createState() => _PerformanceCardState();
}

class _PerformanceCardState extends ConsumerState<PerformanceCard> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final today = ref.read(clockProvider).today();
    final p = widget.m.property;
    final labels = FinanceAnalytics.quarterLabels(today);
    late List<double> values;
    late String head, sub;
    if (_tab == 0) {
      final q0 = DateTime(today.year, ((today.month - 1) ~/ 3) * 3 + 1);
      final firstKnown = p.valueHistory.isEmpty ? p.currentValue : p.valueHistory.first.value;
      values = List.generate(8, (i) {
        if (i == 7) return p.currentValue.toDouble();
        final end = Dates.addMonths(q0, (i - 6) * 3);
        // Quarters that ended before the property was added have no value.
        if (!end.isAfter(p.createdAt)) return 0.0;
        final h = p.valueHistory.where((v) => v.date.isBefore(end));
        return (h.isEmpty ? firstKnown : h.last.value).toDouble();
      });
      head = Money.m(p.currentValue);
      final pct = p.gainPct.abs().toStringAsFixed(1);
      sub = p.purchasePrice == 0
          ? 'Current estimated value'
          : p.gain == 0
              ? 'Unchanged since purchase'
              : '${p.gain > 0 ? 'Up' : 'Down'} $pct% since purchase';
    } else {
      final ledger = ref.watch(ledgerProvider).value ?? const [];
      final v = FinanceAnalytics.quarterlyAverages(ledger, today, p.id, income: _tab == 1);
      values = v.map((e) => e.toDouble()).toList();
      head = Money.k((v.last / 500).round() * 500);
      sub = _tab == 1 ? 'Monthly rent, last 8 quarters' : 'Monthly expenses, last 8 quarters';
    }

    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Performance', style: AppType.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          SoftSegments(labels: const ['Value', 'Rent', 'Costs'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        ]),
        const SizedBox(height: 16),
        Text(head, style: AppType.num(24, FontWeight.w800, -.5)),
        const SizedBox(height: 2),
        Text(sub, style: AppType.caption),
        const SizedBox(height: 16),
        QuarterBars(values: values, labels: labels),
      ]),
    );
  }
}
