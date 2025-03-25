import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application1/models/goal.dart';

class GoalService {
  final String _baseUrl = 'http://192.168.255.91:8080'; // VEYA 'http://127.0.0.1:8080'

  Future<List<Goal>> getGoals() async {
    final response = await http.get(Uri.parse('$_baseUrl/goals'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Goal.fromJson(json)).toList();
    } else {
      throw Exception('Hedefler yüklenemedi. Hata Kodu: ${response.statusCode}');
    }
  }

    Future<Goal> addGoal(Goal goal) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/goals'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(goal.toJson()),
    );

    if (response.statusCode == 201) { // 201 Created
      return Goal.fromJson(jsonDecode(utf8.decode(response.bodyBytes))); // UTF-8
    } else {
      throw Exception('Hedef eklenemedi. Hata kodu: ${response.statusCode}');
    }
  }


  Future<void> updateGoal(Goal goal) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/goals/${goal.id}'), //  /goals/{id}
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(goal.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Hedef güncellenemedi. Hata Kodu: ${response.statusCode}');
    }
  }

  Future<void> deleteGoal(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/goals/$id'));
    if (response.statusCode != 200) {
      throw Exception("Hedef Silinemedi. Hata Kodu: ${response.statusCode}");
    }
  }

    Future<void> toggleComplete(String id) async{
        // /goals/{id}/toggle_complete  endpoint'i (Flask Tarafında)
         final response = await http.patch(  //veya PUT
           Uri.parse('$_baseUrl/goals/$id/toggle_complete'),
             headers: {'Content-Type': 'application/json'},
         );
        if(response.statusCode != 200){
            throw Exception("Tamamlanma durumu değiştirilemedi. Hata Kodu: ${response.statusCode}");
        }
    }
}