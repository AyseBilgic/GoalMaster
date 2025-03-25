import 'package:flutter/material.dart';
import 'package:flutter_application1/models/goal.dart';
import 'package:flutter_application1/services/goal_service.dart'; // GoalService import edildi

class GoalProvider with ChangeNotifier {
  final GoalService _goalService = GoalService(); // GoalService kullanılıyor
  List<Goal> _goals = [];

  List<Goal> get goals => _goals;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
  }

  Future<void> fetchGoals() async {
    clearError();
    _isLoading = true;
    notifyListeners();

    try {
      _goals = await _goalService.getGoals(); // GoalService'den çek
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGoal(Goal goal) async {
    clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final addedGoal = await _goalService.addGoal(goal); // GoalService ile ekle
      _goals.add(addedGoal);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGoal(Goal updatedGoal) async {
    clearError();
    _isLoading = true;
    notifyListeners();

    try {
      await _goalService.updateGoal(updatedGoal); // GoalService ile güncelle
      final index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
      if (index != -1) {
        _goals[index] = updatedGoal;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    clearError();
    _isLoading = true;
    notifyListeners();

    try {
      await _goalService.deleteGoal(id); // GoalService ile sil
      _goals.removeWhere((element) => element.id == id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> toggleComplete(String id) async { //GoalService ile
    clearError();
      try {
      await _goalService.toggleComplete(id); //Database'de değiştir.
           //Lokal Listeyi Güncelle
          final index = _goals.indexWhere((g) => g.id == id);
          if(index != -1){
            _goals[index] = _goals[index].copyWith(isCompleted: !_goals[index].isCompleted);
            notifyListeners(); //Arayüzü Güncelle
          }

        }
        catch(e){
           _errorMessage = e.toString();
            print("Tamamlanma Durumu Değiştirilirken Hata: $e");
        }
  }
}