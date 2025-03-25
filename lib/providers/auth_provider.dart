import 'package:flutter/material.dart';
import 'package:flutter_application1/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 1. Import eklendi

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = FlutterSecureStorage(); // 2. Düzeltildi: const kaldırıldı

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _userId;
  String? get userId => _userId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> checkLoginStatus() async {
    _userId = await _storage.read(key: 'user_id');
    _isLoggedIn = _userId != null;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = await _authService.login(username, password);
      if (userId != null) {
        _userId = userId;
        _isLoggedIn = true;
        await _storage.write(key: 'user_id', value: userId);
      } else {
        _errorMessage = "Kullanıcı adı veya şifre hatalı.";
      }
    } catch (e) {
      _errorMessage = "Giriş Sırasında Hata: $e"; // String interpolation düzeltildi
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String password, String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUserId = await _authService.register(username, password, email);
      if (newUserId != null) {
        await login(username, password);
      } else {
        _errorMessage = "Kayıt Başarısız.";
      }
    } catch (e) {
      _errorMessage = "Kayıt Sırasında Hata: $e"; // String interpolation düzeltildi
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = null;
    await _storage.delete(key: 'user_id');
    notifyListeners();
  }
}