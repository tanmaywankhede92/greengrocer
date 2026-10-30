import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/api_client.dart';
import '../../../core/constants.dart';
import '../../../models/user.dart';

class AuthService {
  final ApiClient _client = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<({User user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data['data'];
    final user = User.fromJson(data['user']);
    await _saveTokens(data['accessToken'], data['refreshToken']);
    await cacheUser(user);
    return (user: user, accessToken: data['accessToken'] as String, refreshToken: data['refreshToken'] as String);
  }

  Future<({User user, String accessToken, String refreshToken})> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.post('/auth/register', data: {
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    final data = response.data['data'];
    final user = User.fromJson(data['user']);
    await _saveTokens(data['accessToken'], data['refreshToken']);
    await cacheUser(user);
    return (user: user, accessToken: data['accessToken'] as String, refreshToken: data['refreshToken'] as String);
  }

  Future<void> cacheUser(User user) async {
    try {
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<User?> getCachedUser() async {
    try {
      final jsonStr = await _storage.read(key: AppConstants.userKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return User.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<void> logout() async {
    await _client.clearTokens();
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<User> getProfile() async {
    final response = await _client.get('/auth/me');
    return User.fromJson(response.data['data']);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: access);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);
  }
}
