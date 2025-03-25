import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Backend API'nin adresi
  final String _baseUrl = 'http://192.168.255.91:8080'; // VEYA 'http://127.0.0.1:8080'

  Future<String?> login(String username, String password) async {
    print('Login isteği gönderiliyor...'); // Ekle

    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    print('Login isteği cevabı: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user_id']; // Flask'tan gelen cevaba göre ayarla!
    } else {
      print('Login failed: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  Future<String?> register(String username, String password, String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'email': email}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['user_id']; // Flask'tan gelen cevaba göre ayarla!
    } else if (response.statusCode == 409) {
      throw Exception('Username already exists');
    } else {
      print('Register failed: ${response.statusCode} - ${response.body}');
      return null;
    }
  }
}