import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Безопасное хранилище JWT (Access/Refresh) токенов на базе Keychain / Keystore.
///
/// Строгое правило безопасности: JWT токены запрещено хранить в Hive или SharedPreferences.
class SecureTokenStorage {
  SecureTokenStorage._(this._storage, this._inMemory);

  factory SecureTokenStorage() {
    return SecureTokenStorage._(const FlutterSecureStorage(), false);
  }

  /// Изолированный конструктор для тестов без нативных каналов Keychain/Keystore.
  factory SecureTokenStorage.inMemory() {
    return SecureTokenStorage._(null, true);
  }

  static const _keyAccessToken = 'toidym_jwt_access';
  static const _keyRefreshToken = 'toidym_jwt_refresh';
  static const _keySessionUserId = 'toidym_jwt_user_id';

  final FlutterSecureStorage? _storage;
  final bool _inMemory;
  final Map<String, String> _memory = {};

  Future<String?> getAccessToken() => _readKey(_keyAccessToken);

  Future<String?> getRefreshToken() => _readKey(_keyRefreshToken);

  Future<String?> getSessionUserId() => _readKey(_keySessionUserId);

  Future<String?> _readKey(String key) async {
    final cached = _memory[key];
    if (_inMemory || cached != null) return cached;
    final storage = _storage;
    if (storage == null) return null;
    try {
      final value = await storage.read(key: key);
      if (value != null && value.isNotEmpty) {
        _memory[key] = value;
      }
      return value;
    } catch (_) {
      // На Flutter Web параллельная или повреждённая WebCrypto-запись не должна
      // ломать Dio AuthInterceptor при чтении токена.
      try {
        await storage.delete(key: key);
      } catch (_) {}
      return _memory[key];
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    _memory[_keyAccessToken] = accessToken;
    _memory[_keyRefreshToken] = refreshToken;
    _memory[_keySessionUserId] = userId;
    if (_inMemory) return;
    final storage = _storage;
    if (storage == null) return;
    // Пишем последовательно: в flutter_secure_storage_web параллельный Future.wait
    // на пустом localStorage создаёт гонку генерации WebCrypto-ключа.
    try {
      await storage.write(key: _keyAccessToken, value: accessToken);
      await storage.write(key: _keyRefreshToken, value: refreshToken);
      await storage.write(key: _keySessionUserId, value: userId);
    } catch (_) {
      // В памяти сессия уже сохранена; браузерная ошибка шифрования не блокирует вход.
    }
  }

  Future<void> clearSession() async {
    _memory.clear();
    if (_inMemory) return;
    final storage = _storage;
    if (storage == null) return;
    for (final key in const [
      _keyAccessToken,
      _keyRefreshToken,
      _keySessionUserId,
    ]) {
      try {
        await storage.delete(key: key);
      } catch (_) {}
    }
  }
}
