import 'dart:async';

import 'package:flutter/material.dart' show TextField, InputDecoration, InputBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/controls.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_blocks.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/portfolio.dart';
import '../../shell/presentation/quick_actions_controller.dart';
import 'widgets/carousel/property_stack_carousel.dart';
import 'widgets/property_cards.dart';

/// Property portfolio — search, type filters, list (All) or swipeable deck (a category).
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  static const _filters = ['All', 'House', 'Apartment', 'Commercial', 'Land'];
  String _filter = 'All';
  String _query = '';
  int _deckIndex = 0;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => setState(() {
          _query = q.trim().toLowerCase();
          _deckIndex = 0;
        }));
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(portfolioReadyProvider)) return const DashboardSkeleton();
    final summary = ref.watch(portfolioSummaryProvider);
    final list = summary.metrics.where((m) {
      final p = m.property;
      final typeOk = _filter == 'All' || p.type.label == _filter;
      final qOk = _query.isEmpty || '${p.name} ${p.location}'.toLowerCase().contains(_query);
      return typeOk && qOk;
    }).toList()
      ..sort((a, b) => b.yieldPct.compareTo(a.yieldPct));
    // "All": a plain list. A category: the swipeable deck.
    final deck = _filter != 'All';
    void open(String id) => context.push(Routes.property(id));

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 12, 24, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: PageTitle('Portfolio',
                  subtitle: '${summary.count} ${summary.count == 1 ? 'property' : 'properties'} · ${Money.m(summary.totalValue)} total value'),
            ),
            CircleIconButton(
              icon: HomelyIcons.plus,
              color: AppColors.blue100,
              iconColor: AppColors.primary,
              semanticLabel: 'Add property',
              onTap: ref.read(quickActionsProvider.notifier).open,
            ),
          ]),
        ),
      ),
      SliverToBoxAdapter(child: _SearchField(onChanged: _onQuery)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: ChipRow(
            labels: _filters,
            selected: _filter,
            activeBg: AppColors.accent,
            height: 36,
            fontSize: 14,
            onSelect: (f) => setState(() {
              _filter = f;
              _deckIndex = 0;
            }),
          ),
        ),
      ),
      if (deck && list.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: PropertyStackCarousel(
              // A new filter / search starts the deck from its first card.
              key: ValueKey('$_filter|$_query'),
              properties: list,
              onPropertyTap: (m) => open(m.property.id),
              onPageChanged: (i) => setState(() => _deckIndex = i),
            ),
          ),
        ),
      if (deck && list.length > 1)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(child: DeckIndicator(count: list.length, index: _deckIndex.clamp(0, list.length - 1))),
          ),
        ),
      if (!deck && list.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
            child: Text('All properties', style: AppType.section18),
          ),
        ),
      if (!deck && list.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => PropertyRow(m: list[i], onTap: () => open(list[i].property.id)),
          ),
        ),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: EmptyStateCard(
            title: 'Nothing here yet',
            message: 'No properties match this view. Add one and it will appear with its value and income.',
            actionLabel: 'Add a property',
            onAction: ref.read(quickActionsProvider.notifier).open,
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.navClearance)),
    ]);
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.search),
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          const HomelyIcon(HomelyIcons.search, size: 18, color: AppColors.textFaint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search by name or area',
                hintStyle: TextStyle(fontSize: 15, color: AppColors.textFaint),
              ),
            ),
          ),
        ]),
      );
}
