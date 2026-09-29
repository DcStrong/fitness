import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT tokens.
///
/// Uses [FlutterSecureStorage] on mobile/web.
/// On desktop (macOS/Linux/Windows) uses [SharedPreferences] because Keychain
/// Sharing entitlements require a signed Apple development certificate, which
/// local `flutter run -d macos` with ad-hoc signing (`CODE_SIGN_IDENTITY=-`)
/// does not provide.
class TokenStorage {
  TokenStorage({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? preferences,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _preferencesOverride = preferences;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _preferencesOverride;
  SharedPreferences? _preferences;

  static bool get _usePrefs {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ??=
        _preferencesOverride ?? await SharedPreferences.getInstance();
  }

  Future<String?> readAccessToken() async {
    if (_usePrefs) {
      return (await _prefs()).getString(_accessKey);
    }
    return _secureStorage.read(key: _accessKey);
  }

  Future<String?> readRefreshToken() async {
    if (_usePrefs) {
      return (await _prefs()).getString(_refreshKey);
    }
    return _secureStorage.read(key: _refreshKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (_usePrefs) {
      final prefs = await _prefs();
      await prefs.setString(_accessKey, accessToken);
      await prefs.setString(_refreshKey, refreshToken);
      return;
    }
    await _secureStorage.write(key: _accessKey, value: accessToken);
    await _secureStorage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> clear() async {
    if (_usePrefs) {
      final prefs = await _prefs();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
      return;
    }
    await _secureStorage.delete(key: _accessKey);
    await _secureStorage.delete(key: _refreshKey);
  }
}
