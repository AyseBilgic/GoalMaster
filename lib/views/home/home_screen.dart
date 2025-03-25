import 'package:flutter/material.dart';
// import 'package:flutter_application1/models/goal.dart'; // Kullanılmıyor, sildim
import 'package:flutter_application1/providers/goal_provider.dart';
import 'package:flutter_application1/routes/app_routes.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key); // Key parametresi

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<GoalProvider>(context, listen: false).fetchGoals();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalProvider>(
      builder: (context, goalProvider, child) {
        final goals = goalProvider.goals;
        final isLoading = goalProvider.isLoading;
        final errorMessage = goalProvider.errorMessage;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hedeflerim'), // const eklendi
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator()) // const eklendi
              : errorMessage != null
                  ? Center(child: Text("Hata: $errorMessage"))
                  : goals.isEmpty
                      ? const Center(child: Text('Henüz hedefiniz yok.')) // const eklendi
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
            child: const Icon(Icons.add), // const eklendi
          ),
        );
      },
    );
  }
}