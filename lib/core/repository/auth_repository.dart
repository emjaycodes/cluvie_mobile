import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/utils/build_config.dart';

import '../../../core/api/api_client.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  static const _tokenKey = 'auth_token';

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _apiClient.setAuthToken(token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _apiClient.clearAuthToken();
  }

  /// Restores a saved session (sets the auth header). True when a token exists.
  Future<bool> restoreSession() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return false;
    _apiClient.setAuthToken(token);
    return true;
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {'email': email, 'password': password});

      // Parse first: a malformed response must not leave a half-saved session.
      final token = response.data['token'] as String;
      final user = UserModel.fromJson(response.data['user']);
      await _saveToken(token);
      return user;
    } catch (e) {
      log('Error during login: $e');
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> register(String username, String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {'username': username, 'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      final user = UserModel.fromJson(response.data['user']);
      await _saveToken(token);
      return user;
    } catch (e) {
      log('❌ Error during registration: $e');
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> getProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception("No auth token");

    _apiClient.setAuthToken(token);
    final response = await _apiClient.get('/auth/profile');

    return UserModel.fromJson(response.data);
  }

  Future<void> logout() async {
    await _clearToken();
  }
}
