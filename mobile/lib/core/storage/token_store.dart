import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT (and basic identity) in the platform keychain/keystore.
class TokenStore {
  static const _storage = FlutterSecureStorage();
  static const _kToken = 'finki_token';
  static const _kUserId = 'finki_userId';
  static const _kEmail = 'finki_email';
  static const _kPassword = 'finki_password';
  static const _kName = 'finki_name';

  Future<void> save({
    required String token,
    required int userId,
    required String email,
    String? name,
  }) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUserId, value: '$userId');
    await _storage.write(key: _kEmail, value: email);
    // A later login without a name must not wipe the one already on file.
    if (name != null && name.isNotEmpty) {
      await _storage.write(key: _kName, value: name);
    }
  }

  Future<void> savePassword(String password) => _storage.write(key: _kPassword, value: password);

  /// Updates just the display name, for a session that is already signed in.
  Future<void> saveName(String name) => _storage.write(key: _kName, value: name);

  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<String?> readEmail() => _storage.read(key: _kEmail);
  Future<String?> readPassword() => _storage.read(key: _kPassword);
  Future<String?> readName() => _storage.read(key: _kName);

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kName);
  }
}
