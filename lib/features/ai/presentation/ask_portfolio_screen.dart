import 'dart:math' as math;

import 'package:flutter/material.dart' show TextField, InputDecoration, InputBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/pressable.dart';
import '../../finance/presentation/finance_providers.dart';
import 'ask_controller.dart';

class AskPortfolioScreen extends ConsumerStatefulWidget {
  const AskPortfolioScreen({super.key});

  @override
  ConsumerState<AskPortfolioScreen> createState() => _AskPortfolioScreenState();
}

class _AskPortfolioScreenState extends ConsumerState<AskPortfolioScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? q]) {
    ref.read(askControllerProvider.notifier).ask(q ?? _input.text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(askControllerProvider);
    ref.listen(askControllerProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
        }
      });
    });
    final suggestions = ref.read(aiRepositoryProvider).suggestions;
    final cards = ref.watch(financeInsightsProvider).take(3).toList();
    final media = MediaQuery.of(context);

    return ColoredBox(
      color: AppColors.background,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, media.padding.top + 8, 16, 8),
          child: Row(children: [
            CircleIconButton(icon: HomelyIcons.back, onTap: () => context.pop(), semanticLabel: 'Back'),
            const SizedBox(width: 12),
            Text('Intelligence', style: AppType.cardTitle),
          ]),
        ),
        Expanded(
          child: ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _Orb(),
                const SizedBox(height: 10),
                Text('Ask your portfolio', style: AppType.title28),
                const SizedBox(height: 10),
                Text('Answers come from the data you’ve recorded in LandOwner. Not financial advice.', style: AppType.body),
              ]),
            ),
            const SizedBox(height: 12),
            if (s.messages.isEmpty)
              for (final c in cards)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 62),
                      child: Text(c.stat, style: AppType.num(20).copyWith(color: AppColors.primary)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(c.text, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink))),
                  ]),
                ),
            for (final m in s.messages) Entrance.fadeUp(key: ObjectKey(m), child: _Bubble(m: m)),
            if (s.thinking) const Padding(padding: EdgeInsets.only(top: 12), child: _Typing()),
          ]),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Pressable(
              onTap: () => _send(suggestions[i]),
              scale: .96,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(suggestions[i],
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(media.viewInsets.bottom, media.padding.bottom) + 12),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(26), boxShadow: AppShadows.cardStrong),
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(fontSize: 15, color: AppColors.ink),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Ask about rent, costs, leases…',
                    hintStyle: TextStyle(fontSize: 15, color: AppColors.textFaint),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Pressable(
              onTap: _send,
              scale: .94,
              semanticLabel: 'Send',
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: const Center(child: HomelyIcon(HomelyIcons.send, size: 20, color: AppColors.white)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb();

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
        child: Stack(children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.blue200, borderRadius: BorderRadius.circular(22)),
            ),
          ),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m});
  final ChatMessage m;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .85,
            alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Align(
              alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: m.mine ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(m.mine ? 20 : 6),
                    bottomRight: Radius.circular(m.mine ? 6 : 20),
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.text, style: TextStyle(fontSize: 15, height: 1.45, color: m.mine ? AppColors.white : AppColors.ink)),
                  if (!m.mine && m.grounded) ...[
                    const SizedBox(height: 6),
                    Text('Based on your recorded data',
                        style: TextStyle(fontSize: 11, color: AppColors.ink.withValues(alpha: .6))),
                  ],
                ]),
              ),
            ),
          ),
        ),
      );
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: const Text('Reading your data…', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ),
      );
}
