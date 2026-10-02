import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/seed/seed_ops.dart';
import '../data/firebase_auth_repository.dart';
import '../data/local_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) {
  if (Firebase.apps.isNotEmpty) {
    return FirebaseAuthRepository();
  }
  return LocalAuthRepository(seedUser);
});

final authStateProvider = StreamProvider<AppUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// Signed-in user (null while signed out).
final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authStateProvider).value);

/// Bridges auth changes to GoRouter's `refreshListenable`.
class AuthRefresh extends ChangeNotifier {
  AuthRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

final authRefreshProvider = Provider<AuthRefresh>((ref) => AuthRefresh(ref));

/// Onboarding seen flag (in-memory; persisted with the profile later).
class OnboardingSeen extends Notifier<bool> {
  @override
  bool build() => false;
  void markSeen() => state = true;
}

final onboardingSeenProvider = NotifierProvider<OnboardingSeen, bool>(OnboardingSeen.new);
