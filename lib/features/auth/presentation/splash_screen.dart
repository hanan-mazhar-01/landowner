import 'package:flutter/widgets.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/entrance.dart';
import 'welcome_screen.dart';

/// Shown while the session restores (the native launch screen covers cold start).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.background,
        child: Center(child: Entrance(child: BrandMark(size: 48))),
      );
}
