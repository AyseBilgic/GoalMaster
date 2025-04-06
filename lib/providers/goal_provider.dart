// lib/providers/goal_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/goal.dart';

class GoalProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _userId; // Sadece userId tutulur, token AuthProvider'da kalabilir

  List<Goal> get goals => List.unmodifiable(_goals); // Değiştirilemez kopya
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // AuthProvider'dan userId'yi almak için kullanılır (main.dart'taki ProxyProvider ile)
  void updateAuth(String? tokenIgnored, int? userId) {
    bool userChanged = _userId != userId;
    _userId = userId;
    if (userChanged) {
      // print("GoalProvider: User changed to $userId. Clearing goals.");
      _goals = [];
      _errorMessage = null;
      _isLoading = false; // Reset loading state
      notifyListeners(); // Clear UI immediately
      // Eğer yeni kullanıcı giriş yaptıysa, hedefleri otomatik çekebiliriz
      // Ancak bu HomeScreen'in initState'i ile çakışabilir.
      // HomeScreen'in çekmesi daha iyi olabilir.
      // if (_userId != null) fetchGoals(_userId!);
    }
  }

  void _setLoading(bool value) { if (_isLoading == value) return; _isLoading = value; notifyListeners(); }
  void _setError(String? message) { _errorMessage = message; _setLoading(false); notifyListeners(); }

  // Hedefleri API'den çekme
  Future<void> fetchGoals(int userId) async {
    // Yetki kontrolü (Provider'daki userId ile eşleşmeli)
    if (_userId == null || _userId != userId) {
      print("GoalProvider: fetchGoals called with mismatching userId or user not set.");
      _setError("Hedefleri çekmek için yetki hatası.");
      _goals = []; // Güvenlik için listeyi boşalt
      return;
    }
    if (_isLoading) return; // Zaten yükleniyorsa tekrar başlatma

    _setLoading(true); _setError(null); // Yüklemeyi başlat, hatayı temizle
    try {
      _goals = await _apiService.fetchGoals(_userId!);
      _setLoading(false); // Yükleme bitti (notify çağrıldı)
    } catch (error) {
      _setError(error.toString()); // Hata mesajını ayarla (notify çağrıldı)
      _goals = []; // Hata durumunda listeyi boşalt
    }
  }

  // Yeni hedef ekleme
  Future<bool> addGoal(Goal newGoal) async {
    if (_isLoading) return false;
    if (_userId == null) { _setError("Giriş yapılmadı."); return false;}
    // Gönderilecek hedefin userId'sini ayarla
    final goalToSend = Goal( goalId: 0, userId: _userId!, title: newGoal.title, description: newGoal.description, targetDate: newGoal.targetDate, isCompleted: newGoal.isCompleted, category: newGoal.category, progress: newGoal.progress);

    _setLoading(true); _setError(null);
    try {
      await _apiService.addGoal(goalToSend);
      // Başarılı ekleme sonrası listeyi GÜNCELLEMEK İÇİN fetchGoals ÇAĞIR
      await fetchGoals(_userId!); // Bu satır _setLoading(false) ve notifyListeners içerir
      return true; // Başarılı
    } catch (error) {
      _setError(error.toString()); // Hata mesajını ayarla
      return false; // Başarısız
    }
  }

  // Hedef tamamlama durumunu değiştirme
  Future<bool> toggleGoalCompletion(int goalId, int userId) async {
     if (_userId == null || _userId != userId) { _setError("Yetkisiz işlem."); return false; }
    _setError(null); // Eski hatayı temizle

    final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex == -1) { _setError("Güncellenecek hedef bulunamadı."); return false; }

    final originalGoal = _goals[goalIndex];
    final List<Goal> originalGoalsBackup = List.from(_goals); // Yedek al
    final newStatus = !originalGoal.isCompleted;

    // Optimistic UI: Önce arayüzü güncelle
    _goals[goalIndex] = Goal(
        goalId: originalGoal.goalId, userId: originalGoal.userId, title: originalGoal.title,
        description: originalGoal.description, targetDate: originalGoal.targetDate,
        isCompleted: newStatus, category: originalGoal.category,
        progress: newStatus ? 1.0 : 0.0, // Tamamlanınca %100
        createdAt: originalGoal.createdAt, updatedAt: originalGoal.updatedAt);
    notifyListeners();

    // API'yi çağır
    try {
      await _apiService.toggleGoalCompletion(goalId);
      return true; // Başarılı
    } catch (error) {
      _setError("Durum güncellenemedi: $error");
      // Hata olursa UI'ı geri al
      _goals = originalGoalsBackup;
      notifyListeners();
      return false; // Başarısız
    }
  }

  // Hedef silme
  Future<bool> deleteGoal(int goalId, int userId) async {
    if (_userId == null || _userId != userId) { _setError("Yetkisiz işlem."); return false; }
    _setError(null);

    final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex == -1) { _setError("Silinecek hedef bulunamadı."); return false; }

    final List<Goal> originalGoalsBackup = List.from(_goals); // Yedek al
    _goals.removeAt(goalIndex); // Optimistic UI
    notifyListeners();

    try {
       await _apiService.deleteGoal(goalId, userId); // API'yi çağır
       return true; // Başarılı
     }
    catch (error) {
      _setError("Hedef silinemedi: $error");
      _goals = originalGoalsBackup; // Hatada geri al
      notifyListeners();
      return false; // Başarısız
     }
  }
}