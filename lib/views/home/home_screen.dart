// lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatı için
import 'package:flutter_application1/models/goal.dart';
import 'package:flutter_application1/providers/auth_provider.dart';
import 'package:flutter_application1/providers/goal_provider.dart';
import 'package:flutter_application1/routes/app_routes.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // initState bittikten sonra hedefleri güvenli şekilde çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { _fetchGoalsInitial(); }
    });
  }

  // İlk hedef çekme işlemi
  Future<void> _fetchGoalsInitial() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      // Hata kontrolü Provider'da olduğu için burada try-catch gereksiz
      await Provider.of<GoalProvider>(context, listen: false).fetchGoals(authProvider.userId!);
    } else if (mounted) {
      // Eğer login değilse (beklenmedik durum), login'e yönlendir
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

   // Pull-to-refresh için hedef çekme işlemi
   Future<void> _refreshGoals() async {
     final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn && authProvider.userId != null) {
         await Provider.of<GoalProvider>(context, listen: false).fetchGoals(authProvider.userId!);
      }
   }

  @override
  Widget build(BuildContext context) {
    // Sadece çıkış butonu için AuthProvider (dinlemeden)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // GoalProvider'daki değişiklikleri dinlemek için Consumer
    return Consumer<GoalProvider>(
      builder: (context, goalProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(authProvider.username ?? 'Hedeflerim'), // Kullanıcı adı veya varsayılan
            actions: [
              IconButton( icon: const Icon(Icons.logout), tooltip: 'Çıkış Yap',
                onPressed: () async {
                  await authProvider.logout();
                  if (!mounted) return; // Async sonrası context kontrolü
                  // Tüm geçmişi temizleyerek login'e git
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                }, ), ], ),
          // Aşağı çekerek yenileme özelliği
          body: RefreshIndicator(
             onRefresh: _refreshGoals, // Yenileme fonksiyonunu bağla
             child: _buildBody(context, goalProvider), // İçeriği oluşturan metot
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
                // Ekleme ekranına git, geri dönüldüğünde yenileme ihtimali için .then
                Navigator.pushNamed(context, AppRoutes.addGoal).then((result) {
                   if (result == true) { // AddGoalScreen başarılı olursa true döner
                      _refreshGoals(); // Listeyi yenile
                   }
                });
            },
            tooltip: 'Yeni Hedef Ekle', child: const Icon(Icons.add), ),
        ); }, );
  }

  // Scaffold'un body'sini oluşturan metot
  Widget _buildBody(BuildContext context, GoalProvider goalProvider) {
    // Yükleme durumu (ilk yükleme veya refresh)
    if (goalProvider.isLoading && goalProvider.goals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // Hata durumu
    if (goalProvider.errorMessage != null) {
      return Center( child: Padding( padding: const EdgeInsets.all(16.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Hata:\n${goalProvider.errorMessage}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,),
              const SizedBox(height: 16),
              ElevatedButton.icon( onPressed: _refreshGoals, icon: const Icon(Icons.refresh), label: const Text("Tekrar Dene") ) ] ) ) );
    }
    // Hedef yok durumu
    if (goalProvider.goals.isEmpty) {
      return const Center(child: Padding( padding: EdgeInsets.all(16.0), child: Text('Henüz hiç hedef eklemediniz.\nEklemek için + butonuna dokunun.', textAlign: TextAlign.center,)));
    }

    // Hedef listesi
    return ListView.builder(
      itemCount: goalProvider.goals.length,
      itemBuilder: (context, index) {
        final goal = goalProvider.goals[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false); // userId için
        return Card( margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), elevation: 2,
          child: ListTile(
            // Başlık (üzeri çizili veya normal)
            title: Text(goal.title, style: TextStyle(decoration: goal.isCompleted ? TextDecoration.lineThrough : null)),
            // Alt başlık (Açıklama, Kategori, Tarih)
            subtitle: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (goal.description != null && goal.description!.isNotEmpty) Padding( padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text(goal.description!), ),
                Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, // Kategori ve tarihi ayır
                     children: [
                    if (goal.category != null && goal.category!.isNotEmpty) Chip(label: Text(goal.category!), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, backgroundColor: Theme.of(context).colorScheme.secondaryContainer,),
                    if (goal.targetDate != null) Text(DateFormat('dd/MM/yyyy').format(goal.targetDate!), style: Theme.of(context).textTheme.bodySmall),
                   ], ),
                 // İlerleme çubuğu (%0 veya %100 değilse göster)
                 if (goal.progress > 0 && goal.progress < 1.0 && !goal.isCompleted) Padding( padding: const EdgeInsets.only(top: 6.0), child: LinearProgressIndicator( value: goal.progress, minHeight: 6, borderRadius: BorderRadius.circular(3), ), ),
              ], ),
            // Tamamlama Checkbox'ı
            leading: Checkbox( value: goal.isCompleted,
              onChanged: (value) {
                if (value != null && authProvider.userId != null) {
                   goalProvider.toggleGoalCompletion(goal.goalId, authProvider.userId!);
                } }, ),
            // Silme Butonu
            trailing: IconButton( icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: 'Sil',
              onPressed: () { if(authProvider.userId != null) { _showDeleteConfirmation(context, goal, authProvider.userId!); } }, ),
            onTap: () { /* TODO: Detay Ekranı */ print('Goal tapped: ${goal.title}'); },
          ),
        ); }, );
  }

  // Silme Onayı Dialog'u
  void _showDeleteConfirmation(BuildContext context, Goal goal, int userId) {
     final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    showDialog( context: context, builder: (ctx) => AlertDialog(
        title: const Text('Hedefi Sil'), content: Text('"${goal.title}" hedefini kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton( child: const Text('İptal'), onPressed: () => Navigator.of(ctx).pop(),),
          TextButton( child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () async {
               Navigator.of(ctx).pop(); // Dialog'u kapat
               await goalProvider.deleteGoal(goal.goalId, userId); // Silme işlemini çağır
            }, ), ], ), );
  }
}