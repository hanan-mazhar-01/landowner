import 'package:local_auth/local_auth.dart';

/// Face ID / Touch ID / fingerprint gate.
abstract final class BiometricService {
  static final _auth = LocalAuthentication();

  static Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> confirm(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } catch (_) {
      return false;
    }
  }
}
