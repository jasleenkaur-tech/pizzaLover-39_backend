// lib/models/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_auth_service.dart';

/// Admin Access restricted to these numbers
const List<String> kAdminPhones = ['9878497680', '9878394950'];

class AuthProvider extends ChangeNotifier {
  final ApiAuthService _apiAuth = ApiAuthService();

  bool _isLoading = true; 
  String? _token;
  Map<String, dynamic>? _userData;
  String? _currentAddress;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    await tryRestoreSession();
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get currentAddress => _currentAddress;
  
  String get displayName => _userData?['name'] ?? 'User';
  String get displayEmail => _userData?['email'] ?? 'Not set';
  String get displayPhone => _userData?['phone'] ?? '';
  String get userId       => _userData?['id'] ?? _userData?['_id'] ?? '';
  String get role         => _userData?['role'] ?? 'user';
  
  // Admin check: Phone must be in authorized list
  bool get isAdmin => kAdminPhones.contains(displayPhone);

  Future<void> tryRestoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _apiAuth.loadStoredAuth();
      if (success) {
        _token = _apiAuth.token;
        _userData = _apiAuth.userData;
      }
    } catch (e) {
      debugPrint('AuthProvider: Session restoration error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setAddress(String addr) {
    _currentAddress = addr;
    notifyListeners();
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _apiAuth.signup(
        name: name, email: email, password: password, phone: phone,
      );
      if (success) {
        _token = _apiAuth.token;
        _userData = _apiAuth.userData;
        notifyListeners();
        return null;
      }
      return 'Signup failed.';
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _apiAuth.login(email, password);
      if (success) {
        _token = _apiAuth.token;
        _userData = _apiAuth.userData;
        notifyListeners();
        return null;
      }
      return 'Invalid email or password.';
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    return 'Google sign-in is coming soon. Please use Email/Password.';
  }

  Future<void> updateProfile({String? name, String? phone, String? email}) async {
    if (_userData == null) return;
    
    final updatedUser = Map<String, dynamic>.from(_userData!);
    if (name != null) updatedUser['name'] = name;
    if (phone != null) updatedUser['phone'] = phone;
    if (email != null) updatedUser['email'] = email;
    
    _userData = updatedUser;
    await _apiAuth.updateStoredUser(updatedUser);
    notifyListeners();
  }

  Future<void> logout() async {
    await _apiAuth.logout();
    _token = null;
    _userData = null;
    _currentAddress = null;
    notifyListeners();
  }

  void handleUnauthorized() {
    logout();
  }
}
