import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/widgets/pressable.dart';
import 'property_detail_vm.dart';

/// Horizontal document tiles (132px) with a file-type glyph.
class DocumentsStrip extends StatelessWidget {
  const DocumentsStrip({super.key, required this.docs, this.onAdd, this.onViewAll, this.onOpen});
  final List<DocChip> docs;
  final VoidCallback? onAdd;
  final VoidCallback? onViewAll;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Row(children: [
            Text('Documents', style: AppType.cardTitle),
            const Spacer(),
            if (onViewAll != null)
              Pressable(
                onTap: onViewAll,
                child: const Text('View all',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
          ]),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: docs.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => i == docs.length
                ? _add()
                : Pressable(
                    onTap: docs[i].id == null || onOpen == null ? null : () => onOpen!(docs[i].id!),
                    child: _tile(docs[i]),
                  ),
          ),
        ),
      ]);

  Widget _tile(DocChip d) => Container(
        width: 132,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 44,
            padding: const EdgeInsets.only(left: 6, bottom: 6),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDE3F3)),
            ),
            child: Text(d.kind, style: AppType.num(8).copyWith(color: AppColors.primary)),
          ),
          const Spacer(),
          Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(d.meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: d.color)),
        ]),
      );

  Widget _add() => Pressable(
        onTap: onAdd,
        child: Container(
          width: 96,
          decoration: BoxDecoration(
            color: AppColors.blue25,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.blue300, width: 1.5),
          ),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            HomelyIcon(HomelyIcons.upload, size: 20, color: AppColors.primary, strokeWidth: 1.9),
            SizedBox(height: 8),
            Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ]),
        ),
      );
}

/// "PORTFOLIO INSIGHT" insight card linking to Ask your portfolio.
class IntelligenceCard extends StatelessWidget {
  const IntelligenceCard({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: .99,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.blue100, borderRadius: BorderRadius.circular(26)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              HomelyIcon(HomelyIcons.sparkle, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('PORTFOLIO INSIGHT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: .3)),
            ]),
            const SizedBox(height: 10),
            Text(text, style: AppType.num(18, FontWeight.w700, -.3).copyWith(height: 1.35)),
            const SizedBox(height: 10),
            const Text('From your recorded data · Ask a follow-up →',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      );
}
