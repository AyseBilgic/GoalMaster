import 'package:flutter/material.dart';
import 'package:flutter_application1/providers/auth_provider.dart'; // AuthProvider'ı import et
import 'package:flutter_application1/providers/goal_provider.dart';
import 'package:flutter_application1/routes/app_routes.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
     // Oturum açmış kullanıcı için hedefleri yükle
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if(authProvider.isLoggedIn){
       Provider.of<GoalProvider>(context, listen: false).fetchGoals();
    }

  }


    @override
    Widget build(BuildContext context) {
    //Provider ile Kullanıcı Bilgilerine Eriş
    final authProvider = Provider.of<AuthProvider>(context);

    //Eğer Kullanıcı Giriş Yapmamışsa, Login Ekranına Yönlendir. (Veya Boş Ekran Göster)
     if (!authProvider.isLoggedIn) {
          // return  const Center(child: Text("Lütfen Giriş Yapın"),); //Boş Ekran
          //Ya da Login Ekranına Yönlendir:
          WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
           });
          return const SizedBox.shrink(); //Boş bir widget döndür.

      }


    return Consumer<GoalProvider>(
      builder: (context, goalProvider, child) {
        final goals = goalProvider.goals;
        final isLoading = goalProvider.isLoading;
        final errorMessage = goalProvider.errorMessage;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hedeflerim'),
             actions: [
              IconButton(icon: const Icon(Icons.logout), onPressed: () async{ //Çıkış Yap butonu
                 await authProvider.logout();  //AuthProvider ile çıkış yap
                  if(!mounted) return;
                  Navigator.pushReplacementNamed(context, AppRoutes.login); //Login Ekranına Git
              },)
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: Text("Hata: $errorMessage"))
                  : goals.isEmpty
                      ? const Center(child: Text('Henüz hedefiniz yok.'))
                      : ListView.builder(
                          itemCount: goals.length,
                          itemBuilder: (context, index) {
                            final goal = goals[index];
                            return ListTile(
                              title: Text(goal.title),
                              subtitle: Text(goal.description),
                              trailing: Checkbox(
                                value: goal.isCompleted,
                                onChanged: (value) {
                                  goalProvider.toggleComplete(
                                      goal.id); // Provider ile tamamla/tamamlama
                                },
                              ),
                              onTap: () {
                                // TODO: Hedef detay sayfasına yönlendir (istersen)
                              },
                            );
                          },
                        ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addGoal);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}