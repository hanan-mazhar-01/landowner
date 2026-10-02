import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_decor.dart';
import '../../app/theme/app_motion.dart';

class ToastState {
  const ToastState(this.message, this.visible, this.serial);
  final String message;
  final bool visible;
  final int serial;
}

/// App-wide ink toast (shown for 1.9s at the top, as in the design).
class ToastController extends Notifier<ToastState> {
  Timer? _timer;

  @override
  ToastState build() {
    ref.onDispose(() => _timer?.cancel());
    return const ToastState('', false, 0);
  }

  void show(String message) {
    _timer?.cancel();
    state = ToastState(message, true, state.serial + 1);
    _timer = Timer(AppMotion.toastHold, () => state = ToastState(state.message, false, state.serial));
  }
}

final toastProvider = NotifierProvider<ToastController, ToastState>(ToastController.new);

/// Overlay host placed above the navigator.
class ToastHost extends ConsumerWidget {
  const ToastHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(toastProvider);
    final top = MediaQuery.paddingOf(context).top + 12;
    return Positioned(
      left: 24,
      right: 24,
      top: top,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: t.visible ? 1 : 0,
          duration: Motion.of(context, const Duration(milliseconds: 220)),
          child: AnimatedSlide(
            offset: t.visible ? Offset.zero : const Offset(0, -.25),
            duration: Motion.of(context, const Duration(milliseconds: 260)),
            curve: AppMotion.standard,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadius.search),
                  boxShadow: AppShadows.toast,
                ),
                child: Text(
                  t.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
