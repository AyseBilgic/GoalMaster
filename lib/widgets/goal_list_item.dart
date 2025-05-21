// lib/widgets/goal_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'package:provider/provider.dart'; // Provider için

import '../models/goal.dart'; // Goal modeli
import '../providers/goal_provider.dart'; // GoalProvider
import '../providers/auth_provider.dart'; // AuthProvider (isLoggedIn ve userId için)
// import '../routes/app_routes.dart'; // Rotalar (detay ekranı için) - Kullanılmıyorsa kaldırılabilir

// Tek bir hedef öğesini liste içinde göstermek için kullanılan StatelessWidget
class GoalListItem extends StatelessWidget {
  final Goal goal; // Gösterilecek hedef verisi

  // Constructor
  const GoalListItem({
    super.key,
    required this.goal, // Dışarıdan goal objesi alır
  });

  // Silme onayı dialogunu gösteren metot
  void _showDeleteConfirmation(BuildContext context, Goal goal, int currentUserId) {
    // Provider'a erişim (listen:false çünkü sadece metot çağıracağız)
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    showDialog(
      context: context, // Dialogu göstermek için GoalListItem'in context'i
      builder: (dialogCtx) => AlertDialog( // dialogCtx, AlertDialog'un kendi context'i
        title: const Text('Hedefi Sil'),
        content: Text(
            '"${goal.title}" hedefini kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(dialogCtx).pop(), // Dialogu kapat
          ),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(dialogCtx).pop(); // Dialogu kapat

              // Provider üzerinden silme işlemini çağır
              // GoalProvider'daki deleteGoal metodu currentUserId bekliyor.
              bool success = await goalProvider.deleteGoal(goal.goalId, currentUserId);

              // SnackBar'ı göstermek için GoalListItem'in ana context'ini kullan
              // Bu context'in hala geçerli olduğunu varsayıyoruz (widget ağaçta).
              // Daha karmaşık senaryolarda state yönetimi üzerinden mesajlaşma tercih edilebilir.
              if (context.mounted) { // Widget'ın hala ağaçta olup olmadığını kontrol et
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Hedef başarıyla silindi.'
                        : goalProvider.goalError ?? 'Hedef silinemedi!'),
                    backgroundColor: success ? Colors.green : Colors.red, // Başarı için yeşil renk
                  ),
                );
              }
              // Silme sonrası HomeScreen'in listeyi yenilemesi Provider dinlediği için otomatik olmalı.
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider'lara erişim (listen:false çünkü sadece metotları çağıracağız veya bir kerelik okuma yapacağız)
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final authProvider = context.read<AuthProvider>(); // Değişiklikleri dinlemeden okuma
    final bool isLoggedIn = authProvider.isLoggedIn;
    final int? currentUserId = authProvider.userId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1.5, // Daha hafif gölge
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Köşe yuvarlaklığı
      clipBehavior: Clip.antiAlias, // İçeriğin taşmasını önler
      child: ListTile(
        // Tamamlama Checkbox'ı (Önde)
        leading: Checkbox(
          value: goal.isCompleted,
          // Giriş yapılmamışsa veya kullanıcı ID'si yoksa onChanged null (pasif)
          onChanged: (isLoggedIn && currentUserId != null)
              ? (value) {
                  if (value != null) {
                    // GoalProvider'daki toggleGoalCompletion metodu currentUserId bekliyor.
                    goalProvider.toggleGoalCompletion(goal.goalId, currentUserId);
                  }
                }
              : null,
          // Temadan renkleri alır
        ),
        // Başlık (Üzeri çizili veya normal)
        title: Text(
          goal.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600, // Biraz daha kalın
                decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                color: goal.isCompleted ? Colors.grey.shade600 : null,
              ),
          maxLines: 2, // En fazla 2 satır
          overflow: TextOverflow.ellipsis, // Sığmazsa ...
        ),
        // Alt başlık (Açıklama, Kategori, Tarih, İlerleme)
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0), // Başlıkla arası boşluk
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Açıklama (varsa)
              if (goal.description != null && goal.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0), // Alt boşluk
                  child: Text(
                    goal.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Kategori ve Tarih (Aynı satırda)
              Row(
                children: [
                  // Kategori (varsa)
                  if (goal.category != null && goal.category!.isNotEmpty)
                    Chip(
                      label: Text(goal.category!),
                      padding: const EdgeInsets.symmetric(horizontal: 6), // Daha sıkı padding
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Tıklama alanı
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                      side: BorderSide.none, // Kenarlık yok
                    ),
                  const Spacer(), // Aradaki boşluğu doldurur
                  // Hedef Tarih (varsa)
                  if (goal.targetDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd.MM.yy').format(goal.targetDate!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
              // İlerleme Çubuğu (tamamlanmadıysa ve ilerleme varsa)
              if (goal.progress > 0 && !goal.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(
                    value: goal.progress, // 0.0 - 1.0 arası değer
                    minHeight: 6, // Kalınlık
                    borderRadius: BorderRadius.circular(3), // Yuvarlak köşeler
                  ),
                ),
              // Alt görev ve hatırlatıcı sayısı (opsiyonel)
              if (goal.subtasks.isNotEmpty || goal.reminders.isNotEmpty) // Goal modelinde bu alanların olduğundan emin olun
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      if (goal.subtasks.isNotEmpty) // Goal modelinde bu alanların olduğundan emin olun
                        Text('${goal.subtasks.length} alt görev', style: Theme.of(context).textTheme.bodySmall),
                      if (goal.subtasks.isNotEmpty && goal.reminders.isNotEmpty) // Goal modelinde bu alanların olduğundan emin olun
                        const Text(' • ', style: TextStyle(fontSize: 10)),
                      if (goal.reminders.isNotEmpty) // Goal modelinde bu alanların olduğundan emin olun
                        Text('${goal.reminders.length} hatırlatıcı', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),),
            ],
          ),
        ),
        // Silme Butonu (Sonda)
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Sil',
          // Giriş yapılmamışsa veya kullanıcı ID'si yoksa pasif
          onPressed: (isLoggedIn && currentUserId != null)
              ? () => _showDeleteConfirmation(context, goal, currentUserId)
              : null,
        ),
        onTap: () {
          // Hedef detay ekranına git
          Navigator.pushNamed(
            context,
            // AppRoutes.goalDetail, // HATA: AppRoutes.goalDetail tanımlı değil.
            // ÖNERİLEN DÜZELTME: AppRoutes.goalDetail sabitini c:\src\flutter_application1\lib\routes\app_routes.dart dosyasında tanımlayın.
            // Örnek: static const String goalDetail = '/goal_detail';
            // Geçici çözüm olarak veya rota adının bu olduğundan eminseniz:
            '/goal_detail', // Bu string'in app_routes.dart dosyasındaki routes Map'inde bir ekrana karşılık geldiğinden emin olun.
            arguments: goal, // GoalDetailScreen'e goal nesnesini gönder
          );
          debugPrint('Goal tapped: ${goal.title}, Navigating to detail screen.');
        },
      ),
    );
  }
}
