import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de almacenamiento local con encriptación por hardware para tokens sensibles y SharedPreferences para UI state
class LocalStorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  LocalStorageService(
    this._prefs, [
    FlutterSecureStorage? secureStorage,
  ]) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _keySessionUserId = 'fishbit_session_uid';
  static const String _keyActiveSedeId = 'fishbit_active_sede_id';
  static const String _keyThemeMode = 'fishbit_theme_mode';
  static const String _keyOnboarded = 'fishbit_onboarded';
  static const String _keyAuthToken = 'fishbit_secure_auth_token';
  static const String _keyRefreshToken = 'fishbit_secure_refresh_token';

  // SharedPreferences (UI & non-sensitive session metadata)
  String? getSessionUserId() => _prefs.getString(_keySessionUserId);
  Future<bool> setSessionUserId(String? uid) async {
    if (uid == null) {
      await _secureStorage.delete(key: _keySessionUserId);
      return _prefs.remove(_keySessionUserId);
    }
    await _secureStorage.write(key: _keySessionUserId, value: uid);
    return _prefs.setString(_keySessionUserId, uid);
  }

  String? getActiveSedeId() => _prefs.getString(_keyActiveSedeId);
  Future<bool> setActiveSedeId(String? sedeId) async {
    if (sedeId == null) return _prefs.remove(_keyActiveSedeId);
    return _prefs.setString(_keyActiveSedeId, sedeId);
  }

  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'dark';
  Future<bool> setThemeMode(String mode) => _prefs.setString(_keyThemeMode, mode);

  bool isOnboarded() => _prefs.getBool(_keyOnboarded) ?? false;
  Future<bool> setOnboarded(bool value) => _prefs.setBool(_keyOnboarded, value);

  // FlutterSecureStorage operations for sensitive credentials & tokens
  Future<void> saveSecureToken(String token) async {
    await _secureStorage.write(key: _keyAuthToken, value: token);
  }

  Future<String?> getSecureToken() async {
    return _secureStorage.read(key: _keyAuthToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _keyRefreshToken);
  }

  Future<void> writeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readSecure(String key) async {
    return _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keySessionUserId);
    await _prefs.remove(_keyActiveSedeId);
    await _secureStorage.deleteAll();
  }
}
