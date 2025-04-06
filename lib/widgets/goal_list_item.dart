// lib/widgets/goal_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart'; // Provider'ı import et
import '../providers/auth_provider.dart'; // userId için

class GoalListItem extends StatelessWidget {
  final Goal goal;

  const GoalListItem({
    super.key,
    required this.goal,
  });

  // Silme onayı dialog'unu gösteren metot
  void _showDeleteConfirmation(BuildContext context, Goal goal, int userId) {
     final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hedefi Sil'),
        content: Text('"${goal.title}" hedefini kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () async {
               Navigator.of(ctx).pop(); // Dialog'u kapat
               // Provider üzerinden silme işlemini çağır
               await goalProvider.deleteGoal(goal.goalId, userId);
               // Hata mesajı Provider tarafından yönetilir
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId; // Null olabilir, kontrol et

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        // Başlık (üzeri çizili veya normal)
        title: Text(
          goal.title,
          style: TextStyle(
              decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w500),
        ),
        // Alt başlık (Açıklama, Kategori, Tarih, İlerleme)
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (goal.description != null && goal.description!.isNotEmpty)
                Text(goal.description!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6), // Boşluk
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (goal.category != null && goal.category!.isNotEmpty)
                    Chip(
                      label: Text(goal.category!),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                      side: BorderSide.none
                    ),
                  if (goal.targetDate != null)
                    Text(
                      DateFormat('dd/MM/yyyy').format(goal.targetDate!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                ],
              ),
              // İlerleme çubuğu
              if (goal.progress > 0 && !goal.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Tamamlama Checkbox'ı
        leading: Checkbox(
          value: goal.isCompleted,
          onChanged: (userId == null) ? null : (value) { // userId yoksa devre dışı
            if (value != null) {
              // Provider'daki doğru metodu çağır
              goalProvider.toggleGoalCompletion(goal.goalId, userId);
            }
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        // Silme Butonu
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Sil',
          onPressed: (userId == null) ? null : () { // userId yoksa devre dışı
             _showDeleteConfirmation(context, goal, userId);
          },
        ),
        onTap: () {
          // TODO: Detay ekranına gitmek için Navigator.pushNamed(...)
          print('Goal tapped: ${goal.title}');
        },
      ),
    );
  }
}