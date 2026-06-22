import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT (and basic identity) in the platform keychain/keystore.
class TokenStore {
  static const _storage = FlutterSecureStorage();
  static const _kToken = 'finki_token';
  static const _kUserId = 'finki_userId';
  static const _kEmail = 'finki_email';
  static const _kPassword = 'finki_password';

  Future<void> save({required String token, required int userId, required String email}) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUserId, value: '$userId');
    await _storage.write(key: _kEmail, value: email);
  }

  Future<void> savePassword(String password) => _storage.write(key: _kPassword, value: password);

  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<String?> readEmail() => _storage.read(key: _kEmail);
  Future<String?> readPassword() => _storage.read(key: _kPassword);

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kEmail);
  }
}
