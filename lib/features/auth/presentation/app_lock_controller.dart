import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/biometric_service.dart';
import 'auth_providers.dart';
import 'preferences_provider.dart';

class AppLockController extends Notifier<bool> {
  @override
  bool build() {
    // If user has biometric enabled and is currently signed in, start locked.
    final biometric = ref.watch(preferencesProvider).biometric;
    final signedIn = ref.watch(currentUserProvider) != null;
    return biometric && signedIn;
  }

  void lock() {
    final biometric = ref.read(preferencesProvider).biometric;
    final signedIn = ref.read(currentUserProvider) != null;
    if (biometric && signedIn) {
      state = true;
    }
  }

  Future<bool> promptUnlock() async {
    if (!state) return true;
    final canAuth = await BiometricService.available();
    if (!canAuth) {
      // Biometric hardware unavailable on this device, unlock.
      state = false;
      return true;
    }

    final success = await BiometricService.confirm('Unlock LandOwner to view your portfolio');
    if (success) {
      state = false;
      return true;
    }
    return false;
  }

  void forceUnlock() {
    state = false;
  }
}

final appLockProvider = NotifierProvider<AppLockController, bool>(AppLockController.new);
