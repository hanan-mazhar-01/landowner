import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/services/account_deletion.dart';
import '../../../firebase_options.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Firebase Authentication and Cloud Firestore implementation of [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AppUser? _cachedUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().asyncMap((fbUser) async {
        debugPrint('>>> [FirebaseAuthRepository] authStateChanges fbUser: ${fbUser?.uid} (${fbUser?.email})');
        if (fbUser == null) {
          _cachedUser = null;
          return null;
        }

        try {
          final doc = await _userDoc(fbUser.uid).get();
          if (doc.exists && doc.data() != null) {
            _cachedUser = AppUser.fromMap(doc.data()!, fbUser.uid);
          } else {
            // First time: provision default user profile doc
            final newUser = AppUser(
              uid: fbUser.uid,
              name: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Landowner',
              email: fbUser.email ?? '',
              avatarUrl: fbUser.photoURL,
              city: '',
              phone: fbUser.phoneNumber ?? '',
            );
            await _userDoc(fbUser.uid).set(newUser.toMap());
            _cachedUser = newUser;
          }
        } catch (_) {
          // If Firestore is offline or fails, fallback to Firebase Auth info
          _cachedUser = AppUser(
            uid: fbUser.uid,
            name: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Landowner',
            email: fbUser.email ?? '',
            avatarUrl: fbUser.photoURL,
          );
        }

        return _cachedUser;
      });

  String _mapAuthException(fb.FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' => 'Incorrect email or password.',
      'email-already-in-use' => 'An account already exists with this email address.',
      'weak-password' => 'Password is too weak. Please use at least 6 characters.',
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled. Please contact support.',
      'too-many-requests' => 'Too many failed attempts. Please try again later.',
      'network-request-failed' => 'Network error. Please check your internet connection.',
      _ => e.message ?? 'Authentication error occurred. Please try again.',
    };
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = credential.user!;
      final doc = await _userDoc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        _cachedUser = AppUser.fromMap(doc.data()!, fbUser.uid);
      } else {
        _cachedUser = AppUser(
          uid: fbUser.uid,
          name: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Landowner',
          email: fbUser.email ?? email.trim(),
          avatarUrl: fbUser.photoURL,
        );
        await _userDoc(fbUser.uid).set(_cachedUser!.toMap(), SetOptions(merge: true));
      }
      return _cachedUser!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthException(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      debugPrint('Auth error: $e');
      throw const AuthFailure('Something went wrong. Check your connection and try again.');
    }
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = credential.user!;
      await fbUser.updateDisplayName(name.trim());

      final newUser = AppUser(
        uid: fbUser.uid,
        name: name.trim(),
        email: email.trim(),
        city: '',
        phone: '',
      );
      await _userDoc(fbUser.uid).set(newUser.toMap());
      _cachedUser = newUser;
      return newUser;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthException(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      debugPrint('Auth error: $e');
      throw const AuthFailure('Something went wrong. Check your connection and try again.');
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthException(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      debugPrint('Auth error: $e');
      throw const AuthFailure('Something went wrong. Check your connection and try again.');
    }
  }

  static bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS ? DefaultFirebaseOptions.ios.iosClientId : null,
        serverClientId: '341447303427-929fo73ka8n621hvsok2u2aghp7jub7b.apps.googleusercontent.com',
      );
      _googleSignInInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn.initialize note: $e');
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      String? accessToken;
      try {
        final authz = await account.authorizationClient.authorizationForScopes(['email']);
        accessToken = authz?.accessToken;
      } catch (e) {
        debugPrint('GoogleSignIn authorizationForScopes note: $e');
      }

      if (idToken == null && accessToken == null) {
        debugPrint('GoogleSignIn returned no idToken/accessToken — check the SHA-1 fingerprint in Firebase Console.');
        throw const AuthFailure(_googleUnavailable);
      }

      final credential = fb.GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final fbUser = userCred.user!;

      final doc = await _userDoc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        _cachedUser = AppUser.fromMap(doc.data()!, fbUser.uid);
      } else {
        final newUser = AppUser(
          uid: fbUser.uid,
          name: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Landowner',
          email: fbUser.email ?? '',
          avatarUrl: fbUser.photoURL,
        );
        await _userDoc(fbUser.uid).set(newUser.toMap(), SetOptions(merge: true));
        _cachedUser = newUser;
      }
      return _cachedUser!;
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code}, ${e.description}, ${e.details}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('Google sign-in was canceled.');
      } else if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        debugPrint('GoogleSignIn client configuration error — is the SHA-1 key registered in Firebase Console?');
      }
      throw const AuthFailure(_googleUnavailable);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthException(e));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      throw const AuthFailure(_googleUnavailable);
    }
  }

  static const _googleUnavailable = 'Google sign-in isn’t available right now. Please try again or use email.';

  @override
  Future<AppUser> signInWithApple() async {
    try {
      debugPrint('>>> [AppleSignIn] Starting Apple Sign In flow...');
      final isAvailable = await SignInWithApple.isAvailable();
      debugPrint('>>> [AppleSignIn] SignInWithApple.isAvailable() = $isAvailable');

      final rawNonce = _generateNonce();
      final sha256Nonce = sha256.convert(utf8.encode(rawNonce)).toString();
      debugPrint('>>> [AppleSignIn] rawNonce: $rawNonce, sha256: $sha256Nonce');

      debugPrint('>>> [AppleSignIn] Requesting Apple ID credential...');
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Nonce,
      );

      final identityToken = appleCred.identityToken;
      debugPrint('>>> [AppleSignIn] Received credential for userIdentifier: ${appleCred.userIdentifier}, hasToken: ${identityToken != null}');
      if (identityToken == null) {
        throw const AuthFailure('Apple sign-in failed: no identity token was provided by Apple.');
      }

      try {
        final parts = identityToken.split('.');
        if (parts.length > 1) {
          final payloadStr = utf8.decode(base64Url.decode(base64.normalize(parts[1])));
          debugPrint('>>> [AppleSignIn] Token payload: $payloadStr');
        }
      } catch (err) {
        debugPrint('>>> [AppleSignIn] Could not decode token payload: $err');
      }

      final oauthCred = fb.OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
        accessToken: appleCred.authorizationCode,
      );

      debugPrint('>>> [AppleSignIn] Authenticating with Firebase...');
      final userCred = await _auth.signInWithCredential(oauthCred);
      final fbUser = userCred.user!;
      debugPrint('>>> [AppleSignIn] Firebase auth success! uid: ${fbUser.uid}, email: ${fbUser.email}');

      final doc = await _userDoc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        _cachedUser = AppUser.fromMap(doc.data()!, fbUser.uid);
      } else {
        final fullName = [appleCred.givenName, appleCred.familyName].where((s) => s != null && s.isNotEmpty).join(' ');
        final newUser = AppUser(
          uid: fbUser.uid,
          name: fullName.isNotEmpty ? fullName : (fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Landowner'),
          email: fbUser.email ?? appleCred.email ?? '',
          avatarUrl: fbUser.photoURL,
        );
        await _userDoc(fbUser.uid).set(newUser.toMap(), SetOptions(merge: true));
        _cachedUser = newUser;
      }
      return _cachedUser!;
    } on fb.FirebaseAuthException catch (e, st) {
      debugPrint('>>> [AppleSignIn] FirebaseAuthException: ${e.code} - ${e.message}\n$st');
      if (e.code == 'operation-not-allowed') {
        throw const AuthFailure('Apple sign-in is not enabled in Firebase Console. Please enable "Apple" under Firebase Authentication > Sign-in method.');
      }
      if (e.code == 'invalid-credential') {
        throw AuthFailure('Firebase rejected Apple credential: ${e.message ?? "Invalid OAuth response from apple.com"}');
      }
      throw AuthFailure(_mapAuthException(e));
    } on SignInWithAppleAuthorizationException catch (e, st) {
      debugPrint('>>> [AppleSignIn] SignInWithAppleAuthorizationException: code=${e.code} message=${e.message}\n$st');
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthFailure('Apple sign-in was canceled.');
      }
      throw AuthFailure('Apple error (${e.code}): ${e.message}');
    } catch (e, st) {
      debugPrint('>>> [AppleSignIn] Unexpected error: $e\n$st');
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Apple sign-in failed: $e');
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
    _cachedUser = null;
  }

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
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw const AuthFailure('Not signed in.');

    try {
      if (name.trim() != fbUser.displayName) {
        await fbUser.updateDisplayName(name.trim());
      }
      if (avatarUrl != null && avatarUrl != fbUser.photoURL) {
        await fbUser.updatePhotoURL(avatarUrl);
      }

      final updated = (_cachedUser ??
              AppUser(
                uid: fbUser.uid,
                name: name.trim(),
                email: email.trim(),
              ))
          .copyWith(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        avatarUrl: avatarUrl,
        city: city,
        currencySymbol: currencySymbol,
        currencyCode: currencyCode,
      );

      await _userDoc(fbUser.uid).set(updated.toMap(), SetOptions(merge: true));
      _cachedUser = updated;
      return updated;
    } catch (e) {
      if (e is AuthFailure) rethrow;
      debugPrint('Auth error: $e');
      throw const AuthFailure('Something went wrong. Check your connection and try again.');
    }
  }

  @override
  Future<void> changePassword({required String current, required String next}) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null || fbUser.email == null) {
      throw const AuthFailure('Not signed in.');
    }

    try {
      final cred = fb.EmailAuthProvider.credential(
        email: fbUser.email!,
        password: current,
      );
      await fbUser.reauthenticateWithCredential(cred);
      await fbUser.updatePassword(next);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthException(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      debugPrint('Auth error: $e');
      throw const AuthFailure('Something went wrong. Check your connection and try again.');
    }
  }

  @override
  String? get signInMethod {
    final ids = _auth.currentUser?.providerData.map((p) => p.providerId).toSet() ?? const {};
    if (ids.contains('password')) return 'password';
    if (ids.contains('apple.com')) return 'apple.com';
    if (ids.contains('google.com')) return 'google.com';
    return null;
  }

  /// Deletion runs server-side: writing `accountDeletions/{uid}` triggers the
  /// onAccountDeletionRequested Cloud Function, which removes uploaded media,
  /// every Firestore document and the sign-in with admin rights — so the user
  /// isn't asked for a password or a fresh login.
  @override
  Future<void> deleteAccount() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw const AuthFailure('Not signed in.');
    final method = signInMethod;

    try {
      // Sign in with Apple accounts must revoke the app's Apple tokens on
      // deletion (App Store requirement). Apple shows its own confirm sheet.
      if (method == 'apple.com') {
        final apple = await SignInWithApple.getAppleIDCredential(scopes: const []);
        try {
          await _auth.revokeTokenWithAuthorizationCode(apple.authorizationCode);
        } catch (e) {
          debugPrint('Apple token revoke note: $e');
        }
      }

      final uid = fbUser.uid;
      AccountDeletion.inProgress = true;
      await _firestore.collection('accountDeletions').doc(uid).set({'requestedAt': FieldValue.serverTimestamp()});
      // Wait for the server to finish (the profile document disappears).
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      var done = false;
      while (!done && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        try {
          done = !(await _userDoc(uid).get(const GetOptions(source: Source.server))).exists;
        } on FirebaseException catch (e) {
          // Once the sign-in is gone, reads can be refused — that also means done.
          done = e.code == 'permission-denied' || e.code == 'unauthenticated';
        }
      }
      if (!done) {
        AccountDeletion.inProgress = false;
        throw const AuthFailure('Deletion is taking longer than usual. It will finish shortly — you can close the app.');
      }

      if (method == 'google.com') {
        try {
          await GoogleSignIn.instance.disconnect();
        } catch (_) {}
      }
      _cachedUser = null;
      // The server already removed the user; this clears the local session.
      await _auth.signOut();
      AccountDeletion.inProgress = false;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const AuthFailure('Account deletion was canceled.');
      debugPrint('Apple confirm error: ${e.code} ${e.message}');
      throw const AuthFailure('Couldn\u2019t confirm your Apple ID. Please try again.');
    } catch (e) {
      AccountDeletion.inProgress = false;
      if (e is AuthFailure) rethrow;
      debugPrint('Delete account error: $e');
      throw const AuthFailure('Couldn\u2019t delete your account. Check your connection and try again.');
    }
  }
}
