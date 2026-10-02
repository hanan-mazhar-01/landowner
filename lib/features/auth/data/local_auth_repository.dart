import 'dart:async';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Demo auth used until Firebase Auth is connected. Validates input the same
/// way the Firebase implementation will, but keeps the session in memory.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._demoUser) : _user = _demoUser;

  final AppUser _demoUser;
  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void _validate(String email, String password) {
    if (!_email.hasMatch(email.trim())) throw const AuthFailure('Enter a valid email address.');
    if (password.length < 6) throw const AuthFailure('Password must be at least 6 characters.');
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    _validate(email, password);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _set(_demoUser);
    return _demoUser;
  }

  @override
  Future<AppUser> signUp({required String name, required String email, required String password}) async {
    if (name.trim().isEmpty) throw const AuthFailure('Tell us your name.');
    _validate(email, password);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final u = AppUser(
      uid: _demoUser.uid,
      name: name.trim(),
      email: email.trim(),
      city: _demoUser.city,
      avatarUrl: _demoUser.avatarUrl,
    );
    _set(u);
    return u;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (!_email.hasMatch(email.trim())) throw const AuthFailure('Enter a valid email address.');
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String email,
    String phone = '',
    String? avatarUrl,
    String? city,
    String? currencySymbol,
    String? currencyCode,
  }) async {
    if (name.trim().isEmpty) throw const AuthFailure('Tell us your name.');
    if (!_email.hasMatch(email.trim())) throw const AuthFailure('Enter a valid email address.');
    final u = (_user ?? _demoUser).copyWith(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      avatarUrl: avatarUrl,
      city: city,
      currencySymbol: currencySymbol,
      currencyCode: currencyCode,
    );
    _set(u);
    return u;
  }

  @override
  Future<void> changePassword({required String current, required String next}) async {
    if (current.isEmpty) throw const AuthFailure('Enter your current password.');
    if (next.length < 6) throw const AuthFailure('New password must be at least 6 characters.');
    if (next == current) throw const AuthFailure('Choose a password you haven\u2019t used here.');
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _set(_demoUser);
    return _demoUser;
  }

  @override
  Future<AppUser> signInWithApple() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _set(_demoUser);
    return _demoUser;
  }

  @override
  String? get signInMethod => _user == null ? null : 'password';

  @override
  Future<void> deleteAccount() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _set(null);
  }

  void _set(AppUser? u) {
    _user = u;
    _changes.add(u);
  }
}
