// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io'; // Platformu kontrol et
import 'package:http/http.dart' as http;
import '../models/goal.dart'; // Kendi Goal modelimiz

class ApiService {
  // Backend API URL'si (Emulator veya fiziksel cihaz için ayarlı)
  final String _baseUrl = Platform.isAndroid ? 'http://10.0.2.2:8080/api' : 'http://localhost:8080/api';

  // --- AUTH Endpoints ---
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(url, headers: _headers(), body: jsonEncode({'username': username, 'email': email, 'password': password}),);
      // print('API Register Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) { throw Exception('Kayıt başarısız: Ağ hatası veya sunucuya ulaşılamadı.'); }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/login');
     try {
      final response = await http.post(url, headers: _headers(), body: jsonEncode({'username': username, 'password': password}),);
      // print('API Login Status: ${response.statusCode}');
      return _handleResponse(response);
     } catch (e) { throw Exception('Giriş başarısız: Ağ hatası veya sunucuya ulaşılamadı.');}
  }

  // --- GOAL Endpoints ---
  Future<List<Goal>> fetchGoals(int userId) async {
    // Backend API endpoint: GET /api/goals?userId={userId}
    final url = Uri.parse('$_baseUrl/goals?userId=$userId');
     try {
        final response = await http.get(url, headers: _headers());
        // print('API Fetch Goals Status: ${response.statusCode}');
        final responseData = _handleResponse(response);
        // Gelen liste boş olsa bile hata vermemeli, boş liste dönmeli
        if (responseData is List) {
           return responseData.map((json) => Goal.fromJson(json)).toList();
        } else {
           print("API Fetch Goals: Unexpected response format. Expected a List.");
           return []; // Beklenmedik formatta boş liste dön
        }
     } catch (e) { throw Exception('Hedefler alınamadı: $e');}
  }

  Future<Goal> addGoal(Goal goal) async {
    final url = Uri.parse('$_baseUrl/goals'); // POST /api/goals
     try {
        final response = await http.post(url, headers: _headers(), body: jsonEncode(goal.toJson()));
        // print('API Add Goal Status: ${response.statusCode}');
        final responseData = _handleResponse(response);
        // API, oluşturulan hedefi (ID'si ile birlikte) dönmeli
        return Goal.fromJson(responseData);
     } catch (e) { throw Exception('Hedef eklenemedi: $e');}
  }

  // Hedefin tamamını güncellemek için PUT kullanılabilir (backend destekliyorsa)
  Future<void> updateGoal(Goal goal) async {
    final url = Uri.parse('$_baseUrl/goals/${goal.goalId}'); // PUT /api/goals/{id}
     try {
      final response = await http.put(url, headers: _headers(), body: jsonEncode(goal.toJson()));
      _handleResponse(response); // Başarılı ise 200 OK döner genelde
     } catch (e) { throw Exception('Hedef güncellenemedi: $e');}
  }

   // Sadece tamamlanma durumunu değiştirmek için PATCH
   Future<void> toggleGoalCompletion(int goalId) async {
     final url = Uri.parse('$_baseUrl/goals/$goalId/toggle'); // PATCH /api/goals/{id}/toggle
     try {
       final response = await http.patch(url, headers: _headers()); // Body göndermeye gerek yok
      _handleResponse(response); // Başarılı ise 200 OK döner
     } catch (e) { throw Exception('Durum değiştirilemedi: $e');}
   }

  Future<void> deleteGoal(int goalId, int userId) async {
    // Yetkilendirme için userId query parametresi olarak gönderiliyor
    final url = Uri.parse('$_baseUrl/goals/$goalId?userId=$userId'); // DELETE /api/goals/{id}?userId={userId}
     try {
      final response = await http.delete(url, headers: _headers());
      // Başarılı silme 200 OK veya 204 No Content dönebilir
      if (response.statusCode != 200 && response.statusCode != 204) {
         // Eğer _handleResponse 204'ü hata olarak görüyorsa burayı ayarlamamız gerekir.
         // Şimdilik _handleResponse'a bırakalım.
          _handleResponse(response);
      }
      // print("Goal $goalId deleted successfully via API.");
     } catch (e) { throw Exception('Hedef silinemedi: $e'); }
  }

  // --- Yardımcılar ---
  Map<String, String> _headers() {
    // Gerekirse Auth token gibi başlıkları buraya ekle
    return {'Content-Type': 'application/json'};
  }

   dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    // UTF-8 decoding ile Türkçe karakter sorunlarını çöz
    final responseBody = utf8.decode(response.bodyBytes);

    try {
        // Yanıt boşsa (örn: 204 No Content) ama başarılıysa null dön
         if (responseBody.isEmpty) {
             if (statusCode >= 200 && statusCode < 300) return null;
             else throw Exception('Boş yanıt (Status: $statusCode)');
         }
         // Yanıtı JSON olarak decode etmeyi dene
         final responseData = jsonDecode(responseBody);

        // Başarılı durum kodları
        if (statusCode >= 200 && statusCode < 300) {
          return responseData;
        }
        // Bilinen hata durum kodları için API'den gelen mesajı kullan
        else {
           throw Exception('${responseData['error'] ?? responseBody} (Status: $statusCode)');
        }
    } catch(e) { // jsonDecode hatası veya yukarıdaki throw
         // print("Error decoding JSON or handling response: $e, Body: $responseBody");
         // Hata durumunda daha genel bir mesaj veya orijinal hata
         throw Exception('Sunucu yanıtı işlenemedi veya beklenmedik format (Status: $statusCode)');
    }
  }
}