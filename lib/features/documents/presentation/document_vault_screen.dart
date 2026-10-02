import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/sheets.dart';
import '../../../core/widgets/states.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/widgets/status_row.dart';
import '../../../shared/widgets/sub_page.dart';
import '../domain/document_item.dart';
import '../domain/document_status.dart';

/// Document vault — More → Documents and Property → Documents.
class DocumentVaultScreen extends ConsumerStatefulWidget {
  const DocumentVaultScreen({super.key, this.propertyId});
  final String? propertyId;

  @override
  ConsumerState<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  static const _sorts = ['Expiry date', 'Document date', 'Name', 'Property'];
  String _tab = 'All documents', _type = 'All types', _sort = 'Expiry date', _q = '';

  @override
  Widget build(BuildContext context) {
    final today = ref.read(clockProvider).today();
    final names = {for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
    final all = (ref.watch(documentsProvider).value ?? const <DocumentItem>[])
        .where((d) => widget.propertyId == null || d.propertyId == widget.propertyId)
        .toList();
    final soon = all.where((d) => {ExpiryState.soon, ExpiryState.tomorrow, ExpiryState.today}.contains(d.stateOn(today)));
    final expired = all.where((d) => d.stateOn(today) == ExpiryState.expired);
    final list = (switch (_tab) { 'Expiring soon' => soon, 'Expired' => expired, _ => all }).where((d) {
      final t = _type == 'All types' || d.type.label == _type;
      return t && (_q.isEmpty || '${d.name} ${d.type.label} ${names[d.propertyId]}'.toLowerCase().contains(_q));
    }).toList()
      ..sort((a, b) => switch (_sort) {
            'Document date' => b.date.compareTo(a.date),
            'Name' => a.name.compareTo(b.name),
            'Property' => (names[a.propertyId] ?? '').compareTo(names[b.propertyId] ?? ''),
            _ => (a.expiry ?? DateTime(2999)).compareTo(b.expiry ?? DateTime(2999)),
          });

    return SubPage(
      title: 'Documents',
      subtitle: widget.propertyId == null
          ? '${all.length} in your vault · ${soon.length} expiring'
          : '${names[widget.propertyId]} · ${all.length} files',
      action: AddButton(onTap: () => context.push(Routes.add('document', propertyId: widget.propertyId))),
      slivers: [
        SliverToBoxAdapter(child: HomelySearchField(placeholder: 'Search documents', onChanged: (q) => setState(() => _q = q))),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: ChipRow(
              labels: ['All documents', 'Expiring soon', 'Expired'],
              selected: _tab,
              onSelect: (t) => setState(() => _tab = t),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              SortButton(
                label: _type,
                onTap: () async {
                  final r = await showChoiceSheet(context,
                      title: 'Document type', options: ['All types', for (final t in DocumentType.values) t.label], selected: _type);
                  if (r != null) setState(() => _type = r);
                },
              ),
              const Spacer(),
              SortButton(
                label: 'Sort · $_sort',
                onTap: () async {
                  final r = await showChoiceSheet(context, title: 'Sort documents', options: _sorts, selected: _sort);
                  if (r != null) setState(() => _sort = r);
                },
              ),
            ]),
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: EmptyStateCard(
              title: _tab == 'All documents' ? 'Nothing here yet' : 'All clear',
              message: _tab == 'All documents' ? 'Leases, deeds, policies and receipts you add appear here.' : 'No documents in this view.',
              icon: HomelyIcons.file,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = list[i];
                return StatusRow(
                  icon: HomelyIcons.file,
                  tone: d.toneOn(today) == Tone.neutral ? Tone.info : d.toneOn(today),
                  title: d.name,
                  subtitle: '${d.type.label} · ${names[d.propertyId] ?? ''}',
                  meta: 'Dated ${Dates.dMy(d.date)}${d.expiry == null ? '' : ' · expiry ${Dates.dMy(d.expiry!)}'}',
                  status: d.statusLabel(today),
                  statusTone: d.toneOn(today),
                  onTap: () => context.push(Routes.document(d.id)),
                );
              },
            ),
          ),
      ],
    );
  }
}
