// lib/providers/goal_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/goal.dart';
import '../models/subtask.dart';
import '../models/reminder.dart';

class GoalProvider with ChangeNotifier {
  final ApiService _apiService = ApiService(); // ApiService örneği

  // --- Ana Hedefler State ---
  List<Goal> _goals = [];
  bool _isLoadingGoals = false;
  String? _goalError; // Genel hedef işlemleri için hata mesajı

  // --- Alt Görevler State (Hedef ID'sine göre) ---
  final Map<int, List<Subtask>> _subtasksByGoalId = {};
  final Map<int, bool> _isLoadingSubtasksForGoal = {};
  final Map<int, String?> _subtaskErrorForGoal = {};

  // --- Hatırlatıcılar State (Hedef ID'sine göre) ---
  final Map<int, List<Reminder>> _remindersByGoalId = {};
  final Map<int, bool> _isLoadingRemindersForGoal = {};
  final Map<int, String?> _reminderErrorForGoal = {};

  // --- AI Önerileri State (Hedef ID'sine göre) ---
  final Map<int, List<String>> _suggestionsByGoalId = {};
  final Map<int, bool> _isLoadingSuggestionsForGoal = {};
  final Map<int, String?> _suggestionErrorForGoal = {};

  int? _userId;

  // --- Public Getters ---
  List<Goal> get goals => List.unmodifiable(_goals);
  bool get isLoadingGoals => _isLoadingGoals;
  String? get goalError => _goalError;

  List<Subtask> getSubtasksFor(int goalId) => List.unmodifiable(_subtasksByGoalId[goalId] ?? []);
  bool isLoadingSubtasksFor(int goalId) => _isLoadingSubtasksForGoal[goalId] ?? false;
  String? getSubtaskErrorFor(int goalId) => _subtaskErrorForGoal[goalId];

  List<Reminder> getRemindersFor(int goalId) => List.unmodifiable(_remindersByGoalId[goalId] ?? []);
  bool isLoadingRemindersFor(int goalId) => _isLoadingRemindersForGoal[goalId] ?? false;
  String? getReminderErrorFor(int goalId) => _reminderErrorForGoal[goalId];

  List<String> getSuggestionsForGoal(int goalId) => List.unmodifiable(_suggestionsByGoalId[goalId] ?? []);
  bool isSuggestionLoading(int goalId) => _isLoadingSuggestionsForGoal[goalId] ?? false;
  String? getSuggestionError(int goalId) => _suggestionErrorForGoal[goalId];

  // --- Auth Entegrasyonu ---
  void updateAuth(String? token, int? userId) { // Token şimdilik kullanılmıyor ama ileride gerekebilir
    bool userChanged = _userId != userId;
    _userId = userId;
    _apiService.setCurrentUserId(userId); // ApiService'i de güncelle
    _apiService.setAuthToken(token);      // ApiService'i de güncelle

    if (userChanged) {
      _resetState();
      if (_userId != null) {
        debugPrint("[GoalProvider] User ID set to $_userId. Fetching initial goals.");
        fetchGoals(_userId!);
      } else {
        debugPrint("[GoalProvider] User logged out. State reset.");
      }
    }
  }

  void _resetState() {
    _goals = [];
    _isLoadingGoals = false;
    _goalError = null;
    _subtasksByGoalId.clear();
    _isLoadingSubtasksForGoal.clear();
    _subtaskErrorForGoal.clear();
    _remindersByGoalId.clear();
    _isLoadingRemindersForGoal.clear();
    _reminderErrorForGoal.clear();
    _suggestionsByGoalId.clear();
    _isLoadingSuggestionsForGoal.clear();
    _suggestionErrorForGoal.clear();
    notifyListeners();
  }

  // --- Helper Metotlar (State Güncelleme) ---
  void _setLoading(bool loading, {String? type, int? goalId}) {
    switch (type) {
      case 'goals': _isLoadingGoals = loading; break;
      case 'subtasks': if (goalId != null) _isLoadingSubtasksForGoal[goalId] = loading; break;
      case 'reminders': if (goalId != null) _isLoadingRemindersForGoal[goalId] = loading; break;
      case 'suggestions': if (goalId != null) _isLoadingSuggestionsForGoal[goalId] = loading; break;
    }
    notifyListeners();
  }

  void _setError(String? error, {String? type, int? goalId}) {
    final errorMessage = error?.replaceFirst("Exception: ", "");
    switch (type) {
      case 'goals': _goalError = errorMessage; if (_isLoadingGoals) _isLoadingGoals = false; break;
      case 'subtasks': if (goalId != null) { _subtaskErrorForGoal[goalId] = errorMessage; if (_isLoadingSubtasksForGoal[goalId] == true) _isLoadingSubtasksForGoal[goalId] = false; } break;
      case 'reminders': if (goalId != null) { _reminderErrorForGoal[goalId] = errorMessage; if (_isLoadingRemindersForGoal[goalId] == true) _isLoadingRemindersForGoal[goalId] = false; } break;
      case 'suggestions': if (goalId != null) { _suggestionErrorForGoal[goalId] = errorMessage; if (_isLoadingSuggestionsForGoal[goalId] == true) _isLoadingSuggestionsForGoal[goalId] = false; } break;
    }
    notifyListeners();
  }

  // --- Ana Hedef Metotları ---
  Future<void> fetchGoals(int userId) async {
    if (_userId != userId) {
      _setError("Geçersiz kullanıcı. Hedefler çekilemiyor.", type: 'goals');
      return;
    }
    _setLoading(true, type: 'goals');
    _setError(null, type: 'goals');
    try {
      _goals = await _apiService.fetchGoals(userId);
      for (var goal in _goals) { // API'den gelen alt görev ve hatırlatıcıları da state'e ekle
        _subtasksByGoalId[goal.goalId] = List.from(goal.subtasks);
        _remindersByGoalId[goal.goalId] = List.from(goal.reminders);
      }
    } catch (e) {
      _setError(e.toString(), type: 'goals');
      _goals = []; // Hata durumunda listeyi boşalt
    } finally {
      _setLoading(false, type: 'goals');
    }
  }

  Future<Goal?> addGoal(Goal newGoal) async {
    if (_userId == null) { _setError("Hedef eklemek için giriş yapılmalı.", type: 'goals'); return null; }
    _setLoading(true, type: 'goals'); // Genel bir yükleme durumu
    _setError(null, type: 'goals');
    try {
      final goalToAdd = newGoal.copyWith(userId: _userId, goalId: 0);
      final addedGoal = await _apiService.addGoal(goalToAdd);
      _goals.add(addedGoal);
      _subtasksByGoalId[addedGoal.goalId] = []; // Yeni hedef için boş listeler
      _remindersByGoalId[addedGoal.goalId] = [];
      _suggestionsByGoalId[addedGoal.goalId] = [];
      notifyListeners();
      return addedGoal;
    } catch (e) {
      _setError(e.toString(), type: 'goals');
      return null;
    } finally {
      _setLoading(false, type: 'goals');
    }
  }

  Future<bool> updateGoal(Goal goalToUpdate) async {
    if (_userId == null) { _setError("Hedef güncellemek için giriş yapılmalı.", type: 'goals'); return false; }
    // _setLoading(true, type: 'goals'); // Ayrı bir _isUpdatingGoal state'i daha iyi olabilir
    _setError(null, type: 'goals');
    try {
      final updatedGoal = await _apiService.updateGoal(goalToUpdate.copyWith(userId: _userId));
      final index = _goals.indexWhere((g) => g.goalId == updatedGoal.goalId);
      if (index != -1) {
        _goals[index] = updatedGoal;
        // Alt görev ve hatırlatıcılar API'den güncel geliyorsa onları da güncelle
        _subtasksByGoalId[updatedGoal.goalId] = List.from(updatedGoal.subtasks);
        _remindersByGoalId[updatedGoal.goalId] = List.from(updatedGoal.reminders);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString(), type: 'goals');
      return false;
    }
    // finally { _setLoading(false, type: 'goals'); }
  }

  Future<bool> deleteGoal(int goalId, int currentUserId) async {
    if (_userId != currentUserId) { _setError("Yetkisiz işlem.", type: 'goals'); return false; }
    final originalGoals = List<Goal>.from(_goals);
    _goals.removeWhere((g) => g.goalId == goalId);
    notifyListeners(); // Optimistic UI
    try {
      await _apiService.deleteGoal(goalId);
      _subtasksByGoalId.remove(goalId); // İlgili alt verileri de temizle
      _remindersByGoalId.remove(goalId);
      _suggestionsByGoalId.remove(goalId);
      return true;
    } catch (e) {
      _setError(e.toString(), type: 'goals');
      _goals = originalGoals; // Hata durumunda geri al
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleGoalCompletion(int goalId, int currentUserId) async {
    if (_userId != currentUserId) { _setError("Yetkisiz işlem.", type: 'goals'); return false; }
    final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex == -1) { _setError("Hedef bulunamadı.", type: 'goals'); return false; }

    final originalGoal = _goals[goalIndex];
    final newStatus = !originalGoal.isCompleted;
    final updatedGoal = originalGoal.copyWith(
      isCompleted: newStatus,
      progress: newStatus ? 1.0 : (originalGoal.progress == 1.0 ? 0.0 : originalGoal.progress),
      updatedAt: DateTime.now(),
    );
    _goals[goalIndex] = updatedGoal;
    notifyListeners(); // Optimistic UI

    try {
      await _apiService.toggleGoalCompletion(goalId);
      return true;
    } catch (e) {
      _setError(e.toString(), type: 'goals');
      _goals[goalIndex] = originalGoal; // Hata durumunda geri al
      notifyListeners();
      return false;
    }
  }

  // --- Alt Görev Metotları ---
  Future<void> fetchSubtasksForGoal(int goalId) async {
    if (_userId == null) { _setError("Giriş yapılmalı.", type: 'subtasks', goalId: goalId); return; }
    if (_isLoadingSubtasksForGoal[goalId] == true) return;
    _setLoading(true, type: 'subtasks', goalId: goalId);
    _setError(null, type: 'subtasks', goalId: goalId);
    try {
      _subtasksByGoalId[goalId] = await _apiService.fetchSubtasksForGoal(goalId);
    } catch (e) {
      _setError(e.toString(), type: 'subtasks', goalId: goalId);
      _subtasksByGoalId[goalId] = [];
    } finally {
      _setLoading(false, type: 'subtasks', goalId: goalId);
    }
  }

  Future<bool> addSubtaskToGoal(int goalId, Subtask subtaskData) async {
    if (_userId == null) { _setError("Giriş yapılmalı.", type: 'subtasks', goalId: goalId); return false; }
    _setError(null, type: 'subtasks', goalId: goalId); // Önceki hatayı temizle
    try {
      final subtaskToSend = subtaskData.copyWith(userId: _userId!, goalId: goalId);
      final newSubtask = await _apiService.addSubtask(subtaskToSend);
      _subtasksByGoalId.putIfAbsent(goalId, () => []).add(newSubtask);
      _updateGoalInListWithNewSubtask(goalId, newSubtask);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString(), type: 'subtasks', goalId: goalId);
      return false;
    }
  }

  Future<bool> toggleSubtaskCompletion(int goalId, int subtaskId) async {
    // ... (Bir önceki cevaptaki gibi, _subtasksByGoalId ve _goals[goalIndex].subtasks güncellenmeli)
    // Hata yönetimi ve optimistic UI için benzer bir yapı kurulmalı.
    // Bu metodun detaylı implementasyonu için önceki cevaplara bakılabilir.
    // Şimdilik kısa kesiyorum.
    final subtasks = _subtasksByGoalId[goalId];
    if (subtasks == null) return false;
    final subtaskIndex = subtasks.indexWhere((s) => s.id == subtaskId);
    if (subtaskIndex == -1) return false;

    final originalSubtask = subtasks[subtaskIndex];
    final updatedSubtask = originalSubtask.copyWith(isCompleted: !originalSubtask.isCompleted);
    subtasks[subtaskIndex] = updatedSubtask;
    _updateGoalInListWithUpdatedSubtask(goalId, updatedSubtask);
    notifyListeners();

    try {
      await _apiService.updateSubtask(updatedSubtask);
      return true;
    } catch (e) {
      subtasks[subtaskIndex] = originalSubtask; // Geri al
      _updateGoalInListWithUpdatedSubtask(goalId, originalSubtask);
      _setError(e.toString(), type: 'subtasks', goalId: goalId);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSubtaskFromGoal(int goalId, int subtaskId) async {
    // ... (Bir önceki cevaptaki gibi)
    // Bu metodun detaylı implementasyonu için önceki cevaplara bakılabilir.
    final subtasks = _subtasksByGoalId[goalId];
    if (subtasks == null) return false;
    final originalSubtasks = List<Subtask>.from(subtasks);
    subtasks.removeWhere((s) => s.id == subtaskId);
    _updateGoalInListByRemovingSubtask(goalId, subtaskId);
    notifyListeners();

    try {
      await _apiService.deleteSubtask(subtaskId);
      return true;
    } catch (e) {
      _subtasksByGoalId[goalId] = originalSubtasks; // Geri al
      _updateGoalInListWithFullSubtasks(goalId, originalSubtasks);
      _setError(e.toString(), type: 'subtasks', goalId: goalId);
      notifyListeners();
      return false;
    }
  }

  // --- Hatırlatıcı Metotları ---
  // fetchRemindersForGoal, addReminderToGoal, deleteReminderFromGoal metodları
  // alt görev metodlarına benzer şekilde implemente edilecek.
  // Örnek:
  Future<void> fetchRemindersForGoal(int goalId) async {
    if (_userId == null) { _setError("Giriş yapılmalı.", type: 'reminders', goalId: goalId); return; }
    if (_isLoadingRemindersForGoal[goalId] == true) return;
    _setLoading(true, type: 'reminders', goalId: goalId);
    _setError(null, type: 'reminders', goalId: goalId);
    try {
      _remindersByGoalId[goalId] = await _apiService.fetchRemindersForGoal(goalId);
    } catch (e) {
      _setError(e.toString(), type: 'reminders', goalId: goalId);
      _remindersByGoalId[goalId] = [];
    } finally {
      _setLoading(false, type: 'reminders', goalId: goalId);
    }
  }

   Future<bool> addReminderToGoal(int goalId, Reminder reminderData) async {
    if (_userId == null) { _setError("Giriş yapılmalı.", type: 'reminders', goalId: goalId); return false; }
    _setError(null, type: 'reminders', goalId: goalId);
    try {
      final reminderToSend = reminderData.copyWith(userId: _userId!, goalId: goalId);
      final newReminder = await _apiService.addReminder(reminderToSend);
      _remindersByGoalId.putIfAbsent(goalId, () => []).add(newReminder);
      _updateGoalInListWithNewReminder(goalId, newReminder);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString(), type: 'reminders', goalId: goalId);
      return false;
    }
  }

  Future<bool> deleteReminderFromGoal(int goalId, String reminderId) async {
    final reminders = _remindersByGoalId[goalId];
    if (reminders == null) return false;
    final originalReminders = List<Reminder>.from(reminders);
    reminders.removeWhere((r) => r.reminderId == reminderId);
    _updateGoalInListByRemovingReminder(goalId, reminderId);
    notifyListeners();

    try {
      await _apiService.deleteReminder(reminderId);
      return true;
    } catch (e) {
      _remindersByGoalId[goalId] = originalReminders;
      _updateGoalInListWithFullReminders(goalId, originalReminders);
      _setError(e.toString(), type: 'reminders', goalId: goalId);
      notifyListeners();
      return false;
    }
  }

  // --- AI Öneri Metotları ---
  Future<void> fetchGoalSuggestions(int goalId) async {
    if (_userId == null) { _setError("Giriş yapılmalı.", type: 'suggestions', goalId: goalId); return; }
    if (_isLoadingSuggestionsForGoal[goalId] == true) return;
    _setLoading(true, type: 'suggestions', goalId: goalId);
    _setError(null, type: 'suggestions', goalId: goalId);
    try {
      _suggestionsByGoalId[goalId] = await _apiService.getGoalSuggestions(goalId);
    } catch (e) {
      _setError(e.toString(), type: 'suggestions', goalId: goalId);
      _suggestionsByGoalId[goalId] = [];
    } finally {
      _setLoading(false, type: 'suggestions', goalId: goalId);
    }
  }

  // --- Ana _goals listesini güncellemek için yardımcı metodlar ---
  void _updateGoalInListWithNewSubtask(int goalId, Subtask newSubtask) {
    final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex != -1) {
      final updatedSubtasks = List<Subtask>.from(_goals[goalIndex].subtasks)..add(newSubtask);
      _goals[goalIndex] = _goals[goalIndex].copyWith(subtasks: updatedSubtasks);
    }
  }
   void _updateGoalInListWithUpdatedSubtask(int goalId, Subtask updatedSubtask) {
    final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex != -1) {
      final subtaskIndexInGoal = _goals[goalIndex].subtasks.indexWhere((s) => s.id == updatedSubtask.id);
      if (subtaskIndexInGoal != -1) {
        final updatedSubtasks = List<Subtask>.from(_goals[goalIndex].subtasks);
        updatedSubtasks[subtaskIndexInGoal] = updatedSubtask;
        _goals[goalIndex] = _goals[goalIndex].copyWith(subtasks: updatedSubtasks);
      }
    }
  }
  void _updateGoalInListByRemovingSubtask(int goalId, int subtaskId) {
     final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex != -1) {
      final updatedSubtasks = List<Subtask>.from(_goals[goalIndex].subtasks)..removeWhere((s) => s.id == subtaskId);
      _goals[goalIndex] = _goals[goalIndex].copyWith(subtasks: updatedSubtasks);
    }
  }
   void _updateGoalInListWithFullSubtasks(int goalId, List<Subtask> subtasks) {
    final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex != -1) {
      _goals[goalIndex] = _goals[goalIndex].copyWith(subtasks: List.from(subtasks));
    }
  }

  void _updateGoalInListWithNewReminder(int goalId, Reminder newReminder) {
    final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex != -1) {
      final updatedReminders = List<Reminder>.from(_goals[goalIndex].reminders)..add(newReminder);
      _goals[goalIndex] = _goals[goalIndex].copyWith(reminders: updatedReminders);
    }
  }
  void _updateGoalInListByRemovingReminder(int goalId, String reminderId) {
    final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex != -1) {
      final updatedReminders = List<Reminder>.from(_goals[goalIndex].reminders)..removeWhere((r) => r.reminderId == reminderId);
      _goals[goalIndex] = _goals[goalIndex].copyWith(reminders: updatedReminders);
    }
  }
  void _updateGoalInListWithFullReminders(int goalId, List<Reminder> reminders) {
    final goalIndex = _goals.indexWhere((g) => g.goalId == goalId);
    if (goalIndex != -1) {
      _goals[goalIndex] = _goals[goalIndex].copyWith(reminders: List.from(reminders));
    }
  }
}