// c:\src\flutter_application1\lib\views\home\home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math; // Rastgele ikon için

import '../../models/goal.dart';
import '../../models/subtask.dart';
import '../../models/reminder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../routes/app_routes.dart';
import '../add_goal/add_goal_screen.dart'; // Düzenleme için
import '../goal_details/goal_detail_screen.dart'; // Detay için (eğer rota argümanı yerine doğrudan geçiş yapılacaksa)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Filtreleme ve Arama
  // String _selectedFilter = 'all'; // 'all', 'completed', 'incomplete' -> SegmentedButton bunu yönetecek
  // String _searchQuery = ''; // _searchController.text kullanılacak
  final TextEditingController _searchController = TextEditingController();

  // Animasyonlar için
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  // Rastgele başlık ikonu için
  final List<IconData> _headerIcons = [
    Icons.rocket_launch_outlined, Icons.filter_hdr_outlined, Icons.emoji_events_outlined,
    Icons.lightbulb_outline, Icons.eco_outlined, Icons.star_outline,
    Icons.insights_outlined, Icons.explore_outlined
  ];
  late IconData _currentHeaderIcon;

  @override
  void initState() {
    super.initState();
    _currentHeaderIcon = _headerIcons[math.Random().nextInt(_headerIcons.length)];

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOutBack),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialDataLoad();
      _fabAnimationController.forward(); // FAB animasyonunu başlat
    });

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          // Arama sorgusu değiştikçe UI'ı yeniden çizmek için (filtreleme anlık yapılır)
        });
      }
    });
  }

  Future<void> _initialDataLoad() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      // Sadece hedefler boşsa veya hata varsa ve yüklenmiyorsa çek
      if (goalProvider.goals.isEmpty && goalProvider.goalError == null && !goalProvider.isLoadingGoals) {
        debugPrint("HomeScreen: Initial data load for user ${authProvider.userId}");
        await goalProvider.fetchGoals(authProvider.userId!);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  List<Goal> _getFilteredAndSearchedGoals(List<Goal> allGoals, String currentFilter) {
    List<Goal> filteredGoals;
    if (currentFilter == 'completed') {
      filteredGoals = allGoals.where((goal) => goal.isCompleted).toList();
    } else if (currentFilter == 'incomplete') {
      filteredGoals = allGoals.where((goal) => !goal.isCompleted).toList();
    } else {
      filteredGoals = List.from(allGoals); // 'all'
    }

    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filteredGoals = filteredGoals.where((goal) {
        final titleMatch = goal.title.toLowerCase().contains(searchQuery);
        final descriptionMatch = goal.description?.toLowerCase().contains(searchQuery) ?? false;
        final categoryMatch = goal.category?.toLowerCase().contains(searchQuery) ?? false;
        return titleMatch || descriptionMatch || categoryMatch;
      }).toList();
    }
    return filteredGoals;
  }

  Future<void> _refreshGoals() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      await Provider.of<GoalProvider>(context, listen: false).fetchGoals(authProvider.userId!);
    }
  }

  void _navigateToGoalDetails(Goal goal) {
    Navigator.pushNamed(context, AppRoutes.goalDetails, arguments: goal);
  }

  void _navigateToEditGoal(Goal goal) async {
     final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddGoalScreen(goalToEdit: goal)),
     );
     if (result == true && mounted) { // Eğer düzenleme ekranı true döndürürse listeyi yenile
        _refreshGoals();
     }
  }

  void _navigateToAddNewGoal() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addGoal);
    if (result == true && mounted) { // Eğer ekleme ekranı true döndürürse listeyi yenile
        _refreshGoals();
    }
  }


  // --- DASHBOARD WIDGET'LARI ---
  Widget _buildDashboardMetrics(BuildContext context, List<Goal> allGoals) {
    final theme = Theme.of(context);
    int totalGoalsCount = allGoals.length;
    int completedGoalsCount = allGoals.where((g) => g.isCompleted).length;
    double overallProgressValue = totalGoalsCount > 0
        ? (allGoals.fold<double>(0.0, (sum, g) => sum + g.progress) / totalGoalsCount)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _DashboardWidget(
              icon: Icons.emoji_flags_outlined,
              value: totalGoalsCount.toString(),
              label: 'Aktif Hedef Sayısı',
              iconColor: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DashboardWidget(
              icon: Icons.check_circle_outline,
              value: completedGoalsCount.toString(),
              label: 'Fethedilen Zirveler',
              iconColor: theme.colorScheme.tertiary, // success-color
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DashboardWidget(
              icon: Icons.trending_up_outlined,
              value: '${(overallProgressValue * 100).toStringAsFixed(0)}%',
              label: 'Genel İlerleme',
              iconColor: theme.colorScheme.primary, // warning-color
              progressBarValue: overallProgressValue,
            ),
          ),
        ],
      ),
    );
  }


  // --- HEDEF KARTI WIDGET'LARI ---
  Widget _buildGoalCard(BuildContext context, Goal goal, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    // Web'deki emotion_class_suffix makrosunun Flutter karşılığı
    String emotionSuffix = "neutral";
    IconData emotionIconData = Icons.sentiment_neutral_outlined;
    Color emotionColor = theme.colorScheme.secondary;

    if (goal.analyzedEmotionPrimary != null) {
      final emotionLower = goal.analyzedEmotionPrimary!.toLowerCase();
      if (emotionLower.contains('pozitif') || emotionLower.contains('olumlu') || emotionLower.contains('mutlu')) {
        emotionSuffix = "positive";
        emotionIconData = Icons.sentiment_very_satisfied_outlined;
        emotionColor = Colors.green.shade600;
      } else if (emotionLower.contains('negatif') || emotionLower.contains('olumsuz') || emotionLower.contains('üzgün') || emotionLower.contains('endişeli')) {
        emotionSuffix = "negative";
        emotionIconData = Icons.sentiment_very_dissatisfied_outlined;
        emotionColor = Colors.red.shade600;
      } else if (emotionLower.contains('karışık')) {
        emotionSuffix = "mixed";
        emotionIconData = Icons.sentiment_satisfied_outlined; // Veya farklı bir ikon
        emotionColor = Colors.orange.shade600;
      } else if (emotionLower.contains('hata')) {
        emotionSuffix = "error";
        emotionIconData = Icons.error_outline;
        emotionColor = theme.colorScheme.error;
      }
    }

    // Düşük ilerleme kontrolü (web'deki gibi)
    bool isLowProgress = (emotionSuffix == "neutral" || emotionSuffix == "mixed") && goal.progress < 0.5 && !goal.isCompleted;

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: emotionSuffix == "positive" ? Colors.green.shade300 :
                 emotionSuffix == "negative" ? Colors.red.shade300 :
                 emotionSuffix == "mixed" ? Colors.orange.shade300 : // Material 3'te theme.errorColor yerine theme.colorScheme.error
                 emotionSuffix == "error" ? theme.colorScheme.error.withOpacity(0.6) :
                 theme.dividerColor.withOpacity(0.5),
          width: emotionSuffix == "neutral" ? 0.5 : 2.5, // Nötr için daha ince, diğerleri için belirgin
        ),
      ),
      child: ExpansionTile(
        key: PageStorageKey<int>(goal.goalId),
        backgroundColor: theme.cardColor, // Açıldığında arka plan
        collapsedBackgroundColor: theme.cardColor,
        leading: Icon(emotionIconData, color: emotionColor, size: 28),
        title: Row(
          children: [
            Expanded(
              child: Text(
                goal.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                  color: goal.isCompleted ? Colors.grey.shade600 : theme.textTheme.titleMedium?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLowProgress)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.hourglass_empty_outlined, size: 16, color: theme.colorScheme.secondary.withAlpha(178)), // 0.7 opacity
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (goal.category != null && goal.category!.isNotEmpty)
                  Chip(
                    avatar: Icon(Icons.label_outline, size: 14, color: theme.colorScheme.onSecondaryContainer),
                    label: Text(goal.category!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
                    backgroundColor: theme.colorScheme.secondaryContainer.withAlpha(178), // 0.7 opacity
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                if (goal.category != null && goal.category!.isNotEmpty && goal.targetDate != null)
                  const SizedBox(width: 8),
                if (goal.targetDate != null)
                  Text(
                    DateFormat('dd MMM yyyy', 'tr_TR').format(goal.targetDate!),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: goal.isCompleted ? Colors.green.withAlpha(51) : theme.colorScheme.primary.withAlpha(51), // 0.2 opacity
              valueColor: AlwaysStoppedAnimation<Color>(goal.isCompleted ? Colors.green : theme.colorScheme.primary),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
             if (goal.isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text("Tamamlandı!", style: theme.textTheme.labelSmall?.copyWith(color: Colors.green.shade700, fontStyle: FontStyle.italic)),
              )
          ],
        ),
        trailing: IconButton( // Detaylar/Düzenle butonu için
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Detayları Gör',
          onPressed: () => _navigateToGoalDetails(goal),
        ),
        onExpansionChanged: (isExpanded) {
          if (isExpanded) {
            // Detaylar açıldığında verileri çek (eğer daha önce çekilmediyse)
            if (authProvider.userId != null && goalProvider.getSubtasksFor(goal.goalId).isEmpty && !goalProvider.isLoadingSubtasksFor(goal.goalId)) {
              goalProvider.fetchSubtasksForGoal(goal.goalId);
            }
            if (authProvider.userId != null && goalProvider.getRemindersFor(goal.goalId).isEmpty && !goalProvider.isLoadingRemindersFor(goal.goalId)) {
              goalProvider.fetchRemindersForGoal(goal.goalId);
            }
            // AI önerileri için de benzer bir kontrol eklenebilir.
          }
        },
        children: <Widget>[
          _buildGoalCardDetails(context, goal, goalProvider, authProvider)
        ],
      ),
    );
  }

  Widget _buildGoalCardDetails(BuildContext context, Goal goal, GoalProvider goalProvider, AuthProvider authProvider) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("\"${goal.description!}\"", style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
            ),
            const Divider(height: 16),
          ],

          // Alt Görevler Bölümü
          _buildDetailSectionTitle(theme, "Alt Adımlar", Icons.list_alt_outlined, goalProvider.getSubtasksFor(goal.goalId).length),
          _buildSubtaskList(context, goal, goalProvider, authProvider.userId!),
          _buildAddSubtaskForm(context, goal, goalProvider, authProvider.userId!),
          const SizedBox(height: 16),

          // Hatırlatıcılar Bölümü
          _buildDetailSectionTitle(theme, "Hatırlatıcılar", Icons.alarm_on_outlined, goalProvider.getRemindersFor(goal.goalId).length),
          _buildReminderList(context, goal, goalProvider),
          _buildAddReminderForm(context, goal, goalProvider, authProvider.userId!),
          const SizedBox(height: 16),

          // Yapay Zeka Önerileri Bölümü
          _buildDetailSectionTitle(theme, "Yapay Zeka İlham Perisi", Icons.psychology_outlined, null), // Count opsiyonel
          _buildAISuggestionSection(context, goal, goalProvider),
          const SizedBox(height: 16),

          // Eylemler (Tamamlama, Düzenleme, Silme)
          _buildGoalActions(context, goal, goalProvider, authProvider.userId!),
        ],
      ),
    );
  }

  Widget _buildDetailSectionTitle(ThemeData theme, String title, IconData icon, int? count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Chip(
              label: Text(count.toString(), style: TextStyle(fontSize: 11, color: theme.colorScheme.onPrimaryContainer)),
              backgroundColor: theme.colorScheme.primaryContainer.withAlpha(153), // 0.6 opacity
              padding: const EdgeInsets.all(0),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSubtaskList(BuildContext context, Goal goal, GoalProvider provider, int currentUserId) {
    final subtasks = provider.getSubtasksFor(goal.goalId);
    final isLoading = provider.isLoadingSubtasksFor(goal.goalId);
    final error = provider.getSubtaskErrorFor(goal.goalId);

    if (isLoading && subtasks.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
    if (error != null && subtasks.isEmpty) return Text("Alt görevler yüklenemedi: $error", style: const TextStyle(color: Colors.red, fontSize: 12));
    if (subtasks.isEmpty && !isLoading) return const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("Henüz alt adım eklenmemiş.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)));

    return Column(
      children: [
        if (isLoading && subtasks.isNotEmpty) const Padding(padding: EdgeInsets.all(4.0), child: LinearProgressIndicator(minHeight: 2)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subtasks.length,
          itemBuilder: (ctx, index) {
            final subtask = subtasks[index];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              leading: Checkbox(
                value: subtask.isCompleted,
                onChanged: subtask.isCompleted ? null : (val) { // Tamamlanmışsa değiştirilemesin
                  if (subtask.id != null) {
                    provider.toggleSubtaskCompletion(goal.goalId, subtask.id!);
                  }
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              title: Text(subtask.title, style: TextStyle(decoration: subtask.isCompleted ? TextDecoration.lineThrough : null, fontSize: 13, color: subtask.isCompleted ? Colors.grey.shade600 : null)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: "Alt Adımı Sil",
                onPressed: () {
                  if (subtask.id != null) {
                    provider.deleteSubtaskFromGoal(goal.goalId, subtask.id!);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddSubtaskForm(BuildContext context, Goal goal, GoalProvider provider, int currentUserId) {
    final TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>(); // Her form için ayrı key tanımla

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Form(
        key: formKey,
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Yeni bir alt adım ekle...",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                style: const TextStyle(fontSize: 13),
                validator: (value) => (value == null || value.trim().isEmpty) ? "Başlık boş olamaz" : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_task_outlined, color: Colors.blue),
              tooltip: "Alt Adım Ekle",
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await provider.addSubtaskToGoal(
                    goal.goalId,
                    Subtask(goalId: goal.goalId, userId: currentUserId, title: controller.text.trim()),
                  );
                  controller.clear();
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReminderList(BuildContext context, Goal goal, GoalProvider provider) {
    final reminders = provider.getRemindersFor(goal.goalId);
    final isLoading = provider.isLoadingRemindersFor(goal.goalId);
    final error = provider.getReminderErrorFor(goal.goalId);

    if (isLoading && reminders.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
    if (error != null && reminders.isEmpty) return Text("Hatırlatıcılar yüklenemedi: $error", style: const TextStyle(color: Colors.red, fontSize: 12));
    if (reminders.isEmpty && !isLoading) return const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("Henüz hatırlatıcı eklenmemiş.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)));

    return Column(
      children: [
        if (isLoading && reminders.isNotEmpty) const Padding(padding: EdgeInsets.all(4.0), child: LinearProgressIndicator(minHeight: 2)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reminders.length,
          itemBuilder: (ctx, index) {
            final reminder = reminders[index];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              leading: Icon(reminder.isSent ? Icons.notifications_off_outlined : Icons.notifications_active_outlined, size: 18, color: reminder.isSent ? Colors.grey : Colors.orangeAccent),
              title: Text(DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(reminder.reminderTime), style: const TextStyle(fontSize: 13)),
              subtitle: reminder.message != null && reminder.message!.isNotEmpty ? Text(reminder.message!, style: const TextStyle(fontSize: 12)) : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: "Hatırlatıcıyı Sil",
                onPressed: () {
                  provider.deleteReminderFromGoal(goal.goalId, reminder.reminderId);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddReminderForm(BuildContext context, Goal goal, GoalProvider provider, int currentUserId) {
    final TextEditingController messageController = TextEditingController();
    final TextEditingController dateTimeController = TextEditingController(); // Sadece göstermek için
    DateTime? selectedDateTime;
    final formKey = GlobalKey<FormState>(); // Her form için ayrı key tanımla

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Her çağrıldığında yeni key oluşur.
          children: [ 
            TextFormField(
              controller: dateTimeController,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: "Tarih ve Saat Seçin",
                isDense: true,
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2101));
                if (date == null) return; // Kullanıcı iptal etti
                if (mounted) { // mounted kontrolü async işlemden sonra
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    dateTimeController.text = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(selectedDateTime!);
                  }
                }
              },
              validator: (value) => selectedDateTime == null ? "Tarih seçilmelidir" : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Kısa hatırlatma notu (ops.)",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_alarm_outlined, color: Colors.blue),
                  tooltip: "Hatırlatıcı Ekle",
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await provider.addReminderToGoal(
                        goal.goalId,
                        Reminder(
                          goalId: goal.goalId,
                          userId: currentUserId,
                          reminderTime: selectedDateTime!,
                          message: messageController.text.trim().isNotEmpty ? messageController.text.trim() : null,
                        ),
                      );
                      messageController.clear();
                      dateTimeController.clear();
                      selectedDateTime = null; // State'i sıfırla
                      FocusScope.of(context).unfocus(); // Klavyeyi kapat
                    }
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISuggestionSection(BuildContext context, Goal goal, GoalProvider provider) {
    // final theme = Theme.of(context); // Kullanılmıyor
    final suggestions = provider.getSuggestionsForGoal(goal.goalId);
    final isLoading = provider.isSuggestionLoading(goal.goalId);
    final error = provider.getSuggestionError(goal.goalId);

    // Web'deki sticky note görünümünü taklit etmeye çalışalım
    Color stickyNoteColor = const Color(0xFFFFFACD); // Limon sarısı
    Color stickyNoteBorderColor = const Color(0xFFFADF98);
    if (goal.analyzedEmotionPrimary != null) {
        final emotionLower = goal.analyzedEmotionPrimary!.toLowerCase();
        if (emotionLower.contains('pozitif')) { stickyNoteColor = const Color(0xFFF0FFF0); stickyNoteBorderColor = const Color(0xFFB3FFB3); }
        else if (emotionLower.contains('negatif')) { stickyNoteColor = const Color(0xFFFFF0F0); stickyNoteBorderColor = const Color(0xFFFFB3B3); }
        else if (emotionLower.contains('nötr')) { stickyNoteColor = const Color(0xFFF5F5F5); stickyNoteBorderColor = const Color(0xFFDCDCDC); }
        else if (emotionLower.contains('karışık')) { stickyNoteColor = const Color(0xFFFFF8E1); stickyNoteBorderColor = const Color(0xFFFFECB3); }
    }


    return Card(
      color: stickyNoteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: stickyNoteBorderColor, width: 1),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (isLoading)
              const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)),
            if (error != null && !isLoading)
              Padding(padding: const EdgeInsets.all(8.0), child: Text("Öneriler yüklenemedi: $error", style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
            if (!isLoading && error == null && suggestions.isEmpty)
              Column(
                children: [
                  const Text("Bu hedef için ilham almak ister misin?", style: TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.psychology_outlined, size: 18),
                    label: const Text("Bana Fikir Ver!", style: TextStyle(fontSize: 13)),
                    onPressed: () => provider.fetchGoalSuggestions(goal.goalId), // API endpoint'ini kontrol edin
                    style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
                  ),
                ],
              ),
            if (suggestions.isNotEmpty && !isLoading)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                itemBuilder: (ctx, index) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                    leading: Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade700),
                    title: Text(suggestions[index], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalActions(BuildContext context, Goal goal, GoalProvider provider, int currentUserId) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Durum Değiştirme Butonu
          TextButton.icon(
            icon: Icon(
              goal.isCompleted ? Icons.check_box_outlined : Icons.check_box_outline_blank_rounded,
              color: goal.isCompleted ? Colors.green : theme.colorScheme.onSurfaceVariant,
            ),
            label: Text(
              goal.isCompleted ? "Tamamlandı" : "Tamamla",
              style: TextStyle(color: goal.isCompleted ? Colors.green : theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            onPressed: () {
              provider.toggleGoalCompletion(goal.goalId, currentUserId);
            },
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap), // Daha kompakt dokunma alanı
          ),
          Row(
            children: [
              TextButton.icon(
                icon: Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.secondary),
                label: Text("Düzenle", style: TextStyle(fontSize: 13, color: theme.colorScheme.secondary)),
                onPressed: () => _navigateToEditGoal(goal),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                label: Text("Sil", style: TextStyle(fontSize: 13, color: theme.colorScheme.error)),
                onPressed: () => _showDeleteConfirmationDialog(context, goal, provider, currentUserId),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          )
        ],
      ),
    );
  }

   void _showDeleteConfirmationDialog(BuildContext context, Goal goal, GoalProvider goalProvider, int userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hedefi Sil'),
        content: Text('"${goal.title}" hedefini ve bağlı tüm detayları kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz!'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () { final nav = Navigator.of(dialogContext); if (nav.canPop()) nav.pop(); }
          ),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext); // Store navigator
              final scaffoldMessenger = ScaffoldMessenger.of(context); // Store ScaffoldMessenger
              bool success = await goalProvider.deleteGoal(goal.goalId, userId);
              if (navigator.canPop()) navigator.pop(); // Dialog'u kapat

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Hedef başarıyla silindi.' : goalProvider.goalError ?? 'Hedef silinemedi!'),
                  backgroundColor: success ? Colors.green : Colors.red, // scaffoldMessenger.showSnackBar(...)
                ),
              );
              // Ana liste zaten provider'ı dinlediği için otomatik güncellenecektir.
            },
          ),
        ],
      ),
    );
  }


  // --- ANA BUILD METODU ---
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final goalProvider = Provider.of<GoalProvider>(context);
    final theme = Theme.of(context);

    // Kullanıcı giriş kontrolü
    if (!authProvider.isLoggedIn || authProvider.userId == null) {
      // Bu durum normalde SplashScreen veya main.dart'ta ele alınır.
      // Buraya düşmemesi gerekir. Güvenlik için bir fallback.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Filtreleme için SegmentedButton state'i
    // SegmentedButton kendi state'ini yönettiği için _selectedFilter'a gerek yok,
    // onSelectionChanged içinde doğrudan kullanılabilir veya bir state variable'a atanabilir.
    // Şimdilik, _getFilteredAndSearchedGoals içinde doğrudan kullanacağız.
    // Ancak, SegmentedButton'ın `selected` parametresi bir Set<String> bekler.
    // Bu yüzden bir state variable tutmak daha iyi olabilir.
    // Veya, her build'de `_selectedFilter`'ı bir Set'e çevirebiliriz.
    // Basitlik için, SegmentedButton'ın dışına bir state variable ekleyelim.
    // Bu zaten en başta tanımlanmıştı, şimdi SegmentedButton'da kullanalım.
    // String _currentFilter = 'all'; // Bu state'i SegmentedButton yönetecek.

    final allGoals = goalProvider.goals;
    // SegmentedButton'ın seçili değerini almak için bir yol bulmamız lazım.
    // Ya da SegmentedButton'ı bir stateful widget içine alıp oradan yönetmek.
    // Şimdilik, _getFilteredAndSearchedGoals'a "all" geçelim ve SegmentedButton'ın
    // onSelectionChanged'ında setState ile UI'ı güncelleyelim.
    // Bu, _selectedFilter state variable'ını kullanmayı gerektirir.
    // _selectedFilter en başta tanımlı, onu kullanalım.

    // SegmentedButton için seçili segmenti tutacak bir state variable
    // Bu, _HomeScreenState içinde tanımlanmalı.
    // String _selectedFilterSegment = 'all'; // initState'te 'all' olarak ayarla

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest, // Daha açık arka plan
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_currentHeaderIcon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 10),
            const Text('Kontrol Merkezin'),
          ],
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (route) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshGoals,
        child: Column(
          children: [
            // Üst Başlık ve Karşılama
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba, ${authProvider.username ?? "Kaşif"}!',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Hayallerine giden yolda, her adımını planla.",
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  // Yeni hedef ekleme butonu buraya da konabilir veya sadece FAB kalabilir.
                ],
              ),
            ),

            // Dashboard Metrikleri
            _buildDashboardMetrics(context, allGoals),

            // Arama Çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Hedef ara (başlık, açıklama, kategori)...',
                  prefixIcon: const Icon(Icons.search_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0), // Daha modern
                    borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
                  ), // withOpacity yerine withAlpha
                  enabledBorder: OutlineInputBorder( // Odaklanılmamışken border
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.dividerColor.withAlpha(77)), // 0.3 opacity
                  ), // withOpacity yerine withAlpha
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer.withOpacity(0.8),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_outlined, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null, // withOpacity yerine withAlpha
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // Filtre Butonları (SegmentedButton)
            // SegmentedButton'ın seçili değerini yönetmek için bir state variable lazım.
            // Bu state variable'ı _HomeScreenState içinde tanımlayalım:
            // String _selectedFilterSegment = 'all'; // initState'te 'all' olarak ayarla
            // Ve onSelectionChanged'da setState ile güncelleyelim.
            // Bu zaten en başta _selectedFilter olarak tanımlı.

            // Hedef Listesi
            Expanded(
              child: goalProvider.isLoadingGoals && allGoals.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : goalProvider.goalError != null && allGoals.isEmpty
                      ? _buildErrorState(context, goalProvider.goalError!)
                      : _buildGoalList(context, _getFilteredAndSearchedGoals(allGoals, "all" /* TODO: _selectedFilterSegment'i buraya bağla */), authProvider),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddNewGoal,
          icon: const Icon(Icons.add_chart_outlined),
          label: const Text('Yeni Zirve Belirle'),
          tooltip: 'Yeni Bir Hedef Oluştur',
          backgroundColor: theme.colorScheme.primary, // Gradient yerine tek renk
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, color: theme.colorScheme.error, size: 64),
            const SizedBox(height: 20),
            Text(
              'Veriler yüklenirken bir sorun oluştu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Tekrar Dene'),
              onPressed: _refreshGoals,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGoalList(BuildContext context, List<Goal> displayedGoals, AuthProvider authProvider) {
    final theme = Theme.of(context);
    if (displayedGoals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assistant_photo_outlined, size: 64, color: theme.colorScheme.secondary.withOpacity(0.7)),
              const SizedBox(height: 20), // withOpacity yerine withAlpha
              Text(
                _searchController.text.isNotEmpty
                    ? 'Arama kriterlerinize uygun hedef bulunamadı.'
                    // : _selectedFilterSegment == 'all' // TODO: Filtreye göre mesaj
                    //     ? 'Henüz hiç hedef eklemediniz.'
                    //     : _selectedFilterSegment == 'completed'
                    //         ? 'Henüz tamamlanmış hedefiniz yok.'
                    //         : 'Aktif hedefiniz bulunmuyor.',
                    : 'Henüz hiç hedef eklemediniz.\nSağ alttaki "+" butonuna dokunarak başlayın!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), // FAB için boşluk
      itemCount: displayedGoals.length,
      itemBuilder: (context, index) {
        final goal = displayedGoals[index];
        // Kartların fade-in animasyonu için
        return AnimatedListItem(
          index: index,
          child: _buildGoalCard(context, goal, authProvider),
        );
      },
    );
  }
}

// --- YARDIMCI WIDGET'LAR ---

class _DashboardWidget extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final double? progressBarValue;

  const _DashboardWidget({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    this.progressBarValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            if (progressBarValue != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressBarValue, // withOpacity yerine withAlpha
                backgroundColor: iconColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Liste elemanları için basit bir fade-in animasyon widget'ı
class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const AnimatedListItem({super.key, required this.index, required this.child});

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Her eleman için hafif bir gecikmeyle animasyonu başlat
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
