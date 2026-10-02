import 'package:flutter/widgets.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/icons/homely_icon.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/net_image.dart';
import '../../../../../core/widgets/pills.dart';
import '../../../domain/property_metrics.dart';
import '../property_cards.dart';

/// One portfolio asset in the deck: the photo is the hero (it takes all the
/// height the info block doesn't need — ~60% on standard phones), with name,
/// place, type and the key figures underneath. Only existing
/// Property / PropertyMetrics fields are shown.
class PropertyCarouselCard extends StatelessWidget {
  const PropertyCarouselCard({super.key, required this.m});
  final PropertyMetrics m;

  static const radius = 30.0;

  @override
  Widget build(BuildContext context) {
    final p = m.property;
    final statusColor = m.statusIsAttention ? AppColors.attentionText : AppColors.positiveText;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (p.coverUrl == null)
                    const ColoredBox(
                      color: AppColors.imagePlaceholder,
                      child: Center(
                        child: HomelyIcon(
                          HomelyIcons.emptyBuilding,
                          size: 40,
                          color: AppColors.textFaint,
                          strokeWidth: 1.6,
                        ),
                      ),
                    )
                  else
                    NetImage(p.coverUrl),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: PhotoStatusPill(label: m.statusLabel, color: statusColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.title22),
                  const SizedBox(height: 3),
                  Text(
                    '${p.location} · ${p.type.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.meta,
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  // Scales down rather than overflowing on narrow cards / large text.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _fig('Value', Money.m(p.currentValue), AppColors.ink, big: true),
                        const SizedBox(width: 22),
                        _fig('Rent / mo', m.monthlyRent == 0 ? '—' : Money.k(m.monthlyRent), AppColors.ink),
                        const SizedBox(width: 22),
                        _fig('Yield', yieldLabel(m), AppColors.positiveText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fig(String label, String value, Color color, {bool big = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: AppType.caption),
      const SizedBox(height: 2),
      Text(value, style: AppType.num(big ? 20 : 16, FontWeight.w800, big ? -.4 : 0).copyWith(color: color)),
    ],
  );

  /// Screen-reader summary of the card.
  static String semanticsFor(PropertyMetrics m) =>
      '${m.property.name}, ${m.property.location}, '
      '${m.property.type.label}, ${m.statusLabel}, value ${Money.m(m.property.currentValue)}'
      '${m.monthlyRent == 0 ? '' : ', rent ${Money.k(m.monthlyRent)} a month'}';
}
