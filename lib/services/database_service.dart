import 'package:mysql1/mysql1.dart';
import 'package:flutter_application1/models/goal.dart';

class DatabaseService {
  // SingleStore bağlantı bilgileri (GÜVENLİ BİR YERDE SAKLA!)
  final String _host = 'svc-3482219c-a389-4079-b18b-d50662524e8a-shared-dml.aws-virginia-6.svc.singlestore.com';
  final int _port = 3333;
  final String _user = 'ayşe-bilgic';
  final String _password = 'NE3pVe8l4TcUW2cQi9mAb20VbtvbUmZb';
  final String _db = 'db_aye_48fa1';

  Future<MySqlConnection> _createConnection() async {
    return await MySqlConnection.connect(ConnectionSettings(
      host: _host,
      port: _port,
      user: _user,
      password: _password,
      db: _db,
    ));
  }

  Future<List<Goal>> getGoals() async {
    MySqlConnection? connection;
    try {
      connection = await _createConnection();
      final results = await connection.query('SELECT * FROM goals');

      return results.map((row) => Goal(
        id: row['id'].toString(),
        title: row['title'],
        description: row['description'],
        dueDate: row['dueDate'],
        category: row['category'],
        isCompleted: row['isCompleted'] == 1,
      )).toList();
    } catch (e) {
      throw Exception("Hedefler çekilemedi: $e");
    } finally {
      await connection?.close();
    }
  }

  Future<String?> addGoal(Goal goal) async {
    MySqlConnection? connection;
    try {
      connection = await _createConnection();
      final result = await connection.query(
        'INSERT INTO goals (id, title, description, dueDate, category, isCompleted) VALUES (?, ?, ?, ?, ?, ?)',
        [goal.id, goal.title, goal.description, goal.dueDate, goal.category, goal.isCompleted],
      );
      return result.insertId?.toString();
    } catch (e) {
      throw Exception("Hedef eklenemedi: $e");
    } finally {
      await connection?.close();
    }
  }

  Future<void> updateGoal(Goal goal) async {
    MySqlConnection? connection;
    try {
      connection = await _createConnection();
      await connection.query(
        'UPDATE goals SET title = ?, description = ?, dueDate = ?, category = ?, isCompleted = ? WHERE id = ?',
        [goal.title, goal.description, goal.dueDate, goal.category, goal.isCompleted, goal.id],
      );
    } catch (e) {
      throw Exception("Hedef güncellenemedi: $e");
    } finally {
      await connection?.close();
    }
  }

  Future<void> deleteGoal(String id) async {
    MySqlConnection? connection;
    try {
      connection = await _createConnection();
      await connection.query('DELETE FROM goals WHERE id = ?', [id]);
    } catch (e) {
      throw Exception("Hedef silinemedi: $e");
    } finally {
      await connection?.close();
    }
  }

  Future<void> toggleComplete(String id) async {
    MySqlConnection? connection;
    try {
      connection = await _createConnection();
      final result = await connection.query(
        'SELECT isCompleted FROM goals WHERE id = ?',
        [id]
      );
      
      if (result.isEmpty) throw Exception('Hedef bulunamadı');
      final currentStatus = result.first['isCompleted'] == 1;
      
      await connection.query(
        'UPDATE goals SET isCompleted = ? WHERE id = ?',
        [!currentStatus, id]
      );
    } catch (e) {
      throw Exception("Durum değiştirilemedi: $e");
    } finally {
      await connection?.close();
    }
  }

  Future<Goal?> getGoalById(String id) async {
    MySqlConnection? connection;
    try {
      connection = await _createConnection();
      final result = await connection.query(
        'SELECT * FROM goals WHERE id = ?',
        [id]
      );
      
      if (result.isNotEmpty) {
        final row = result.first;
        return Goal(
          id: row['id'].toString(),
          title: row['title'],
          description: row['description'],
          dueDate: row['dueDate'],
          category: row['category'],
          isCompleted: row['isCompleted'] == 1,
        );
      }
      return null;
    } catch (e) {
      throw Exception("Hedef getirilemedi: $e");
    } finally {
      await connection?.close();
    }
  }
}