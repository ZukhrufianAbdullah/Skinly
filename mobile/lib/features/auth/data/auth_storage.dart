import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'skinly_jwt_token';
  static const _onboardingKey = 'skinly_has_seen_onboarding';

  final FlutterSecureStorage _secureStorage;
  String? _cachedToken;

  AuthStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Token sinkron untuk interceptor Dio
  String? get cachedToken => _cachedToken;

  /// Inisialisasi token dari secure storage saat app startup
  Future<String?> initToken() async {
    try {
      _cachedToken = await _secureStorage.read(key: _tokenKey);
      return _cachedToken;
    } catch (_) {
      _cachedToken = null;
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, seen);
  }
}
