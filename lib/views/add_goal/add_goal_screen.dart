// lib/views/add_goal/add_goal_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert'; // JSON işlemleri için

import '../../models/goal.dart';
import '../../providers/auth_provider.dart';
// import '../../models/subtask.dart'; // Kullanılmıyorsa kaldırıldı
// import '../../models/reminder.dart'; // Kullanılmıyorsa kaldırıldı
import '../../providers/goal_provider.dart';
import '../../models/sentiment_result.dart';
import '../../services/api_service.dart';
// import '../../utils/theme.dart'; // Eğer özel tema renkleriniz varsa

class AddGoalScreen extends StatefulWidget {
  final Goal? goalToEdit;
  const AddGoalScreen({super.key, this.goalToEdit});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();

  // Temel Hedef Bilgileri
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime? _selectedTargetDate;
  double _progressValue = 0.0;
  bool _isCompleted = false;

  // Alt Görevler
  final List<TextEditingController> _subtaskTitleControllers = [];

  // Hatırlatıcılar
  final List<TextEditingController> _reminderMessageControllers = [];
  final List<TextEditingController> _reminderTimeControllers = []; // Flatpickr gibi string tutacak
  final List<DateTime?> _reminderDateTimes = []; // Seçilen gerçek DateTime nesneleri

  // Duygu ve Notlar
  final _emotionNotesController = TextEditingController(); // Bu final kalabilir, içeriği değişiyor
  SentimentResult? _sentimentAnalysisResult; // API'den dönen ham sonuç
  String? _analyzedEmotionPrimary; // Saklanacak ana duygu
  String? _analyzedEmotionDetailsJson; // Saklanacak detay JSON'u
  bool _isAnalyzingEmotion = false;
  String? _emotionAnalysisError;

  // Düzenleme Modu
  Goal? _currentEditingGoal;
  bool get _isEditingMode => _currentEditingGoal != null && _currentEditingGoal!.goalId != 0;

  @override
  void initState() {
    super.initState();
    _addSubtaskField(isInitial: true); // Başlangıçta en az bir alt görev alanı
    _addReminderField(isInitial: true); // Başlangıçta en az bir hatırlatıcı alanı

    if (widget.goalToEdit != null) {
      _currentEditingGoal = widget.goalToEdit;
      _populateFormFields(widget.goalToEdit!);
      // Provider'dan alt görev ve hatırlatıcıları çekme (mevcut kodunuzdaki gibi)
      // Bu kısım, eğer Goal nesnesi subtasks ve reminders listelerini doğrudan içermiyorsa gereklidir.
      // Eğer Goal nesnesi bu listeleri içeriyorsa, _populateFormFields içinde doldurulabilir.
      if (_isEditingMode) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
          // final goalProvider = Provider.of<GoalProvider>(context, listen: false); // Kullanılmıyorsa kaldırıldı
          // final goalId = _currentEditingGoal!.goalId; // Kullanılmıyorsa kaldırıldı
          // Mevcut subtask ve reminder çekme logiği buraya gelebilir
          // Örnek: goalProvider.fetchSubtasksForGoal(goalId);
          // goalProvider.fetchRemindersForGoal(goalId);
          // Bu veriler daha sonra _subtaskTitleControllers ve _reminderXXX controller'larını doldurmak için kullanılabilir.
        });
      }
    }
  }

  void _populateFormFields(Goal goal) {
    _titleController.text = goal.title;
    _descriptionController.text = goal.description ?? '';
    _categoryController.text = goal.category ?? '';
    _selectedTargetDate = goal.targetDate;
    _progressValue = goal.progress;
    _isCompleted = goal.isCompleted;

    // Goal modelinizde bu alanların tanımlı olduğundan emin olun.
    _emotionNotesController.text = goal.emotionNotes ?? '';
    _analyzedEmotionPrimary = goal.analyzedEmotionPrimary;
    _analyzedEmotionDetailsJson = goal.analyzedEmotionDetailsJson;

    if (_analyzedEmotionPrimary != null && _analyzedEmotionPrimary!.isNotEmpty) {
        // _sentimentAnalysisResult'ı _analyzedEmotionDetailsJson'dan yeniden oluşturabilirsiniz
        // veya sadece _analyzedEmotionPrimary'e göre bir UI state'i ayarlayabilirsiniz.
        // Şimdilik basitçe ana duyguyu gösterelim.
        // Daha iyisi: _sentimentAnalysisResult'ı JSON'dan parse etmek.
        try {
          if (_analyzedEmotionDetailsJson != null && _analyzedEmotionDetailsJson!.isNotEmpty) {
            final decoded = jsonDecode(_analyzedEmotionDetailsJson!);
            // Bu kısım, SentimentResult modelinizin yapısına ve API'nizin döndüğü JSON'a bağlı.
            // Örnek bir SentimentResult varsayımı:
            _sentimentAnalysisResult = SentimentResult.fromJson(decoded);
          } else if (_analyzedEmotionPrimary != null) {
            // Sadece ana duygu varsa, basit bir SentimentResult oluştur
             _sentimentAnalysisResult = SentimentResult(overallSentiment: _analyzedEmotionPrimary!, confidenceScore: 1.0);
          }
        } catch (e) {
          debugPrint("Error parsing stored sentiment details: $e");
          _sentimentAnalysisResult = SentimentResult(overallSentiment: _analyzedEmotionPrimary ?? "Belirlenemedi", confidenceScore: 0.0);
        }
    }


    // Alt Görevleri Yükle
    _subtaskTitleControllers.clear();
    // Eğer GoalProvider subtask'ları goalId ile yönetiyorsa:
    // final subtasksFromProvider = Provider.of<GoalProvider>(context, listen: false).getSubtasksFor(goal.goalId);
    // if (subtasksFromProvider.isNotEmpty) {
    //   _subtaskTitleControllers = subtasksFromProvider.map((st) => TextEditingController(text: st.title)).toList();
    // } else {
    //   _addSubtaskField(isInitial: true);
    // }
    // Şimdilik, eğer Goal modelinde subtask başlıkları varsa (basit bir List<String> olarak):
    // goal.subtaskTitles?.forEach((title) => _addSubtaskField(initialText: title));
    // Eğer hiç subtask yoksa, boş bir alan ekle:
    if (_subtaskTitleControllers.isEmpty) _addSubtaskField(isInitial: true);


    // Hatırlatıcıları Yükle
    _reminderTimeControllers.clear();
    _reminderMessageControllers.clear();
    _reminderDateTimes.clear();
    // Benzer şekilde, GoalProvider veya Goal modeli üzerinden hatırlatıcıları yükleyin.
    // Örnek (Goal modelinde List<Map<String, String>> remindersData varsa):
    // goal.remindersData?.forEach((data) => _addReminderField(
    //   initialTimeText: data['time'],
    //   initialMessageText: data['message'],
    //   initialDateTime: data['dateTimeObject'] // Bu DateTime olarak saklanmalı
    // ));
    if (_reminderTimeControllers.isEmpty) _addReminderField(isInitial: true);


    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _emotionNotesController.dispose();
    for (var controller in _subtaskTitleControllers) {
      controller.dispose();
    }
    for (var controller in _reminderMessageControllers) {
      controller.dispose();
    }
    for (var controller in _reminderTimeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Dinamik Alan Ekleme/Kaldırma ---
  void _addSubtaskField({bool isInitial = false, String? initialText}) {
    if (!isInitial && _subtaskTitleControllers.length >= 10) { // Maksimum alt görev sayısı (opsiyonel)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maksimum alt görev sayısına ulaşıldı.")));
      return;
    }
    setState(() {
      _subtaskTitleControllers.add(TextEditingController(text: initialText ?? ''));
    });
  }

  void _removeSubtaskField(int index) {
    if (_subtaskTitleControllers.length > 1) {
      setState(() {
        _subtaskTitleControllers.removeAt(index).dispose();
      });
    } else { // Sonuncusu ise temizle
      _subtaskTitleControllers[index].clear();
    }
  }

  void _addReminderField({bool isInitial = false, String? initialTimeText, String? initialMessageText, DateTime? initialDateTime}) {
     if (!isInitial && _reminderTimeControllers.length >= 5) { // Maksimum hatırlatıcı sayısı (opsiyonel)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maksimum hatırlatıcı sayısına ulaşıldı.")));
      return;
    }
    setState(() {
      _reminderTimeControllers.add(TextEditingController(text: initialTimeText ?? ''));
      _reminderMessageControllers.add(TextEditingController(text: initialMessageText ?? ''));
      _reminderDateTimes.add(initialDateTime);
    });
  }

  void _removeReminderField(int index) {
    if (_reminderTimeControllers.length > 1) {
      setState(() {
        _reminderTimeControllers.removeAt(index).dispose();
        _reminderMessageControllers.removeAt(index).dispose();
        _reminderDateTimes.removeAt(index);
      });
    } else { // Sonuncusu ise temizle
        _reminderTimeControllers[index].clear();
        _reminderMessageControllers[index].clear();
        _reminderDateTimes[index] = null;
    }
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _selectedTargetDate) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  Future<void> _selectReminderDateTime(BuildContext context, int index) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDateTimes[index] ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(minutes: 5)), // Geçmişe çok fazla gitmesin
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('tr', 'TR'),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDateTimes[index] ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          final selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _reminderDateTimes[index] = selectedDateTime;
          _reminderTimeControllers[index].text = DateFormat('yyyy-MM-dd HH:mm', 'tr_TR').format(selectedDateTime);
        });
      }
    }
  }

  Future<void> _analyzeEmotion() async {
    if (_emotionNotesController.text.trim().isEmpty) {
      setState(() {
        _emotionAnalysisError = 'Analiz için lütfen düşüncelerinizi yazın.';
        _sentimentAnalysisResult = null;
      });
      return;
    }
    setState(() {
      _isAnalyzingEmotion = true;
      _emotionAnalysisError = null;
      _sentimentAnalysisResult = null;
      _analyzedEmotionPrimary = null;
      _analyzedEmotionDetailsJson = null;
    });

    try {
      final apiService = ApiService(); // Provider'dan da alınabilir
      // Web'deki gibi /api/analyze_emotion endpoint'ine ve userId'ye göre uyarlayın
      // final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      // if (userId == null) throw Exception("Kullanıcı ID bulunamadı.");
      // final result = await apiService.analyzeEmotionText(_emotionNotesController.text.trim(), userId);
      final result = await apiService.analyzeTextSentiment(_emotionNotesController.text.trim()); // Mevcut metodu kullanalım

      setState(() {
        _sentimentAnalysisResult = result;
        // API yanıtınıza göre bu alanları doldurun
        _analyzedEmotionPrimary = result.overallSentiment;
        // SentimentResult modelinizin bir toJson metodu varsa:
        // _analyzedEmotionDetailsJson = jsonEncode(result.toJson());
        // Veya API'den gelen ham JSON'u saklayabilirsiniz. Şimdilik basit tutalım:
        _analyzedEmotionDetailsJson = jsonEncode({
          'sentiment': result.overallSentiment,
          'score': result.confidenceScore,
          'keywords': [], // API'niz keywords döndürüyorsa ekleyin
          'detailedScores': result.detailedScores?.toJson(), // DetailedScores modelinde toJson() olmalı
        });
      });
    } catch (e) {
      setState(() {
        _emotionAnalysisError = "Duygu analizi başarısız: ${e.toString()}";
        _sentimentAnalysisResult = null;
      });
    } finally {
      setState(() => _isAnalyzingEmotion = false);
    }
  }

  Future<void> _saveGoal() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lütfen formdaki zorunlu alanları doldurun.'),
        backgroundColor: Colors.orangeAccent,
      ));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Oturum hatası! Lütfen tekrar giriş yapın.'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    // Alt görev başlıklarını topla
    // final List<String> subtaskTitles = _subtaskTitleControllers // Kullanılmıyorsa kaldırıldı
    //     .map((controller) => controller.text.trim())
    //     .where((title) => title.isNotEmpty)
    //     .toList();

    // Hatırlatıcı verilerini topla (eğer GoalProvider'a ayrı gönderilecekse)
    final List<Map<String, dynamic>> remindersData = [];
    for (int i = 0; i < _reminderDateTimes.length; i++) {
      if (_reminderDateTimes[i] != null) {
        remindersData.add({
          'reminder_time': _reminderDateTimes[i]!.toIso8601String(), // Veya backend'in beklediği format
          'message': _reminderMessageControllers[i].text.trim(),
        });
      }
    }

    final goalData = Goal(
      goalId: _isEditingMode ? _currentEditingGoal!.goalId : 0,
      userId: userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      targetDate: _selectedTargetDate,
      progress: _progressValue,
      isCompleted: _isCompleted || _progressValue >= 1.0,
      // Goal modelinizde bu parametrelerin constructor'da tanımlı olduğundan emin olun.
      emotionNotes: _emotionNotesController.text.trim().isEmpty ? null : _emotionNotesController.text.trim(),
      analyzedEmotionPrimary: _analyzedEmotionPrimary,
      analyzedEmotionDetailsJson: _analyzedEmotionDetailsJson,
      // Subtasks ve Reminders: Provider'ınızın bu listeleri nasıl kabul ettiğine bağlı.
      // Eğer Goal modeli içinde List<Subtask> ve List<Reminder> tutuyorsanız,
      // burada bu listeleri oluşturup goalData'ya eklemeniz gerekir.
      // Ya da provider'ın add/update metodları bu ham listeleri (subtaskTitles, remindersData) kabul etmeli.
    );

    // --- Provider'a Kaydetme/Güncelleme ---
    // Bu kısım, GoalProvider'ınızın subtask ve reminder listelerini nasıl işlediğine bağlı olarak değişir.
    // Seçenek 1: Provider metodları List<String> subtaskTitles ve List<Map> remindersData kabul eder.
    // Seçenek 2: Önce ana hedef kaydedilir/güncellenir, sonra subtask/reminder'lar ayrı ayrı eklenir/güncellenir/silinir.
    // Şimdilik Seçenek 1'e benzer bir çağrı varsayalım.

    bool success = false;
    String? errorMessage;

    if (_isEditingMode) {
      // success = await goalProvider.updateGoalWithDetails(goalData, subtaskTitles, remindersData);
      success = await goalProvider.updateGoal(goalData); // Mevcut provider'ı kullanalım, detaylar sonra eklenebilir
      errorMessage = goalProvider.goalError;
    } else {
      // Goal? addedGoal = await goalProvider.addGoalWithDetails(goalData, subtaskTitles, remindersData);
      Goal? addedGoal = await goalProvider.addGoal(goalData); // Mevcut provider
      success = addedGoal != null;
      errorMessage = goalProvider.goalError;
       if (success && addedGoal != null) {
        setState(() {
          _currentEditingGoal = addedGoal;
          // Yeni eklenen hedef için alt görev ve hatırlatıcıları ayrıca ekleyebilirsiniz
          // Örneğin: _syncSubtasksAndReminders(addedGoal.goalId, goalProvider, _subtaskTitleControllers.map((c)=>c.text).toList(), remindersData);
        });
      }
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hedef başarıyla ${_isEditingMode ? 'güncellendi' : 'eklendi'}!'),
        backgroundColor: Colors.green,
      ));
      if (!_isEditingMode && success) { // Sadece başarılı ekleme durumunda
        // Yeni hedef eklendiyse ve provider detayları ayrıca işlemiyorsa, burada yönlendirme veya state güncellemesi yapılabilir.
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage ?? 'Hedef ${_isEditingMode ? 'güncellenirken' : 'eklenirken'} bir hata oluştu.'),
        backgroundColor: Colors.red,
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalProvider = context.watch<GoalProvider>(); // Sadece loading state için
    final bool isLoading = goalProvider.isLoadingGoals; // Veya özel bir saving state

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isEditingMode ? '🎯 Hedefini Düzenle' : '✨ Yeni Bir Hedef Oluştur',
          style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0.8,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Header (Web'deki gibi)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _isEditingMode ? Icons.edit_note_rounded : Icons.add_task_rounded,
                            size: 48,
                            color: theme.colorScheme.onPrimary.withAlpha(204), // 0.8 opacity
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isEditingMode ? 'Hedefini Güncelle' : 'Yeni Bir Hedef Belirle',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold, // fontWeight zaten headlineSmall'da olabilir
                            ),
                            textAlign: TextAlign.center,
                          ),
                           const SizedBox(height: 8),
                          Text(
                            "Hayallerine bir adım daha yaklaş. Detayları planla, yolculuğunu başlat!",
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.9)),
                            textAlign: TextAlign.center, // withOpacity yerine withAlpha(230)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Temel Hedef Bilgileri
                    _buildSectionTitle(theme, "Temel Hedef Bilgileri", Icons.sticky_note_2_outlined),
                    _buildTextFormField(
                      controller: _titleController,
                      labelText: 'Hedef Başlığı *',
                      hintText: 'Örn: Yıl sonuna kadar İspanyolca B1...',
                      icon: Icons.flag_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık zorunludur.' : null,
                      isLargeText: true,
                    ),
                    _buildTextFormField(
                      controller: _descriptionController,
                      labelText: 'Açıklama',
                      hintText: 'Bu hedef neden önemli? Motivasyon kaynakların neler?',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _categoryController,
                            labelText: 'Kategori',
                            hintText: 'Kişisel, İş, Sağlık vb.',
                            icon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTargetDateField(theme)),
                      ],
                    ),
                    _buildProgressSlider(theme),
                    _buildIsCompletedSwitch(theme),
                    const SizedBox(height: 20),

                    // Alt Görevler
                    _buildSectionTitle(theme, "Alt Görevler", Icons.list_alt_rounded),
                    _buildSubtasksList(theme),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Alt Görev Ekle'),
                        onPressed: () => _addSubtaskField(),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hatırlatıcılar
                    _buildSectionTitle(theme, "Hatırlatıcılar", Icons.notifications_active_outlined),
                    _buildRemindersList(theme),
                     Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add_alarm_outlined, size: 18),
                        label: const Text('Hatırlatıcı Ekle'),
                        onPressed: () => _addReminderField(),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), foregroundColor: theme.colorScheme.secondary),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Duygu ve Notlar
                    _buildSectionTitle(theme, "Duygu ve Notlar", Icons.emoji_emotions_outlined),
                    _buildTextFormField(
                      controller: _emotionNotesController,
                      labelText: 'Bu hedefle ilgili düşüncelerin/duyguların neler?',
                      hintText: 'Motivasyonun, endişelerin, beklentilerin...',
                      icon: Icons.comment_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: _isAnalyzingEmotion ? const SizedBox(width:18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.psychology_outlined, size: 18),
                      label: const Text('Duyguyu Analiz Et (AI)'),
                      onPressed: _isAnalyzingEmotion ? null : _analyzeEmotion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, // theme.colorScheme.tertiary,
                        foregroundColor: Colors.white, // theme.colorScheme.onTertiary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    _buildEmotionAnalysisResultArea(theme),
                    const SizedBox(height: 30),

                    // Kaydet/Güncelle Butonu
                    ElevatedButton.icon(
                      icon: isLoading ? const SizedBox(width:20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_isEditingMode ? Icons.save_alt_rounded : Icons.add_circle_outline_rounded),
                      label: Text(_isEditingMode ? 'Değişiklikleri Kaydet' : 'Hedefi Oluştur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: isLoading ? null : _saveGoal,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      child: const Text('İptal Et ve Geri Dön'),
                      onPressed: () => Navigator.of(context).pop(),
                       style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: theme.textTheme.bodyLarge?.color,
                        side: BorderSide(color: theme.dividerColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration( // withOpacity yerine withAlpha(76)
          color: theme.colorScheme.primaryContainer.withAlpha(77), // 0.3 opacity
          borderRadius: BorderRadius.circular(5),
          // border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 2))
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? icon,
    int maxLines = 1,
    bool isLargeText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(vertical: isLargeText ? 16 : 12, horizontal: 12),
          alignLabelWithHint: maxLines > 1,
        ),
        style: isLargeText ? Theme.of(context).textTheme.titleMedium : null,
        maxLines: maxLines,
        validator: validator,
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      ),
    );
  }

  Widget _buildTargetDateField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hedef Tamamlama Tarihi", style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _selectTargetDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: 'Bir tarih seçin...',
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              child: Text(
                _selectedTargetDate == null
                    ? 'Tarih Seç...'
                    : DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedTargetDate!),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _selectedTargetDate == null ? theme.hintColor : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('İlerleme: ${(_progressValue * 100).toStringAsFixed(0)}%', style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor)),
          Slider(
            value: _progressValue,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(_progressValue * 100).toStringAsFixed(0)}%',
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.primary.withAlpha(77), // 0.3 opacity
            onChanged: (value) => setState(() {
              _progressValue = value;
              if (_progressValue >= 1.0) _isCompleted = true;
              // else _isCompleted = false; // Otomatik false yapma, kullanıcı elle de tamamlandı işaretleyebilir
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildIsCompletedSwitch(ThemeData theme) {
    return SwitchListTile(
      title: const Text("Tamamlandı"),
      value: _isCompleted,
      onChanged: (bool? value) {
        setState(() {
          _isCompleted = value ?? false;
          if (_isCompleted) _progressValue = 1.0;
          // else _progressValue = 0.0; // Eğer tamamlanmadıysa progress'i sıfırlamak isteğe bağlı
        });
      },
      activeColor: Colors.green,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildSubtasksList(ThemeData theme) {
    if (_subtaskTitleControllers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Henüz alt görev eklenmedi.", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subtaskTitleControllers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded( // child en sona taşındı
                child: TextFormField( // child en sona taşındı
                  controller: _subtaskTitleControllers[index],
                  decoration: InputDecoration(
                    hintText: 'Alt görev başlığı...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // child en sona taşındı
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: theme.dividerColor)),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                onPressed: () => _removeSubtaskField(index),
                tooltip: "Kaldır",
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemindersList(ThemeData theme) {
     if (_reminderTimeControllers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Henüz hatırlatıcı eklenmedi.", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reminderTimeControllers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => _selectReminderDateTime(context, index),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: 'Tarih ve Saat Seçin',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: theme.dividerColor)),
                      suffixIcon: const Icon(Icons.calendar_month_outlined, size: 18)
                    ),
                    child: Text(
                      _reminderTimeControllers[index].text.isEmpty ? 'Tarih ve Saat...' : _reminderTimeControllers[index].text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _reminderTimeControllers[index].text.isEmpty ? theme.hintColor : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _reminderMessageControllers[index],
                  decoration: InputDecoration(
                    hintText: 'Mesaj (ops.)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: theme.dividerColor)),
                  ),
                   style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                onPressed: () => _removeReminderField(index),
                tooltip: "Kaldır",
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmotionAnalysisResultArea(ThemeData theme) {
    Color borderColor = Colors.grey.shade400;
    Color backgroundColor = Colors.grey.shade100;
    Color textColor = Colors.black87;
    String displayText = "Analiz sonucu burada görünecek...";
    IconData? displayIcon;

    if (_isAnalyzingEmotion) {
      displayText = "Duygu analizi yapılıyor...";
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade300;
      textColor = Colors.blue.shade800;
    } else if (_emotionAnalysisError != null) {
      displayText = _emotionAnalysisError!;
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade400;
      textColor = Colors.red.shade800;
      displayIcon = Icons.error_outline;
    } else if (_sentimentAnalysisResult != null) {
      final sentiment = _sentimentAnalysisResult!.overallSentiment.toLowerCase();
      displayText = 'Tespit Edilen Duygu: ${_sentimentAnalysisResult!.overallSentiment.toUpperCase()}';
      if (_sentimentAnalysisResult!.confidenceScore > 0) {
         displayText += ' (Skor: ${(_sentimentAnalysisResult!.confidenceScore * 100).toStringAsFixed(0)}%)';
      }

      if (sentiment.contains('positive') || sentiment.contains('olumlu')) {
        backgroundColor = Colors.green.shade50; borderColor = Colors.green.shade400; textColor = Colors.green.shade800; displayIcon = Icons.sentiment_very_satisfied_outlined;
      } else if (sentiment.contains('negative') || sentiment.contains('olumsuz')) {
        backgroundColor = Colors.red.shade50; borderColor = Colors.red.shade400; textColor = Colors.red.shade800; displayIcon = Icons.sentiment_very_dissatisfied_outlined;
      } else if (sentiment.contains('neutral') || sentiment.contains('nötr')) {
        backgroundColor = Colors.grey.shade200; borderColor = Colors.grey.shade500; textColor = Colors.grey.shade800; displayIcon = Icons.sentiment_neutral_outlined;
      } else if (sentiment.contains('mixed') || sentiment.contains('karışık')) {
        backgroundColor = Colors.orange.shade50; borderColor = Colors.orange.shade400; textColor = Colors.orange.shade800; displayIcon = Icons.sentiment_satisfied_outlined;
      }
       // Detaylı skorları da ekleyebiliriz
      if (_sentimentAnalysisResult!.detailedScores != null) {
        final ds = _sentimentAnalysisResult!.detailedScores!;
        displayText += '\nPoz: ${(ds.positive * 100).toStringAsFixed(0)}% Neg: ${(ds.negative * 100).toStringAsFixed(0)}% Nötr: ${(ds.neutral * 100).toStringAsFixed(0)}%';
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: borderColor, width: 1.2),
        // border: Border(left: BorderSide(color: borderColor, width: 5)), // Web'deki gibi sol border
      ),
      child: Row(
        children: [
          if (displayIcon != null) Icon(displayIcon, color: textColor.withAlpha(204), size: 20), // 0.8 opacity
          if (displayIcon != null) const SizedBox(width: 8),
          Expanded(child: Text(displayText, style: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// SentimentResult modelinin (models/sentiment_result.dart) basit bir örneği:
// class SentimentResult {
//   final String overallSentiment;
//   final double confidenceScore;
//   final DetailedScores? detailedScores;
//   // API'nizden gelen diğer alanlar (keywords vb.)
//
//   SentimentResult({required this.overallSentiment, required this.confidenceScore, this.detailedScores});
//
//   factory SentimentResult.fromJson(Map<String, dynamic> json) {
//     return SentimentResult(
//       overallSentiment: json['sentiment'] ?? json['overallSentiment'] ?? 'Unknown',
//       confidenceScore: (json['score'] ?? json['confidenceScore'] ?? 0.0).toDouble(),
//       detailedScores: json['detailedScores'] != null ? DetailedScores.fromJson(json['detailedScores']) : null,
//     );
//   }
//   Map<String, dynamic> toJson() => {
//     'overallSentiment': overallSentiment,
//     'confidenceScore': confidenceScore,
//     'detailedScores': detailedScores?.toJson(),
//   };
// }
//
// class DetailedScores {
//   final double positive;
//   final double negative;
//   final double neutral;
//
//   DetailedScores({required this.positive, required this.negative, required this.neutral});
//
//   factory DetailedScores.fromJson(Map<String, dynamic> json) {
//     return DetailedScores(
//       positive: (json['positive'] ?? 0.0).toDouble(),
//       negative: (json['negative'] ?? 0.0).toDouble(),
//       neutral: (json['neutral'] ?? 0.0).toDouble(),
//     );
//   }
//   Map<String, dynamic> toJson() => {
//     'positive': positive,
//     'negative': negative,
//     'neutral': neutral,
//   };
// }
