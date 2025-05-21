// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async'; // TimeoutException için eklendi
import 'dart:io'; // HttpStatus için
import 'package:flutter/foundation.dart'; // debugPrint için
import 'package:http/http.dart' as http;
import '../models/goal.dart';
import '../models/subtask.dart';
import '../models/reminder.dart';
import '../models/user.dart'; // User modeli için
import '../models/sentiment_result.dart'; // Yeni eklenen SentimentResult modeli

class ApiService {
  // Android emülatörü için localhost IP'si
  // Fiziksel cihazda test ediyorsanız veya farklı bir ağdaysanız,
  // bilgisayarınızın yerel ağ IP adresini kullanın (örn: 192.168.1.X)
  // Backend'inizin çalıştığı portu da ekleyin. Flask loglarından alınan IP ve port:
  static const String _baseUrl = 'http://10.0.2.2:8080/api';

  String? _authToken;
  int? _currentUserId;
  
  get url => null;

  String? getAuthToken() => _authToken; // Token'ı dışarıdan okumak için getter

  // Singleton pattern (isteğe bağlı, Provider ile yönetiliyorsa gerekmeyebilir)
  // static final ApiService _instance = ApiService._internal();
  // factory ApiService() => _instance;
  // ApiService._internal();

  void setAuthToken(String? token) {
    _authToken = token;
    debugPrint("[ApiService] Auth Token set to: ${_authToken == null ? "null" : "********"}");
  }

  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
    debugPrint("[ApiService] Current User ID set to: $_currentUserId");
  }

   Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    } else if (_currentUserId != null) {
        headers['X-User-ID'] = _currentUserId.toString(); // userId'yi header'a ekle
    }
    return headers;
  }

  void _logRequest(String method, String url, {dynamic body}) {
    debugPrint('[API Request] $method $url (User: $_currentUserId)');
    if (body != null && body is! http.MultipartRequest) { // MultipartRequest body'sini loglamak karmaşık olabilir
      try {
        debugPrint('[API Request Body]: ${jsonEncode(body)}');
      } catch (e) {
        debugPrint('[API Request Body]: (Unable to encode - possibly FormData)');
      }
    }
  }

  void _logResponse(String method, String url, http.Response response) {
    debugPrint('[API Response] $method $url - Status: ${response.statusCode} (User: $_currentUserId)');
    if (response.body.isNotEmpty) {
      // Çok uzun yanıtları loglamamak için kısaltma
      // debugPrint('[API Response Body]: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');
    }
  }

  void _logError(String operation, dynamic error, {StackTrace? stackTrace, String? url, String? responseBody}) {
    debugPrint('[API Error] Operation: $operation (User: $_currentUserId)');
    if (url != null) debugPrint('[API Error] URL: $url');
    debugPrint('[API Error] Error: $error');
    if (responseBody != null) debugPrint('[API Error] Response Body: $responseBody');
    if (stackTrace != null) debugPrint('[API StackTrace]: $stackTrace');
  }

  // _handleResponse metodunu buraya, onu kullanan ilk metodun öncesine taşıyalım.
  dynamic _handleResponse(http.Response response, {bool acceptNoContent = false}) {
    final int statusCode = response.statusCode;
    final String responseBody = utf8.decode(response.bodyBytes);
    final bool isJson = response.headers['content-type']?.contains('application/json') ?? false;

    if (statusCode >= 200 && statusCode < 300) { // Başarılı yanıtlar
      if (acceptNoContent && (statusCode == HttpStatus.noContent || responseBody.isEmpty)) {
        return null; // İçerik beklenmiyorsa ve yoksa null dön
      }
      if (responseBody.isEmpty) {
        return {}; // Veya null, API sözleşmesine bağlı
      }
      if (isJson) {
        try {
          return json.decode(responseBody);
        } catch (e) {
          _logError('_handleResponse', 'JSON parse hatası', responseBody: responseBody);
          throw Exception('Sunucudan gelen yanıt parse edilemedi (JSON): $e');
        }
      } else {
        return responseBody;
      }
    }
    // Hata Durumu
    String errorMessage = 'Sunucu hatası: $statusCode.';
    if (isJson && responseBody.isNotEmpty) {
      try {
        final errorData = json.decode(responseBody);
        if (errorData is Map && errorData.containsKey('error')) {
          errorMessage = errorData['error'] is Map ? errorData['error']['message'] ?? errorData['error'].toString() : errorData['error'].toString();
        } else if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'].toString();
        } else if (responseBody.isNotEmpty) {
           errorMessage = responseBody.length > 100 ? '${responseBody.substring(0,100)}...' : responseBody;
        }
      } catch (e) {
        if (responseBody.isNotEmpty) {
          errorMessage = responseBody.length > 100 ? '${responseBody.substring(0,100)}...' : responseBody;
        }
      }
    } else if (responseBody.isNotEmpty) {
       errorMessage = responseBody.length > 100 ? '${responseBody.substring(0,100)}...' : responseBody;
    }
    throw Exception('API Hatası (Status: $statusCode): $errorMessage');
  }

  // --- Auth Metotları ---
  Future<User> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
        final body = {'username': email, 'password': password}; // 'email' anahtarını 'username' yap, parametre adı 'email' kalsa da olur
    _logRequest('POST', url.toString(), body: body);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'}, // Auth gerektirmeyen header
        body: json.encode(body),
      );
      _logResponse('POST', url.toString(), response);

      final contentType = response.headers['content-type'];

      if (response.statusCode == HttpStatus.ok) {
        if (contentType != null && contentType.contains('application/json')) {
          final responseData = json.decode(utf8.decode(response.bodyBytes));
          debugPrint('[ApiService login - 200 OK Decoded ResponseData]: $responseData');
          setAuthToken(responseData['token'] as String?); // setAuthToken ile loglama da yapılır
          final user = User.fromJson(responseData['user']);
          // User.id String ise ve setCurrentUserId int? bekliyorsa parse et
          // user.id'nin null olamayacağını varsayarak (hata mesajına göre String tipinde)
          setCurrentUserId(int.tryParse(user.id));
          return user;
        } else {
          _logError('login', 'Başarılı yanıtta (200 OK) geçersiz format.', url: url.toString(), responseBody: response.body.length > 200 ? '${response.body.substring(0,200)}...' : response.body);
          throw Exception('Sunucudan başarılı yanıt için beklenmedik format alındı.');
        }
      } else {
        // Hatalı durum (404, 500 vb.)
        if (contentType != null && contentType.contains('application/json')) {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(errorData['message'] ?? 'Giriş başarısız oldu: ${response.statusCode}');
        } else {
          // JSON olmayan hata yanıtı (muhtemelen HTML 404 sayfası)
          _logError('login', 'Sunucu hatası, JSON olmayan yanıt.', url: url.toString(), responseBody: response.body.length > 200 ? '${response.body.substring(0,200)}...' : response.body);
          throw Exception('Sunucu hatası: ${response.statusCode}. Lütfen API endpoint adresini ve backend loglarını kontrol edin.');
        }
      }
    } catch (e, s) {
      _logError('login', e, stackTrace: s, url: url.toString());
      // Eğer hata zaten bizim tarafımızdan anlamlı bir şekilde fırlatıldıysa, tekrar sarmalamayalım.
      if (e is Exception && (e.toString().contains("Sunucu hatası") || e.toString().contains("Giriş başarısız oldu") || e.toString().contains("beklenmedik format"))) {
        rethrow; // throw e; yerine rethrow
      } // else
      throw Exception('Giriş işlemi sırasında bir sorun oluştu: $e');
    }
  }

  // Bu register metodu User döndüren ile çakışıyordu, kaldırıldı.
  // AuthProvider'ın User beklediğini varsayarak registerUser metodu kullanılacak.
  /* Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    final body = {'username': username, 'email': email, 'password': password};
    _logRequest('POST', url.toString(), body: body);
    try {
      final response = await http.post( url, headers: {'Content-Type': 'application/json; charset=UTF-8'}, body: json.encode(body),);
      _logResponse('POST', url.toString(), response);

      if (response.statusCode == 201) {
         try {
           final responseData = json.decode(utf8.decode(response.bodyBytes));
           return responseData;
         } catch (e) {
           debugPrint("HATA: register response parse edilemedi: $e");
           throw Exception("register response parse edilemedi: $e");

         }
       }

        _handleResponse(response);
       
    } catch (e, s) { _logError('register', e, stackTrace: s, url: url.toString()); throw Exception('Kayıt sırasında bir hata oluştu: $e');}
     return {};
  } */

  // AuthProvider User beklediği için bu register metodu kalacak.
  Future<User> registerUser(String username, String email, String password) async { // register -> registerUser
    final url = Uri.parse('$_baseUrl/auth/register');
    final body = {'username': username, 'email': email, 'password': password};
    _logRequest('POST', url.toString(), body: body);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(body),
      );
      _logResponse('POST', url.toString(), response);

      if (response.statusCode == HttpStatus.created || response.statusCode == HttpStatus.ok) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        // Genellikle kayıt sonrası kullanıcı bilgisi döner, token dönmeyebilir.
        return User.fromJson(responseData['user'] ?? responseData);
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? 'Kayıt başarısız oldu: ${response.statusCode}');
      }
    } catch (e, s) {
      _logError('registerUser', e, stackTrace: s, url: url.toString());
      throw Exception('Kayıt sırasında bir hata oluştu: $e');
    }
  }

  // --- Goal Metotları ---
  Future<List<Goal>> fetchGoals(int userId) async {
    final url = Uri.parse('$_baseUrl/goals?userId=$userId');
    _logRequest('GET', url.toString());

    try {
      final response = await http.get(url, headers: _getHeaders());
      _logResponse('GET', url.toString(), response);

      if (response.statusCode == HttpStatus.ok) {
        final List<dynamic> goalsJson = json.decode(utf8.decode(response.bodyBytes));
        return goalsJson.map((jsonMap) => Goal.fromJson(jsonMap)).toList();
      } else {
        throw Exception('Hedefler çekilemedi: ${response.statusCode} - ${response.body}');
      }
    } catch (e, s) {
      _logError('fetchGoals', e, stackTrace: s, url: url.toString());
      throw Exception('Hedefler çekilirken bir hata oluştu: $e');
    }
  }

  Future<Goal> addGoal(Goal goal) async {
    final url = Uri.parse('$_baseUrl/goals');
    _logRequest('POST', url.toString(), body: goal.toJson());

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(goal.toJson()),
      );
      _logResponse('POST', url.toString(), response);

      if (response.statusCode == HttpStatus.created || response.statusCode == HttpStatus.ok) {
        return Goal.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Hedef eklenemedi: ${response.statusCode} - ${response.body}');
      }
    } catch (e, s) {
      _logError('addGoal', e, stackTrace: s, url: url.toString());
      throw Exception('Hedef eklenirken bir hata oluştu: $e');
    }
  }

  Future<Goal> updateGoal(Goal goal) async {
    final url = Uri.parse('$_baseUrl/goals/${goal.goalId}');
    _logRequest('PUT', url.toString(), body: goal.toJson());

    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: json.encode(goal.toJson()),
      );
      _logResponse('PUT', url.toString(), response);

      if (response.statusCode == HttpStatus.ok) {
        return Goal.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Hedef güncellenemedi: ${response.statusCode} - ${response.body}');
      }
    } catch (e, s) {
      _logError('updateGoal', e, stackTrace: s, url: url.toString());
      throw Exception('Hedef güncellenirken bir hata oluştu: $e');
    }
  }

   Future<void> deleteGoal(int goalId, {int? userId}) async { // goalId int ve userId nullable int
    userId = userId ?? _currentUserId;
    if (userId == null) throw Exception("Giriş yapılmadı (deleteGoal)");

    final url = Uri.parse('$_baseUrl/goals/$goalId');
    debugPrint("ApiService DELETE: $url (User: $userId)");
    try {
      final response = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 10));
      _handleResponse(response, acceptNoContent: true); // 200 OK veya 204 No Content beklenir
    } on SocketException { throw const SocketException('Sunucuya bağlanılamadı.');
    } on TimeoutException catch (e) { throw Exception('İstek zaman aşımına uğradı: $e');
    } on http.ClientException catch(e){throw Exception("HTTP İstek Hatası:$e");
    } catch (e) {
      if (e is Exception && e.toString().contains("(Status:")) rethrow; // HandleResponse'un hatasını ilet
      throw Exception('Hedef silinemedi: $e.');
    }
  }

   Future<void> toggleGoalCompletion(int goalId, {int? userId}) async {
    userId = userId ?? _currentUserId;
    if (userId == null) throw Exception("toggleGoalCompletion için userId gerekli.");

    final url = Uri.parse('$_baseUrl/goals/$goalId/toggle-completion'); // Backend endpoint'i böyle olmalı
    debugPrint("ApiService PATCH: $url (User: $userId)");

     try { final response = await http.patch(url, headers: _getHeaders() ).timeout(const Duration(seconds: 10)); _handleResponse(response, acceptNoContent: true); }
     catch (e) { debugPrint("API Toggle Goal Error: $e"); rethrow; } // HandleResponse'un hatasını ilet
  }

  // --- Subtask Metotları ---
  Future<List<Subtask>> fetchSubtasksForGoal(int goalId, {int? userId}) async {
    userId = userId ?? _currentUserId;
    if (userId == null) throw Exception("Giriş yapılmadı (fetchSubtasks)");

    final url = Uri.parse('$_baseUrl/goals/$goalId/subtasks?userId=$userId'); // userId parametresi
    debugPrint("ApiService GET: $url");
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      final responseData = _handleResponse(response);

      if (responseData is List) { // Boş liste de gelebilir
           return responseData.map((json) => Subtask.fromJson(json)).toList();
      } else {
          // HATA: Beklenmeyen yanıt formatı
          throw Exception("fetchSubtasksForGoal: Beklenmeyen yanıt formatı (${responseData.runtimeType})");
      }
    } catch (e) {
      debugPrint("API Fetch Subtasks Error: $e");
      // _handleResponse zaten hata fırlatır, burası başka bir hata için
       throw Exception("Alt görevler alınamadı: $e");
    }
  }

  Future<Subtask> addSubtask(Subtask subtask) async {
    if (_currentUserId == null) throw Exception("Giriş yapılmadı (addSubtask)");
    // Alt görevler, ana hedef ID'si (goalId) ile ilişkilendirilmeli
    final url = Uri.parse('$_baseUrl/goals/${subtask.goalId}/subtasks'); // goalId URL'de
    _logRequest('POST', url.toString(), body: subtask.toJson());

    try {
      final response = await http.post(url, headers: _getHeaders(), body: jsonEncode(subtask.toJson())).timeout(const Duration(seconds: 15));
      final responseData = _handleResponse(response);
      if (responseData is Map<String, dynamic>) { // Başarılı yanıt bir Map olmalı
        return Subtask.fromJson(responseData);
      } else {
        throw Exception("addSubtask: Geçersiz API yanıtı (${responseData.runtimeType}). Map bekleniyor.");
      }
    } catch (e, s) {
      _logError('addSubtask', e, stackTrace: s, url: url.toString());
      rethrow; // Hatanın Provider'da işlenmesi için
    }
  }


  Future<Subtask> updateSubtask(Subtask subtask) async {
    if (_currentUserId == null) throw Exception("Giriş yapılmadı");
    if (subtask.id == 0) throw Exception("subtask.id 0 olamaz.");
    final url = Uri.parse('$_baseUrl/subtasks/${subtask.id}');
     _logRequest('PUT', url.toString(), body: subtask.toJson());

    try {
        final response = await http.put(url, headers: _getHeaders(), body: jsonEncode(subtask.toJson())).timeout(const Duration(seconds: 15));
        final responseData = _handleResponse(response);
        if(responseData is Map<String, dynamic>){
            return Subtask.fromJson(responseData);
        }
        throw Exception("updateSubtask: Geçersiz API yanıtı (${responseData.runtimeType})");

    } catch (e, s) {
        _logError('updateSubtask', e, stackTrace: s, url: url.toString());
      rethrow; // Hatanın Provider'da işlenmesi için
    }
  }


  

  // --- Reminder Metotları ---
   Future<List<Reminder>> fetchRemindersForGoal(int goalId) async {
    if (_currentUserId == null) throw Exception("Giriş yapılmadı");
    // Flask: GET /api/reminders?userId=<userId>&goalId=<goalId>
    final uri = Uri.parse('$_baseUrl/reminders').replace(queryParameters: {
      'userId': _currentUserId.toString(),
      'goalId': goalId.toString(),
    });
    _logRequest('GET', uri.toString());

    try {
        final response = await http.get(uri, headers: _getHeaders()).timeout(const Duration(seconds: 15));
        final responseData = _handleResponse(response);

        if (responseData is List<dynamic>) { // Boş liste de gelebilir
           // Backend'den gelen her bir reminder objesinin 'user_id' içerdiğinden emin olun.
           // Reminder.fromJson bunu zaten bekliyor.
           return responseData.map((json) => Reminder.fromJson(json)).toList();
        } else {
           throw Exception("fetchRemindersForGoal: Beklenmeyen yanıt formatı");
        }
    } on SocketException catch (e) { throw Exception('Sunucuya bağlanılamadı: $e');
    } on TimeoutException catch (e) { throw Exception('İstek zaman aşımına uğradı: $e');
    } catch (e, s) { // url yerine uri olmalı
       _logError('fetchRemindersForGoal', e, stackTrace: s, url: url.toString(), responseBody: (e is http.Response) ? e.body : null);
        if (e is Exception && e.toString().contains("(Status:")) rethrow; // handleResponse'dan gelen hata ise rethrow // url yerine uri olmalı
       throw Exception('Hatırlatıcılar yüklenemedi.');
    }
  }


   Future<Reminder> addReminder(Reminder reminder) async {
    if (_currentUserId == null) throw Exception("Giriş yapılmadı (addReminder)");
    // Flask: POST /api/reminders (body'de userId, reminder_time, goal_id, subtask_id, message)
    final url = Uri.parse('$_baseUrl/reminders');
    _logRequest('POST', url.toString(), body: reminder.toJson());
    try {
        final response = await http.post(url, headers: _getHeaders(), body: jsonEncode(reminder.toJson())) .timeout(const Duration(seconds: 15));
      final responseData = _handleResponse(response);
      if(responseData is Map<String, dynamic>){
         return Reminder.fromJson(responseData);
      }
      throw Exception("addReminder: Geçersiz API yanıtı");
    } catch (e, s) { _logError('addReminder', e, stackTrace: s, url: url.toString()); rethrow; }
  }

   Future<Reminder> updateReminder(Reminder reminder) async {
    if (_currentUserId == null) throw Exception("Giriş yapılmadı (updateReminder)");
    if (reminder.reminderId.isEmpty) {
        debugPrint("reminderId cannot be null or empty."); // Daha açıklayıcı debug mesajı
         throw Exception("reminderId cannot be null or empty.");
    }
    final url = Uri.parse('$_baseUrl/reminders/${reminder.reminderId}'); // reminderId eklendi.
    _logRequest('PUT', url.toString(), body: reminder.toJson());
     try {
       final response = await http.put(url, headers: _getHeaders(), body: jsonEncode(reminder.toJson())).timeout(const Duration(seconds: 15));
      final responseData = _handleResponse(response);
      if(responseData is Map<String, dynamic>){
        return Reminder.fromJson(responseData);
      }
      throw Exception("updateReminder: Geçersiz API yanıtı");
    } catch (e, s) {
       _logError('updateReminder', e, stackTrace: s, url: url.toString());
        rethrow;
    }
  }
   Future<void> deleteReminder(String reminderId) async { // reminderId string olabilir
    if (_currentUserId == null) throw Exception("Giriş yapılmadı (deleteReminder)");
    // Flask: DELETE /api/reminders/<reminder_id>?userId=<userId>
    final uri = Uri.parse('$_baseUrl/reminders/$reminderId').replace(queryParameters: {
      'userId': _currentUserId.toString(),
    });
    _logRequest('DELETE', uri.toString());

    try {
      final response = await http.delete(uri, headers: _getHeaders()).timeout(const Duration(seconds: 15));
       _handleResponse(response, acceptNoContent: true);
    } catch (e, s) {
        _logError('deleteReminder', e, stackTrace: s, url: url.toString());
         rethrow;
    }
  }

  // --- AI Suggestion Metotları ---
  Future<List<String>> getGoalSuggestions(int goalId) async {
    if (_currentUserId == null) throw Exception("Giriş yapılmadı");
    // Flask: GET /api/goals/<goal_id>/suggest (userId header veya query'den alınır)
    final url = Uri.parse('$_baseUrl/goals/$goalId/suggest');
    _logRequest('GET', url.toString());
    try {
      final response = await http.get(url, headers: _getHeaders());
      _logResponse('GET', url.toString(), response);
      final responseData = _handleResponse(response);
      if (responseData is List) { // Öneri listesi döndüğünü varsayalım
        return responseData.cast<String>(); // String listesine dönüştür
      } else if (responseData is Map && responseData.containsKey('suggestions')) {
        return List<String>.from(responseData['suggestions']); // 'suggestions' anahtarını kontrol et
      } else {
        debugPrint("Warning: Unexpected suggestion response format: $responseData");
        throw Exception('API öneri yanıtı beklenmedik formatta.');
      }
    } catch (e, s) {
        _logError('getGoalSuggestions', e, stackTrace: s, url: url.toString());
      throw Exception('Öneriler alınamadı: $e');
    }
  }

  // --- AI Sentiment Analysis Metotları ---
  Future<SentimentResult> analyzeTextSentiment(String text) async {
    if (_currentUserId == null) throw Exception("Duygu analizi için giriş yapılmadı.");
    // Backend endpoint'inizi buraya göre ayarlayın, örneğin: /ai/sentiment/analyze
    final url = Uri.parse('$_baseUrl/ai/sentiment/analyze');
    final body = {'text': text};
    _logRequest('POST', url.toString(), body: body);

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(), // Auth token gerektirebilir
        body: json.encode(body),
      ).timeout(const Duration(seconds: 20)); // API yanıt süresine göre timeout ayarlayın

      final responseData = _handleResponse(response);
      if (responseData is Map<String, dynamic>) {
        return SentimentResult.fromJson(responseData);
      }
      throw Exception("analyzeTextSentiment: Geçersiz API yanıtı (${responseData.runtimeType}). Map bekleniyor.");
    } catch (e, s) {
      _logError('analyzeTextSentiment', e, stackTrace: s, url: url.toString());
      rethrow; // Hatanın daha üst katmanlarda (Provider gibi) işlenmesi için
    }
  }

  // --- Subtask Metotları (deleteSubtask için userId query parametresi) ---
   Future<void> deleteSubtask(int subtaskId) async {
    if (_currentUserId == null) throw Exception("Giriş yapılmadı (deleteSubtask)");
    // Flask: DELETE /api/subtasks/<subtask_id>?userId=<userId>
    final uri = Uri.parse('$_baseUrl/subtasks/$subtaskId').replace(queryParameters: {
      'userId': _currentUserId.toString(),
    });
    _logRequest('DELETE', uri.toString());
    try {
        final response = await http.delete(uri, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      _handleResponse(response, acceptNoContent: true); // 200 OK veya 204 No Content
    } catch (e, s) {
        _logError('deleteSubtask', e, stackTrace: s, url: uri.toString());
      rethrow; // Hatanın Provider'da işlenmesi için
    }
  }
}
