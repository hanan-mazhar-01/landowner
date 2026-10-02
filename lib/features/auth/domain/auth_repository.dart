import '../../../core/errors/app_failure.dart';
import 'app_user.dart';

class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

/// Authentication contract. `FirebaseAuthRepository` implements this once
/// Firebase is configured (it persists sessions natively).
abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({required String name, required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<AppUser> updateProfile({
    required String name,
    required String email,
    String phone = '',
    String? avatarUrl,
    String? city,
    String? currencySymbol,
    String? currencyCode,
  });
  Future<void> changePassword({required String current, required String next});

  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();

  /// How the current user signs in: 'password', 'google.com', 'apple.com'.
  String? get signInMethod;

  /// Permanently removes the account, all portfolio data and uploaded media.
  Future<void> deleteAccount();
}
