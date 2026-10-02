import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/pressable.dart';
import '../app_lock_controller.dart';
import '../auth_providers.dart';
import '../welcome_screen.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        ref.read(appLockProvider.notifier).lock();
      },
      onHide: () {
        ref.read(appLockProvider.notifier).lock();
      },
      onResume: () {
        final isLocked = ref.read(appLockProvider);
        if (isLocked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(appLockProvider.notifier).promptUnlock();
          });
        }
      },
    );

    // Initial prompt if app starts locked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appLockProvider)) {
        ref.read(appLockProvider.notifier).promptUnlock();
      }
    });
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider);

    return Stack(children: [
      widget.child,
      if (isLocked)
        Positioned.fill(
          child: ColoredBox(
            color: AppColors.background,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(children: [
                  const Spacer(flex: 2),
                  const BrandMark(size: 64),
                  const SizedBox(height: 28),
                  Text('LandOwner is Locked', style: AppType.title28, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    'Your portfolio is protected with biometric security.',
                    style: AppType.body15,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 2),
                  Pressable(
                    onTap: () => ref.read(appLockProvider.notifier).promptUnlock(),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppGradients.cta,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.cta,
                      ),
                      child: const Center(
                        child: HomelyIcon(HomelyIcons.lock, size: 36, color: AppColors.white, strokeWidth: 2.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Tap to unlock', style: AppType.meta),
                  const Spacer(flex: 3),
                  LinkText(
                    'Sign out',
                    color: AppColors.overdueText,
                    onTap: () async {
                      ref.read(appLockProvider.notifier).forceUnlock();
                      await ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }
}
