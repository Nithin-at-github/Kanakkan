import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();

  final LocalAuthentication _auth = LocalAuthentication();

  static const String pinKey = "app_pin";

  Future<void> savePin(String pin) async {
    await _storage.write(key: pinKey, value: pin);
  }

  Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _storage.read(key: pinKey);

    return storedPin == enteredPin;
  }

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: pinKey);

    return pin != null;
  }

  Future<bool> authenticateBiometric() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) return false;

      return await _auth.authenticate(
        localizedReason: "Authenticate to access Kanakkan",
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        sensitiveTransaction: true,
      );
    } catch (e) {
      return false;
    }
  }
}
