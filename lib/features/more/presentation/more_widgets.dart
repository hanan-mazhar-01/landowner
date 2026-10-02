import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/toast.dart';

const supportEmail = 'support@veradostudio.com';

/// Opens a drafted support email; falls back to a toast with the address.
Future<void> openSupportEmail(WidgetRef ref) async {
  var opened = false;
  try {
    opened = await launchUrl(Uri.parse('mailto:$supportEmail?subject=LandOwner%20support'),
        mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) ref.read(toastProvider.notifier).show('Email us at $supportEmail');
}

/// Operations grid tile — icon, flag, big count, label, sub.
class OpsTile extends StatelessWidget {
  const OpsTile({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    required this.sub,
    this.flag = '',
    this.flagColor = AppColors.textMuted,
    this.onTap,
  });

  final HomelyIcons icon;
  final String count, label, sub, flag;
  final Color flagColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        onTap: onTap,
        pressScale: .98,
        radius: AppRadius.list,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconTile(
              size: 36,
              radius: 12,
              color: AppColors.blue50,
              child: HomelyIcon(icon, size: 18, color: AppColors.primary, strokeWidth: 1.9),
            ),
            const Spacer(),
            Text(flag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: flagColor)),
          ]),
          const SizedBox(height: 14),
          Text(count, style: AppType.num(28, FontWeight.w800, -.8)),
          const SizedBox(height: 1),
          Text(label, style: AppType.label14),
          Text(sub, style: AppType.caption),
        ]),
      );
}

class MenuItem {
  const MenuItem(this.icon, this.label, {this.value = '', this.onTap});
  final HomelyIcons icon;
  final String label, value;
  final VoidCallback? onTap;
}

/// White grouped menu card with hairline separators and chevrons.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.items});
  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        radius: AppRadius.list,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          for (var i = 0; i < items.length; i++)
            Pressable(
              onTap: items[i].onTap,
              scale: .99,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                  border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.dividerSoft)),
                ),
                child: Row(children: [
                  HomelyIcon(items[i].icon, size: 19, color: AppColors.primary, strokeWidth: 1.9),
                  const SizedBox(width: 14),
                  Expanded(child: Text(items[i].label, style: AppType.menuItem)),
                  Text(items[i].value, style: const TextStyle(fontSize: 13, color: AppColors.textFaint)),
                  const SizedBox(width: 8),
                  const HomelyIcon(HomelyIcons.chevronRight, size: 16, color: AppColors.chevron),
                ]),
              ),
            ),
        ]),
      );
}

/// Blue gradient "Portfolio Intelligence" entry with layered orb icon.
class IntelligenceEntry extends StatelessWidget {
  const IntelligenceEntry({super.key, required this.subtitle, required this.onTap});
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GradientCard(
          onTap: onTap,
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.white.withValues(alpha: .14), shape: BoxShape.circle),
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(18)),
                ),
                const HomelyIcon(HomelyIcons.sparkle, size: 22, color: AppColors.white),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Portfolio Intelligence', style: AppType.cardTitle.copyWith(color: AppColors.white)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: .8))),
              ]),
            ),
            HomelyIcon(HomelyIcons.chevronRight, size: 18, color: AppColors.white.withValues(alpha: .7)),
          ]),
        ),
      );
}
