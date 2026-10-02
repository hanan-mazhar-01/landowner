import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/net_image.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/property_metrics.dart';

String yieldLabel(PropertyMetrics m) => m.yieldPct == 0 ? '—' : '${m.yieldPct.toStringAsFixed(1)}%';

/// Compact portfolio row — 84px thumbnail, status, net and yield.
class PropertyRow extends StatelessWidget {
  const PropertyRow({super.key, required this.m, required this.onTap});
  final PropertyMetrics m;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = m.property;
    final status = m.statusIsAttention ? AppColors.attentionText : AppColors.positiveText;
    return Pressable(
      onTap: onTap,
      scale: .985,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.list),
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox.square(dimension: 84, child: NetImage(p.coverUrl)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.num(16, FontWeight.w700, -.2)),
              const SizedBox(height: 3),
              Text(p.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption),
              const SizedBox(height: 7),
              Row(children: [
                Dot(status),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('${m.statusLabel} · ${Money.m(p.currentValue)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: status)),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(Money.k(m.net), style: AppType.num(16)),
            ),
            const SizedBox(height: 3),
            const Text('net / mo', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 3),
            Text(yieldLabel(m),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.positiveText)),
          ]),
        ]),
      ),
    );
  }
}
