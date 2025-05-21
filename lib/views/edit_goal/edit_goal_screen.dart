// c:\src\flutter_application1\lib\views\edit_goal\edit_goal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode için
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/goal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../routes/app_routes.dart';

class EditGoalScreen extends StatefulWidget {
  final Goal? goalToEdit; // Düzenlenecek hedef (yeni hedef için null olabilir)

  const EditGoalScreen({super.key, this.goalToEdit});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime? _targetDate;
  double _progress = 0.0;
  bool _isCompleted = false;

  bool get _isEditing => widget.goalToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      // Düzenleme modu: Formu mevcut hedef verileriyle doldur
      final goal = widget.goalToEdit!;
      _titleController.text = goal.title;
      _descriptionController.text = goal.description ?? '';
      _categoryController.text = goal.category ?? '';
      _targetDate = goal.targetDate;
      _progress = goal.progress;
      _isCompleted = goal.isCompleted;
    } else {
      // Yeni hedef ekleme modu: Varsayılan değerler (isteğe bağlı)
      // _targetDate = DateTime.now().add(const Duration(days: 30)); // Örnek: 30 gün sonrası
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      locale: const Locale('tr', 'TR'), // Türkçe lokalizasyon
       builder: (context, child) { // Tema özelleştirmesi
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.teal, // Ana renk
                  onPrimary: Colors.white, // Ana renk üzerindeki yazı
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal, // Buton yazı rengi
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _targetDate) {
      if (mounted) {
        setState(() {
          _targetDate = picked;
        });
      }
    }
  }

  Future<void> _saveGoal() async {
    FocusScope.of(context).unfocus(); // Klavyeyi kapat

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lütfen formdaki zorunlu alanları doldurun.'),
        backgroundColor: Colors.orangeAccent,
      ));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Async gap öncesi al
    final navigator = Navigator.of(context); // Async gap öncesi al

    final currentUserId = authProvider.userId;
    if (currentUserId == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Oturum hatası! Lütfen tekrar giriş yapın.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final goalData = Goal(
      goalId: _isEditing ? widget.goalToEdit!.goalId : 0, // Yeni hedef için 0
      userId: currentUserId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      targetDate: _targetDate,
      progress: _progress,
      isCompleted: _isCompleted || _progress >= 1.0, // İlerleme %100 ise tamamlanmış say
      // createdAt ve updatedAt API tarafından yönetilmeli veya Goal modelinde varsayılan değer almalı
    );

    bool success = false;
    String? errorMessage;

    try {
      if (_isEditing) {
        debugPrint("[EditGoalScreen] Updating goal: ${goalData.goalId}");
        success = await goalProvider.updateGoal(goalData);
      } else {
        debugPrint("[EditGoalScreen] Adding new goal");
        final addedGoal = await goalProvider.addGoal(goalData);
        success = addedGoal != null;
      }

      if (!mounted) return;

      if (success) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Hedef başarıyla ${_isEditing ? "güncellendi" : "eklendi"}!'),
          backgroundColor: Colors.green,
        ));
        navigator.pop(true); // Başarılı işlem sonrası geri dön ve true döndür
      } else {
        errorMessage = goalProvider.goalError ?? 'Bilinmeyen bir hata oluştu.';
      }
    } catch (e) {
      debugPrint("[EditGoalScreen] Error saving goal: $e");
      errorMessage = e.toString();
    }

    if (!success && mounted) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Hata: $errorMessage'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showDeleteConfirmationDialog() {
    if (!_isEditing || widget.goalToEdit == null) return;

    final goalToDelete = widget.goalToEdit!;
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Async gap öncesi al
    final navigator = Navigator.of(context); // Async gap öncesi al (hem dialog hem ana sayfa için)

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hedefi Sil'),
        content: Text('"${goalToDelete.title}" hedefini kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
            onPressed: () async {
              Navigator.of(dialogCtx).pop(); // Önce dialogu kapat
              final currentUserId = authProvider.userId;
              if (currentUserId == null) {
                 scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Silme hatası: Oturum bulunamadı.'), backgroundColor: Colors.red));
                 return;
              }

              bool success = await goalProvider.deleteGoal(goalToDelete.goalId, currentUserId);
              if (!mounted) return;

              if (success) {
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Hedef başarıyla silindi.'), backgroundColor: Colors.green));
                navigator.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false); // Ana sayfaya dön ve diğerlerini temizle
              } else {
                scaffoldMessenger.showSnackBar(SnackBar(content: Text('Silme hatası: ${goalProvider.goalError ?? "Bilinmeyen hata"}'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider.of yerine context.watch veya context.select kullanmak daha performanslı olabilir.
    // Ancak butonun aktif/pasif durumu için isLoadingGoals'a ihtiyacımız var.
    final isLoading = context.watch<GoalProvider>().isLoadingGoals; // Ana hedef listesinin yüklenme durumu
    final errorMessageFromProvider = context.watch<GoalProvider>().goalError; // Ana hata
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Hedefi Düzenle' : 'Yeni Hedef Ekle'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Hedefi Sil',
              onPressed: _showDeleteConfirmationDialog,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Başlık *', hintText: 'Ne başarmak istiyorsun?', prefixIcon: Icon(Icons.flag_outlined)),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Başlık zorunludur.' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Açıklama', hintText: 'Hedefin detayları...', prefixIcon: Icon(Icons.description_outlined), alignLabelWithHint: true),
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Kategori', hintText: 'Kişisel, İş, Sağlık...', prefixIcon: Icon(Icons.category_outlined)),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_targetDate == null ? 'Hedef Tarih Seç (İsteğe Bağlı)' : 'Hedef Tarih: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(_targetDate!)}'),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _selectDate(context),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 20),
                Text('İlerleme: ${(_progress * 100).toStringAsFixed(0)}%', style: theme.textTheme.labelLarge),
                Slider(
                  value: _progress,
                  onChanged: (newValue) {
                    if (mounted) {
                      setState(() {
                        _progress = newValue;
                        if (_progress >= 1.0) _isCompleted = true;
                        else if (_isCompleted && _progress < 1.0) _isCompleted = false;
                      });
                    }
                  },
                  min: 0.0, max: 1.0, divisions: 20, // 5% adımlar
                  label: '${(_progress * 100).toStringAsFixed(0)}%',
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.primary.withAlpha(77),
                ),
                CheckboxListTile(
                  title: const Text("Hedef Tamamlandı"),
                  value: _isCompleted,
                  onChanged: (bool? newValue) {
                    if (mounted) {
                      setState(() {
                        _isCompleted = newValue ?? false;
                        if (_isCompleted) _progress = 1.0;
                      });
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.green,
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: CircularProgressIndicator()))
                else
                  ElevatedButton.icon(
                    icon: Icon(_isEditing ? Icons.save_as_outlined : Icons.add_task_outlined),
                    label: Text(_isEditing ? 'Değişiklikleri Kaydet' : 'Hedefi Ekle'),
                    onPressed: _saveGoal, // isLoading kontrolü yukarıda yapıldı
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                if (errorMessageFromProvider != null && !isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(errorMessageFromProvider, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}