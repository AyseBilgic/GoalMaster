// lib/views/goal_details/goal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama
import 'package:provider/provider.dart'; // Provider

import '../../models/goal.dart';       // Goal modeli
import '../../providers/goal_provider.dart'; // GoalProvider
import '../../models/subtask.dart';      // Subtask modeli
import '../../models/reminder.dart';    // Reminder modeli
import '../../providers/auth_provider.dart'; // AuthProvider (userId için)
import '../add_goal/add_goal_screen.dart'; // Hedef düzenleme için

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      // GoalProvider'daki goalId bazlı metodları kullan
      goalProvider.fetchSubtasksForGoal(widget.goal.goalId);
      goalProvider.fetchRemindersForGoal(widget.goal.goalId);
    });
  }

  void _showAISuggestionsDialog(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    if (!goalProvider.isSuggestionLoading(widget.goal.goalId)) {
      goalProvider.fetchGoalSuggestions(widget.goal.goalId);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer<GoalProvider>(
          builder: (consumerContext, provider, child) {
            final isLoading = provider.isSuggestionLoading(widget.goal.goalId);
            final error = provider.getSuggestionError(widget.goal.goalId);
            final suggestions = provider.getSuggestionsForGoal(widget.goal.goalId);
            Widget content;
            if (isLoading) {
              content = const Center(heightFactor: 1.5, child: CircularProgressIndicator());
            } else if (error != null) {
              content = Padding( padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text("Öneriler alınamadı:\n$error", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center));
            } else if (suggestions.isEmpty) {
               content = const Padding( padding: EdgeInsets.symmetric(vertical: 20.0), child: Center(child: Text("Bu hedef için öneri bulunamadı.")));
            } else {
              content = SizedBox( width: double.maxFinite,
                 child: ConstrainedBox( constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.separated( shrinkWrap: true, itemCount: suggestions.length,
                        itemBuilder: (_, index) => ListTile(
                              leading: const Icon(Icons.lightbulb_outline, size: 20, color: Colors.orange),
                              title: Text(suggestions[index], style: Theme.of(context).textTheme.bodyMedium),
                              dense: true, ),
                        separatorBuilder: (_, index) => const Divider(height: 1, indent: 16, endIndent: 16), ), ), );
            }
            return AlertDialog(
              title: Text('"${widget.goal.title}" İçin Öneriler', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
              contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
              content: content,
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              actions: <Widget>[
                 if (!isLoading && (error != null || suggestions.isEmpty))
                   TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 18), label: const Text('Yenile'),
                      onPressed: () => goalProvider.fetchGoalSuggestions(widget.goal.goalId), ),
                 TextButton( child: const Text('Kapat'), onPressed: () { if(Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop(); } ),
              ], ); }, ); }, );
  }

   void _showDeleteConfirmationDialog(BuildContext context, Goal goal) {
     final goalProvider = Provider.of<GoalProvider>(context, listen: false);
     final authProvider = Provider.of<AuthProvider>(context, listen: false);
     final userId = authProvider.userId;

     if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Hata: Kullanıcı oturumu bulunamadı!'), backgroundColor: Colors.red,) );
        }
        return;
     }

    showDialog( context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Hedefi Sil'), content: Text('"${widget.goal.title}" hedefini silmek istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton( child: const Text('İptal'), onPressed: () { if(Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop(); } ),
          TextButton( child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () async {
               final navigator = Navigator.of(dialogContext); // Store navigator before async gap
               if (navigator.canPop()) navigator.pop();
               bool success = await goalProvider.deleteGoal(widget.goal.goalId, userId);

               if (!mounted) return; // mounted kontrolü async işlemden sonra
               ScaffoldMessenger.of(context).showSnackBar( SnackBar( 
                       content: Text(success ? 'Hedef başarıyla silindi.' : goalProvider.goalError ?? 'Hedef silinemedi!'),
                       backgroundColor: success ? Colors.green : Colors.red, ) );
               if (success) {
                  final mainNavigator = Navigator.of(context); // Store main navigator
                  if (mainNavigator.canPop()) mainNavigator.pop(true);
               }
            }, ), ], ), );
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    // GoalProvider'ı dinleyerek UI güncellemelerini alalım
    final goalProvider = Provider.of<GoalProvider>(context);
    final int goalId = widget.goal.goalId; // Kolay erişim için

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Düzenle',
              onPressed: () async { // Navigator'ı async işlem öncesi sakla
                final navigator = Navigator.of(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddGoalScreen(goalToEdit: goal)),
                );
                if (result == true && mounted) {
                  // Düzenleme sonrası detay ekranını da yenilemek için pop(true) yapabiliriz
                  // Şimdilik, bir önceki ekrana (muhtemelen HomeScreen) true döndürüyoruz.                  
                  if (navigator.canPop()) navigator.pop(true); 
                }
              }),
          IconButton( icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'Sil',
              onPressed: () => _showDeleteConfirmationDialog(context, goal), ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),

            if (goal.description != null && goal.description!.isNotEmpty) ...[
              Text('Açıklama', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Text(goal.description!, style: Theme.of(context).textTheme.bodyLarge),
              const Divider(height: 30),
            ],
            if (goal.emotionNotes != null && goal.emotionNotes!.isNotEmpty) ...[ // feelingsNotes -> emotionNotes
              Text('Duygu ve Notlar', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Text(goal.emotionNotes!, style: Theme.of(context).textTheme.bodyMedium), // feelingsNotes -> emotionNotes
              const Divider(height: 30),
            ],

             Wrap(
               spacing: 24.0,
               runSpacing: 18.0,
               children: [
                  if (goal.category != null && goal.category!.isNotEmpty)
                     _buildDetailItem(context, Icons.category_outlined, 'Kategori', goal.category!),
                  if (goal.targetDate != null)
                     _buildDetailItem(context, Icons.calendar_today_outlined, 'Hedef Tarih', DateFormat('dd MMMM yyyy', 'tr_TR').format(goal.targetDate!)),
                  _buildDetailItem(context, goal.isCompleted ? Icons.check_circle_outline_rounded : Icons.hourglass_top_rounded, 'Durum', goal.isCompleted ? 'Tamamlandı' : 'Devam Ediyor', valueColor: goal.isCompleted ? Colors.green.shade700 : Colors.blueGrey),
                   _buildDetailItem(context, Icons.show_chart_rounded, 'İlerleme', '${(goal.progress * 100).toStringAsFixed(0)}%', valueColor: Theme.of(context).colorScheme.primary),
               ],
             ),
             if (!goal.isCompleted && goal.progress >= 0) ...[
                const SizedBox(height: 24),
                Text('İlerleme', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                LinearProgressIndicator( value: goal.progress, minHeight: 8, borderRadius: BorderRadius.circular(4), ),
             ],

            const Divider(height: 40, thickness: 0.5),
            _buildSubtasksSection(context, goalId, goalProvider),
            const Divider(height: 40, thickness: 0.5),
            _buildRemindersSection(context, goalId, goalProvider),
            const Divider(height: 40, thickness: 0.5),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: const Text('AI Önerileri Göster'),
                onPressed: () => _showAISuggestionsDialog(context),
                style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                   side: BorderSide(color: Colors.orange.shade200),
                   foregroundColor: Colors.orange.shade800
                ),
              ),
            ),

             if (goal.createdAt != null || goal.updatedAt != null) ...[
               const SizedBox(height: 30),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    if (goal.createdAt != null) Flexible(child: Text('Oluşturma: ${DateFormat('dd.MM.yy HH:mm').format(goal.createdAt!)}', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                    if (goal.updatedAt != null && goal.updatedAt != goal.createdAt) Flexible(child: Text('Güncelleme: ${DateFormat('dd.MM.yy HH:mm').format(goal.updatedAt!)}', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                 ],
               )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    final defaultStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);
    final valueStyle = valueColor != null ? defaultStyle?.copyWith(color: valueColor) : defaultStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildSubtasksSection(BuildContext context, int goalId, GoalProvider goalProvider) {
    final subtasks = goalProvider.getSubtasksFor(goalId);
    final isLoading = goalProvider.isLoadingSubtasksFor(goalId);
    final error = goalProvider.getSubtaskErrorFor(goalId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Alt Görevler', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
              tooltip: 'Yeni Alt Görev Ekle',
              onPressed: () {
                _showAddSubtaskDialog(context, goalId, goalProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))),
        if (error != null && !isLoading)
           Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text('Alt görevler yüklenemedi: $error', style: const TextStyle(color: Colors.red))),
        if (subtasks.isEmpty && !isLoading && error == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Text('Henüz alt görev eklenmemiş.', style: TextStyle(color: Colors.grey)),
          )
        else if (subtasks.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subtasks.length,
            itemBuilder: (ctx, index) {
              final subtask = subtasks[index];
              return ListTile(
                dense: true,
                leading: Checkbox(
                  value: subtask.isCompleted,
                  onChanged: (value) {
                    if (subtask.id != null) {
                      goalProvider.toggleSubtaskCompletion(goalId, subtask.id!);
                    }
                  },
                ),
                title: Text(
                  subtask.title,
                  style: TextStyle(
                      decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                      color: subtask.isCompleted ? Colors.grey : null),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    if (subtask.id != null) {
                      goalProvider.deleteSubtaskFromGoal(goalId, subtask.id!);
                    }
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRemindersSection(BuildContext context, int goalId, GoalProvider goalProvider) {
    final reminders = goalProvider.getRemindersFor(goalId);
    final isLoading = goalProvider.isLoadingRemindersFor(goalId);
    final error = goalProvider.getReminderErrorFor(goalId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hatırlatıcılar', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              icon: const Icon(Icons.add_alarm_outlined, color: Colors.blue),
              tooltip: 'Yeni Hatırlatıcı Ekle',
              onPressed: () {
                _showAddReminderDialog(context, goalId, goalProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))),
        if (error != null && !isLoading)
           Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text('Hatırlatıcılar yüklenemedi: $error', style: const TextStyle(color: Colors.red))),
        if (reminders.isEmpty && !isLoading && error == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Text('Henüz hatırlatıcı eklenmemiş.', style: TextStyle(color: Colors.grey)),
          )
        else if (reminders.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reminders.length,
            itemBuilder: (ctx, index) {
              final reminder = reminders[index];
              return ListTile(
                dense: true,
                leading: Icon(reminder.isSent ? Icons.notifications_off_outlined : Icons.notifications_active_outlined, color: reminder.isSent ? Colors.grey : Colors.orange),
                title: Text(DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(reminder.reminderTime)),
                subtitle: reminder.message != null ? Text(reminder.message!) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    goalProvider.deleteReminderFromGoal(goalId, reminder.reminderId);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddSubtaskDialog(BuildContext context, int goalId, GoalProvider provider) {
    final TextEditingController controller = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Alt Görev'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Alt Görev Başlığı'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () { final dialogNavigator = Navigator.of(ctx); if(dialogNavigator.canPop()) dialogNavigator.pop(); }, child: const Text('İptal')),
          TextButton(
            onPressed: () async { // async eklendi
              final dialogNavigator = Navigator.of(ctx); // Store navigator before async gap
              if (controller.text.isNotEmpty) {
                bool success = await provider.addSubtaskToGoal(goalId,
                  Subtask(
                    goalId: goalId, 
                    userId: authProvider.userId!,
                    title: controller.text.trim(),
                  ), // Subtask
                );
                if (dialogNavigator.canPop()) dialogNavigator.pop();
                // mounted kontrolü async işlemden sonra yapılmalı
                if (!mounted) return;
                if (!success) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.getSubtaskErrorFor(goalId) ?? 'Alt görev eklenemedi!'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, int goalId, GoalProvider provider) {
    final TextEditingController messageController = TextEditingController();
    DateTime? selectedDateTime;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Yeni Hatırlatıcı'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(selectedDateTime == null
                      ? 'Tarih ve Saat Seçin'
                      : DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(selectedDateTime!)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final date = await showDatePicker(context: dialogCtx, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2101));
                    if (date != null) {
                      final time = await showTimePicker(context: dialogCtx, initialTime: TimeOfDay.now());
                      if (time != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
                TextField(controller: messageController, decoration: const InputDecoration(labelText: 'Mesaj (Opsiyonel)')),
              ],
            ),
            actions: [
              TextButton(onPressed: () { final dNavigator = Navigator.of(dialogCtx); if(dNavigator.canPop()) dNavigator.pop(); }, child: const Text('İptal')),
              TextButton(
                onPressed: selectedDateTime == null ? null : () async { // async eklendi
                  final dNavigator = Navigator.of(dialogCtx); // Store navigator before async gap
                  bool success = await provider.addReminderToGoal(goalId,
                    Reminder(
                        goalId: goalId, 
                        userId: authProvider.userId!,
                        reminderTime: selectedDateTime!,
                        message: messageController.text.trim().isNotEmpty ? messageController.text.trim() : null) // Reminder
                    );
                  
                  if (dNavigator.canPop()) dNavigator.pop();
                  // mounted kontrolü async işlemden sonra yapılmalı
                  if (!mounted) return; 
                  if (!success) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.getReminderErrorFor(goalId) ?? 'Hatırlatıcı eklenemedi!'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }
}
