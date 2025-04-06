// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
// import '../models/user.dart'; // User modelini kullanmak istersen

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  int? _userId;
  String? _username;
  String? _email;
  String? _errorMessage;
  bool _isLoading = false;
  // User? _currentUser; // User modelini kullanmak istersen

  bool get isLoggedIn => _userId != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  // User? get currentUser => _currentUser;

  void _setLoading(bool value) { if (_isLoading == value) return; _isLoading = value; notifyListeners(); }
  void _setError(String? message) { _errorMessage = message; _setLoading(false); notifyListeners(); }

  Future<bool> register(String username, String password, String email) async {
    _setLoading(true); _setError(null);
    try {
      // API'den dönen mesajı flash message olarak göstermek daha iyi olabilir
      await _apiService.register(username, email, password);
      _setLoading(false);
      return true; // API hata fırlatmazsa başarılı kabul edilir
    } catch (error) {
      _setError(error.toString()); // API'den gelen veya ağ hatası mesajı
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true); _setError(null);
    try {
      final response = await _apiService.login(username, password);
      // API yanıtından kullanıcı bilgilerini al ('user' anahtarı altında)
      final userData = response['user'] as Map<String, dynamic>?; // Null check
      if (userData != null) {
         _userId = userData['user_id'];
         _username = userData['username'];
         _email = userData['email'];
         // _currentUser = User.fromJson(userData); // User modeli kullanılıyorsa

         await _saveLoginInfo(); // Oturum bilgilerini kaydet
         _isLoading = false;
         notifyListeners(); // State güncellendi, UI'ı uyar
         return true;
      } else {
         throw Exception("API yanıtında kullanıcı bilgisi bulunamadı.");
      }
    } catch (error) {
      _setError(error.toString());
      return false;
    }
  }

  Future<void> logout() async {
    _userId = null; _username = null; _email = null; /* _currentUser = null; */
    _errorMessage = null; _isLoading = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Tüm kayıtlı veriyi sil
    notifyListeners();
    // print("Logged out and session cleared.");
  }

  // Uygulama açılışında otomatik giriş denemesi
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userId')) { return false; }

    _userId = prefs.getInt('userId');
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    // _currentUser = User(...) // Kayıtlı veriden User objesi oluşturulabilir

    if (_userId != null) {
      // print("Auto login successful: ID=$_userId, User=$_username");
      // Otomatik girişte notifyListeners'a gerek yok, Splash screen yönlendirme yapacak
      return true;
    }
    return false;
  }

  // Yardımcı: Giriş bilgilerini SharedPreferences'a kaydet
  Future<void> _saveLoginInfo() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', _userId!);
    if (_username != null) await prefs.setString('username', _username!);
    if (_email != null) await prefs.setString('email', _email!);
    // print("Saved login info: userId=$_userId, username=$_username");
  }
}