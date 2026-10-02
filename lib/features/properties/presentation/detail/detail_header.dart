import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/net_image.dart';
import '../../../../core/widgets/pills.dart';
import '../../domain/property_metrics.dart';

/// 420px swipeable photo header with glass controls and the title block.
class DetailHeader extends StatefulWidget {
  const DetailHeader({super.key, required this.m, required this.onBack, this.onEdit});
  final PropertyMetrics m;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  @override
  State<DetailHeader> createState() => _DetailHeaderState();
}

class _DetailHeaderState extends State<DetailHeader> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.m.property;
    final photos = p.photoUrls;
    final top = MediaQuery.paddingOf(context).top + 8;
    final status = widget.m.statusIsAttention ? AppColors.attentionText : AppColors.positiveText;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.44).clamp(320.0, 430.0);

    return SizedBox(
      height: headerHeight,
      child: Stack(fit: StackFit.expand, children: [
        if (photos.isEmpty)
          const ColoredBox(color: AppColors.imagePlaceholder)
        else
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => NetImage(photos[i]),
          ),
        const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.detailHeader))),
        Positioned(
          top: top,
          left: 16,
          right: 16,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleIconButton(icon: HomelyIcons.back, glass: true, onTap: widget.onBack, semanticLabel: 'Back'),
            const Spacer(),
            if (photos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: GlassLabel(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${_page + 1} / ${photos.length} photos',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            if (widget.onEdit != null) ...[
              const SizedBox(width: 8),
              CircleIconButton(
                icon: HomelyIcons.sliders,
                glass: true,
                iconSize: 18,
                strokeWidth: 1.9,
                onTap: widget.onEdit,
                semanticLabel: 'Edit property',
              ),
            ],
          ]),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 48,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PhotoStatusPill(label: '${widget.m.statusLabel} · ${p.type.label}', color: status, strong: true),
                const SizedBox(height: 6),
                Text(
                  p.name,
                  style: AppType.detailTitle.copyWith(color: AppColors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  p.address,
                  style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: .85)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
