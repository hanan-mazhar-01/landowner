import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_decor.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/net_image.dart';
import '../../core/widgets/surfaces.dart';

class _Rows extends StatelessWidget {
  const _Rows(this.rows);
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.dividerSoft))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.$1, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(r.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ),
            ]),
          ),
      ]);
}

/// Property review — 170px photo with name overlay, then key/value rows.
class PropertyReviewCard extends StatelessWidget {
  const PropertyReviewCard({super.key, required this.name, required this.location, required this.photo, required this.rows});
  final String name, location;
  final String? photo;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.review)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 170,
            child: Stack(fit: StackFit.expand, children: [
              NetImage(photo),
              const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.photoBottom)),
              Positioned(
                left: 18,
                right: 18,
                bottom: 14,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: AppType.num(22).copyWith(color: AppColors.white)),
                  const SizedBox(height: 2),
                  Text(location, style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: .85))),
                ]),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(18, 6, 18, 10), child: _Rows(rows)),
        ]),
      );
}

/// Lease review — gradient summary (rent, start, due, end) + rows.
class LeaseReviewCard extends StatelessWidget {
  const LeaseReviewCard({
    super.key,
    required this.header,
    required this.rent,
    required this.start,
    required this.due,
    required this.end,
    required this.rows,
  });

  final String header, rent, start, due, end;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final soft = TextStyle(fontSize: 11, color: AppColors.white.withValues(alpha: .7));
    Widget cell(String l, String v) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: soft),
            const SizedBox(height: 3),
            Text(v, style: AppType.num(14, FontWeight.w700).copyWith(color: AppColors.white)),
          ]),
        );
    return Column(children: [
      GradientCard(
        radius: AppRadius.review,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(header, style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: .75))),
          const SizedBox(height: 2),
          Text.rich(TextSpan(children: [
            TextSpan(text: rent, style: AppType.num(30, FontWeight.w800, -1).copyWith(color: AppColors.white)),
            TextSpan(text: ' / month', style: TextStyle(fontSize: 15, color: AppColors.white.withValues(alpha: .7))),
          ])),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.white.withValues(alpha: .18)))),
            child: Row(children: [cell('Lease starts', start), cell('Rent due', due), cell('Lease ends', end)]),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      SurfaceCard(
        radius: AppRadius.list,
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
        child: _Rows(rows),
      ),
    ]);
  }
}
