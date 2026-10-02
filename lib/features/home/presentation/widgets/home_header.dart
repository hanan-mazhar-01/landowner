import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/text_blocks.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../shared/providers/collections.dart';
import '../../../auth/presentation/auth_providers.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.read(clockProvider).now();
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(notificationsProvider.select((a) => (a.value ?? const []).any((n) => n.unread)));

    return Padding(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 12, 24, 0),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Dates.longDay(now), style: AppType.meta),
            const SizedBox(height: 2),
            Text('Hi, ${user?.firstName ?? 'there'}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.greeting),
          ]),
        ),
        const SizedBox(width: 12),
        CircleIconButton(
          icon: HomelyIcons.bell,
          iconSize: 20,
          strokeWidth: 1.8,
          badge: unread,
          shadow: AppShadows.cardStrong,
          semanticLabel: 'Notifications',
          onTap: () => context.push(Routes.notifications),
        ),
        const SizedBox(width: 8),
        Pressable(
          onTap: () => context.go(Routes.more),
          scale: .94,
          semanticLabel: 'Profile',
          child: ExcludeSemantics(child: UserAvatar(name: user?.name ?? '', url: user?.avatarUrl, size: 44)),
        ),
      ]),
    );
  }
}

/// "Total portfolio value" hero with growth pill.
class ValueHero extends StatelessWidget {
  const ValueHero({super.key, required this.value, required this.growthPct, required this.growthAbs});
  final int value;
  final double growthPct;
  final int growthAbs;

  @override
  Widget build(BuildContext context) {
    final up = growthPct >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total portfolio value', style: AppType.label13.copyWith(letterSpacing: .2)),
        const SizedBox(height: 8),
        MoneyHero(value: value / 1e6, unit: 'M', symbol: Money.symbol),
        const SizedBox(height: 8),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: up ? AppColors.positiveTint : AppColors.overdueTint,
                borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              HomelyIcon(HomelyIcons.arrowUpRight,
                  size: 13, strokeWidth: 2.4, color: up ? AppColors.positiveText : AppColors.overdueText,
                  rotation: up ? 0 : 1.5708),
              const SizedBox(width: 4),
              Text('${growthPct.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: up ? AppColors.positiveText : AppColors.overdueText)),
            ]),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text('${up ? '+' : '−'}${Money.m(growthAbs.abs())} over 12 months',
                style: AppType.meta, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ]),
    );
  }
}
