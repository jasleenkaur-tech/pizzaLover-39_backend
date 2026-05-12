// lib/services/api_auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiAuthService {
  final _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _adminAccessToken; // Separate token for admin
  String? _refreshToken;
  Map<String, dynamic>? _userData;

  String? get token => _accessToken;
  String? get adminToken => _adminAccessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userData => _userData;

  // Persist data to secure storage
  Future<void> _saveAuthData(String access, String? refresh, Map<String, dynamic> user) async {
    await _storage.write(key: 'accessToken', value: access);
    if (refresh != null) {
      await _storage.write(key: 'refreshToken', value: refresh);
    }
    await _storage.write(key: 'userData', value: jsonEncode(user));
  }

  // Persist admin token separately
  Future<void> _saveAdminToken(String token) async {
    _adminAccessToken = token;
    await _storage.write(key: 'adminAccessToken', value: token);
  }

  // Update only user data in storage (for real-time profile updates)
  Future<void> updateStoredUser(Map<String, dynamic> user) async {
    _userData = user;
    await _storage.write(key: 'userData', value: jsonEncode(user));
  }

  // Load data from secure storage
  Future<bool> loadStoredAuth() async {
    try {
      _accessToken = await _storage.read(key: 'accessToken');
      _adminAccessToken = await _storage.read(key: 'adminAccessToken');
      _refreshToken = await _storage.read(key: 'refreshToken');
      String? userJson = await _storage.read(key: 'userData');
      if (userJson != null) {
        _userData = jsonDecode(userJson);
      }
      return _accessToken != null;
    } catch (e) {
      print("Error loading auth: $e");
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _userData = data['user'];
        
        await _saveAuthData(_accessToken!, _refreshToken, _userData!);
        return true;
      }
      return false;
    } catch (e) {
      print('Login Error: $e');
      return false;
    }
  }

  // Specific admin login implementation
  Future<Map<String, dynamic>?> adminLogin() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'email': 'admin@pizzalovers39.com',
          'password': 'Admin@123',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (data['user']['role'] == 'admin') {
          await _saveAdminToken(data['accessToken']);
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Admin Login Error: $e');
      return null;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signup),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || (response.statusCode == 200 && data['success'] == true)) {
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _userData = data['user'];

        await _saveAuthData(_accessToken!, _refreshToken, _userData!);
        return true;
      }
      return false;
    } catch (e) {
      print('Signup Error: $e');
      return false;
    }
  }

  // Optional: Handle token refresh logic
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh-token'),
        headers: ApiConfig.headers(),
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _accessToken = data['accessToken'];
        await _storage.write(key: 'accessToken', value: _accessToken);
        return true;
      }
    } catch (e) {
      print('Token Refresh Error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    // Capture tokens before clearing local state
    final String? tokenToRevoke = _accessToken;
    final String? refreshToRevoke = _refreshToken;

    // 1. Immediately clear local in-memory state
    _accessToken = null;
    _adminAccessToken = null;
    _refreshToken = null;
    _userData = null;

    // 2. Immediately clear secure storage
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('Error clearing storage: $e');
    }

    // 3. Call backend API in the background. 
    try {
      if (tokenToRevoke != null) {
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: ApiConfig.headers(tokenToRevoke),
          body: jsonEncode({
            'refreshToken': refreshToRevoke,
          }),
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      print('Logout API background call failed: $e');
    }
  }

  Future<void> logoutAdmin() async {
    _adminAccessToken = null;
    await _storage.delete(key: 'adminAccessToken');
  }
}
