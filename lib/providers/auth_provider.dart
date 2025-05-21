// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart'; // ChangeNotifier ve debugPrint için
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // ApiService kullan

class AuthProvider with ChangeNotifier {
  final ApiService _apiService; // ApiService dışarıdan alınabilir veya oluşturulabilir
  // Eğer dışarıdan alacaksanız constructor ekleyin:
  // AuthProvider(this._apiService);
  // Veya doğrudan oluşturun:
  AuthProvider() : _apiService = ApiService();

  int? _userId;
  String? _username;
  String? _email;
  String? _errorMessage;
  bool _isLoading = false;

  // --- Public Getters ---
  bool get isLoggedIn => _userId != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get userId => _userId;
  String? get username => _username;
  String? get email => _email;

  // --- State Yönetimi ---
  void _setLoading(bool value) { if (_isLoading == value) return; _isLoading = value; notifyListeners(); }
  void _setError(String? message) { _errorMessage = message?.replaceFirst("Exception: ", ""); _setLoading(false); notifyListeners(); }

  // --- İşlemler ---
  Future<bool> register(String username, String password, String email) async {
    _setLoading(true); _setError(null);
    try {
      // ApiService'deki User döndüren registerUser metodunu çağır
      // Dönen User nesnesi şimdilik kullanılmıyor ama ileride kullanılabilir.
      await _apiService.registerUser(username, email, password);
      _setLoading(false);
      return true;
    } catch (error) {
      _setError(error.toString()); // _setError zaten replaceFirst yapıyor
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true); _setError(null);
    try {
      // ApiService.login zaten User nesnesi döndürüyor.
      final loggedInUser = await _apiService.login(username, password);

      // loggedInUser.id String tipinde geliyor olabilir, int'e parse et.
      // User.id'nin null olamayacağını varsayarak (hata mesajına göre String tipinde)
      final int? parsedUserId = int.tryParse(loggedInUser.id);

      if (parsedUserId != null && parsedUserId != 0) { // Parse başarılı olduysa ve ID 0 değilse
         _userId = parsedUserId;
         _username = loggedInUser.username; // User modelindeki alanlar
         _email = loggedInUser.email;     // User modelindeki alanlar
         // ApiService'e userId'yi set et (ÖNEMLİ)
         _apiService.setCurrentUserId(_userId); // _userId artık int? tipinde
         await _saveLoginInfo(); // Oturum bilgilerini kaydet
         _isLoading = false;
         notifyListeners(); // Başarılı giriş sonrası UI güncellenir
         return true;
      } else {
        _setError(parsedUserId == null ? "Kullanıcı ID formatı geçersiz." : "Giriş yanıtı geçersiz (ID 0).");
        return false;
      }
    } catch (error) {
      _apiService.setCurrentUserId(null);
      _apiService.setAuthToken(null); // Hata durumunda ID'yi temizle
      _setError(error.toString());
      return false;
    }
  }

  Future<void> logout() async {
    // State'i sıfırla
    _userId = null; _username = null; _email = null;
    _errorMessage = null; _isLoading = false;
    // ApiService'deki ID'yi temizle
    _apiService.setCurrentUserId(null); // Kullanıcı ID'sini temizle
    _apiService.setAuthToken(null);     // Auth token'ı da temizle
    // Kayıtlı oturumu temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // Sadece ilgili key'leri remove et
    await prefs.remove('authToken'); // Token'ı da temizle
    await prefs.remove('username');
    await prefs.remove('email');
    notifyListeners();
    debugPrint("AuthProvider: Logged out and session cleared.");
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('userId'); // Önce değişkene al
    final storedToken = prefs.getString('authToken');

    if (storedUserId == null || storedToken == null) {
      debugPrint("AuthProvider: No stored user ID.");
      await logout(); // Eksik bilgi varsa tam logout yap
      return false;
    }

    // State'i yükle
    _userId = storedUserId;
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    // ApiService'e userId'yi bildir
    _apiService.setCurrentUserId(_userId);
    _apiService.setAuthToken(storedToken); // Token'ı ApiService'e set et
    debugPrint("AuthProvider: Auto login successful. UserID: $_userId");
    // notifyListeners(); // ProxyProvider zaten dinliyor, burada gerekmeyebilir
                      // Ancak doğrudan Consumer ile dinleniyorsa lazım olabilir.
                      // Şimdilik ekleyelim, zararı olmaz.
    notifyListeners();
    return true;
  }

  Future<void> _saveLoginInfo() async {
    if (_userId == null) return;
    try {
        final prefs = await SharedPreferences.getInstance();
        // ApiService'den güncel token'ı alıp kaydetmek daha iyi olabilir,
        // ama login sırasında ApiService kendi içinde set ediyor.
        if (_apiService.getAuthToken() != null) { // ApiService'e bir getter eklemek gerekebilir
          await prefs.setString('authToken', _apiService.getAuthToken()!);
        }
        await prefs.setInt('userId', _userId!);
        if (_username != null) await prefs.setString('username', _username!);
        if (_email != null) await prefs.setString('email', _email!);
        debugPrint("AuthProvider: Saved login info. UserID: $_userId");
    } catch (e) {
         debugPrint("AuthProvider Error saving login info: $e");
    }
  }
}