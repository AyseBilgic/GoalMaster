// lib/services/api_service.dart
import 'dart:convert'; // JSON işlemleri için
import 'dart:io'; // Platform kontrolü için (Android Emulator IP vs.)
import 'package:http/http.dart' as http; // HTTP istekleri için
import '../models/goal.dart'; // Kendi Goal modelimiz (alan adları DB ile uyumlu olmalı)

class ApiService {
  // Backend API sunucusunun adresi
  // Android Emulator'dan bilgisayarın localhost'una erişim için 10.0.2.2 kullanılır.
  // Fiziksel cihazdan aynı ağdaysanız, bilgisayarınızın yerel IP adresini kullanın.
  // Flask sunucunuzun 8080 portunda çalıştığını ve API rotalarının /api altında olduğunu varsayıyoruz.
  final String _baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:8080/api' // Android Emulator için
      : 'http://localhost:8080/api'; // Diğer platformlar (iOS simulator, web, desktop)

  // --- Yardımcı Fonksiyonlar ---

  // İstekler için standart başlıkları oluşturur (şimdilik sadece Content-Type)
  Map<String, String> _getHeaders() {
    // İleride JWT token gibi yetkilendirme başlıkları buraya eklenebilir:
    // String? token = await _getTokenFromStorage(); // Token'ı al
    // if (token != null) headers['Authorization'] = 'Bearer $token';
    return {'Content-Type': 'application/json; charset=UTF-8'}; // UTF-8 eklemek iyi olabilir
  }

  // API yanıtlarını işleyen ve hata kontrolü yapan merkezi fonksiyon
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    // Yanıt gövdesini UTF-8 olarak decode et (Türkçe karakterler için önemli)
    final responseBody = utf8.decode(response.bodyBytes);
    // print("Raw Response Body: $responseBody"); // Debug için ham yanıtı logla

    try {
      // Yanıt gövdesi boş olabilir (örn: 204 No Content veya bazen 200 OK)
      if (responseBody.isEmpty) {
        if (statusCode >= 200 && statusCode < 300) {
          // Başarılı ama içerik yoksa null dön (veya duruma göre True)
          return null;
        } else {
          // Başarısız ve boş yanıt
          throw Exception('Sunucudan boş yanıt alındı (Status: $statusCode)');
        }
      }

      // Yanıt gövdesini JSON olarak parse etmeyi dene
      final responseData = jsonDecode(responseBody);

      // Başarılı HTTP durum kodları (200-299)
      if (statusCode >= 200 && statusCode < 300) {
        return responseData; // Decode edilmiş JSON verisini döndür
      }
      // Bilinen Hata Durum Kodları (API'den gelen hata mesajını kullan)
      else {
        // API yanıtında 'error' anahtarı varsa onu kullan, yoksa tüm body'yi kullan
        final errorMessage = responseData is Map ? responseData['error'] : responseBody;
        throw Exception('${errorMessage ?? 'Bilinmeyen API Hatası'} (Status: $statusCode)');
      }
    } catch (e) { // jsonDecode hatası veya yukarıdaki Exception'lar
      print("Response Handling/JSON Decode Error: $e"); // Hatayı logla
      // JSON parse edilemiyorsa veya başka bir hata varsa, daha genel bir hata fırlat
      throw Exception('Sunucu yanıtı işlenemedi veya geçersiz format (Status: $statusCode)');
    }
  }

  // --- AUTH Endpoints ---

  /// Kullanıcı kaydı yapar. Başarılı olursa API yanıtını, olmazsa Exception fırlatır.
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$_baseUrl/register'); // POST /api/register
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(), // Başlıkları al
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      // print('[API Register] URL: $url, Status: ${response.statusCode}'); // Debug
      // _handleResponse Map<String, dynamic> veya Exception döner
      return await _handleResponse(response);
    } catch (e) {
      // print("[API Register] Network Error: $e"); // Debug
      // _handleResponse zaten Exception fırlattıysa tekrar fırlat, değilse yeni Exception oluştur
      if (e is Exception) rethrow;
      throw Exception('Kayıt başarısız: Ağ hatası veya sunucuya ulaşılamadı.');
    }
  }

  /// Kullanıcı girişi yapar. Başarılı olursa kullanıcı bilgilerini içeren Map, olmazsa Exception fırlatır.
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/login'); // POST /api/login
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'username': username, 'password': password}),
      );
      // print('[API Login] URL: $url, Status: ${response.statusCode}'); // Debug
      return await _handleResponse(response);
    } catch (e) {
      // print("[API Login] Network Error: $e"); // Debug
      if (e is Exception) rethrow;
      throw Exception('Giriş başarısız: Ağ hatası veya sunucuya ulaşılamadı.');
    }
  }

  // --- GOAL Endpoints ---

  /// Belirli bir kullanıcıya ait hedefleri API'den çeker.
  Future<List<Goal>> fetchGoals(int userId) async {
    // Beklenen API endpoint: GET /api/goals?userId={userId}
    final url = Uri.parse('$_baseUrl/goals?userId=$userId');
    try {
      final response = await http.get(url, headers: _getHeaders());
      // print('[API Fetch Goals] URL: $url, Status: ${response.statusCode}'); // Debug
      final responseData = await _handleResponse(response);
      if (responseData is List) {
        // Gelen JSON listesini Goal objelerine çevir
        return responseData.map((json) => Goal.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        // API beklenmedik bir formatta yanıt döndürürse (liste değilse)
        print("API Fetch Goals: Unexpected response format. Expected a List, got: ${responseData.runtimeType}");
        return []; // Boş liste döndür
      }
    } catch (e) {
      // print("[API Fetch Goals] Error: $e"); // Debug
      // Hata mesajını koruyarak tekrar fırlat
      throw Exception('Hedefler alınamadı: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  /// Yeni bir hedefi API'ye gönderir. Başarılı olursa oluşturulan hedefi döner.
  Future<Goal> addGoal(Goal goal) async {
    final url = Uri.parse('$_baseUrl/goals'); // POST /api/goals
    try {
      // Goal objesini JSON'a çevirip gönder
      final response = await http.post(url, headers: _getHeaders(), body: jsonEncode(goal.toJson()));
      // print('[API Add Goal] URL: $url, Status: ${response.statusCode}'); // Debug
      final responseData = await _handleResponse(response);
      // API, oluşturulan ve ID'si atanmış hedefi geri dönmeli
      return Goal.fromJson(responseData);
    } catch (e) {
      // print("[API Add Goal] Error: $e"); // Debug
      throw Exception('Hedef eklenemedi: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  /// Mevcut bir hedefin tüm bilgilerini API'de günceller.
  Future<void> updateGoal(Goal goal) async {
    final url = Uri.parse('$_baseUrl/goals/${goal.goalId}'); // PUT /api/goals/{id}
    try {
      final response = await http.put(url, headers: _getHeaders(), body: jsonEncode(goal.toJson()));
      // print('[API Update Goal] URL: $url, Status: ${response.statusCode}'); // Debug
      await _handleResponse(response); // Başarı veya hata kontrolü
    } catch (e) {
      // print("[API Update Goal] Error: $e"); // Debug
      throw Exception('Hedef güncellenemedi: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  /// Bir hedefin tamamlanma durumunu API'de değiştirir (toggle).
  Future<void> toggleGoalCompletion(int goalId) async {
    // Beklenen API endpoint: PATCH /api/goals/{id}/toggle
    final url = Uri.parse('$_baseUrl/goals/$goalId/toggle');
    try {
      final response = await http.patch(url, headers: _getHeaders()); // Body yok
      // print('[API Toggle Goal] URL: $url, Status: ${response.statusCode}'); // Debug
      await _handleResponse(response); // Başarı veya hata kontrolü
    } catch (e) {
      // print("[API Toggle Goal] Error: $e"); // Debug
      throw Exception('Hedef durumu değiştirilemedi: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  /// Bir hedefi API'den siler. Yetkilendirme için userId gerekebilir.
  Future<void> deleteGoal(int goalId, int userId) async {
    // Backend yetkilendirme için userId'yi query parametresi olarak bekliyorsa:
    final url = Uri.parse('$_baseUrl/goals/$goalId?userId=$userId');
    // Veya API token kullanıyorsa: final url = Uri.parse('$_baseUrl/goals/$goalId');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      // print('[API Delete Goal] URL: $url, Status: ${response.statusCode}'); // Debug
      // _handleResponse 204 No Content durumunu da başarı olarak görmeli (null döner)
      await _handleResponse(response);
    } catch (e) {
      // print("[API Delete Goal] Error: $e"); // Debug
      throw Exception('Hedef silinemedi: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }
}