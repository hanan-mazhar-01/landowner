import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/services/share_service.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/sheets.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/toast.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/usecases.dart';
import '../../../shared/widgets/sub_page.dart';
import '../domain/document_item.dart';
import '../domain/document_status.dart';

class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = (ref.watch(documentsProvider).value ?? const <DocumentItem>[]).where((x) => x.id == id).firstOrNull;
    if (d == null) {
      return const SubPage(title: 'Document', slivers: [
        SliverToBoxAdapter(child: EmptyStateCard(title: 'Not found', message: 'This document was deleted.')),
      ]);
    }
    final today = ref.read(clockProvider).today();
    final p = ref.watch(propertyByIdProvider(d.propertyId));
    final reminder = (ref.watch(remindersProvider).value ?? const []).where((r) => r.sourceKey == 'doc:${d.id}').firstOrNull;
    final toast = ref.read(toastProvider.notifier);
    final summary = '${d.name} · ${d.type.label} · ${p?.name ?? ''}\nDated ${Dates.dMy(d.date)}'
        '${d.expiry == null ? '' : '\nExpires ${Dates.dMy(d.expiry!)}'}';

    Future<void> share() async {
      final f = d.fileUrl;
      f != null && !f.startsWith('http') ? await ShareService.file(f, subject: d.name) : await ShareService.text(summary, subject: d.name);
    }

    Future<void> replace() async {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
      if (x == null) return;
      await ref.read(recordEditsProvider).saveDocument(d.copyWith(fileUrl: x.path));
      toast.show('File replaced');
    }

    Widget tile(HomelyIcons icon, String label, VoidCallback onTap, {bool danger = false}) => Expanded(
          child: SurfaceCard(
            onTap: onTap,
            color: danger ? AppColors.overdueTint : AppColors.blue50,
            radius: 18,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 64,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                HomelyIcon(icon, size: 20, color: danger ? AppColors.overdueText : AppColors.primary, strokeWidth: 1.9),
                const SizedBox(height: 5),
                Text(label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: danger ? AppColors.overdueText : AppColors.primary)),
              ]),
            ),
          ),
        );
    Widget kv(String k, String v, {bool first = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: first ? null : const BoxDecoration(border: Border(top: BorderSide(color: AppColors.dividerSoft))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(width: 12),
            Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink))),
          ]),
        );

    return SubPage(
      title: d.name,
      subtitle: '${d.type.label} · ${p?.name ?? ''}',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList.list(children: [
            // Preview — the image itself, or the design's PDF glyph.
            Container(
              height: 220,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
              child: d.isImage
                  ? NetImage(d.fileUrl)
                  : Center(
                      child: Container(
                        width: 72,
                        height: 88,
                        padding: const EdgeInsets.only(left: 10, bottom: 10),
                        alignment: Alignment.bottomLeft,
                        decoration: BoxDecoration(
                          color: AppColors.blue50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(d.fileKindLabel, style: AppType.num(14).copyWith(color: AppColors.primary)),
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                TonePill.tone(d.statusLabel(today), d.toneOn(today), dot: true),
                const Spacer(),
                if (reminder != null) LinkText('Reminder set →', onTap: () => context.push(Routes.reminder(reminder.id))),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              tile(HomelyIcons.arrowUpRight, 'Open', () {
                d.isImage ? context.push('/documents/${d.id}/view') : share();
              }),
              const SizedBox(width: 8),
              tile(HomelyIcons.message, 'Share', share),
              const SizedBox(width: 8),
              tile(HomelyIcons.upload, 'Download', share),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              tile(HomelyIcons.file, 'Replace', replace),
              const SizedBox(width: 8),
              tile(HomelyIcons.sliders, 'Edit', () => context.push(Routes.add('document', editId: d.id))),
              const SizedBox(width: 8),
              tile(HomelyIcons.close, 'Delete', () async {
                final ok = await showConfirmSheet(context,
                    title: 'Delete this document?', message: 'Its expiry reminder is removed too.', confirmLabel: 'Delete document');
                if (!ok) return;
                await ref.read(recordEditsProvider).deleteDocument(d.id);
                toast.show('Document deleted');
                if (context.mounted) context.pop();
              }, danger: true),
            ]),
            const SizedBox(height: 14),
            SurfaceCard(
              radius: AppRadius.list,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(children: [
                kv('Type', d.type.label, first: true),
                kv('Property', p?.name ?? ''),
                kv('Document date', Dates.dMy(d.date)),
                kv('Expiry date', d.expiry == null ? 'None' : Dates.dMy(d.expiry!)),
                kv('Notes', d.notes.isEmpty ? '—' : d.notes),
              ]),
            ),
            if (d.expiry != null) ...[
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  HomelyIcon(HomelyIcons.bell, size: 14, color: AppColors.accent),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('You’ll be reminded 30 days before it expires.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ],
    );
  }
}

/// Full-screen image viewer for "Open".
class DocumentViewerScreen extends ConsumerWidget {
  const DocumentViewerScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = (ref.watch(documentsProvider).value ?? const <DocumentItem>[]).where((x) => x.id == id).firstOrNull;
    return ColoredBox(
      color: AppColors.inkDeep,
      child: Stack(children: [
        Positioned.fill(child: InteractiveViewer(child: NetImage(d?.fileUrl, fit: BoxFit.contain))),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 16,
          child: CircleIconButton(icon: HomelyIcons.close, glass: true, iconSize: 18, onTap: () => context.pop()),
        ),
      ]),
    );
  }
}
