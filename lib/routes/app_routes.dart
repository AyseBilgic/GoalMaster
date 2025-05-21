// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

// Gerekli ekran sınıflarını import et
import '../views/add_goal/add_goal_screen.dart';
import '../views/edit_goal/edit_goal_screen.dart'; // EditGoalScreen'i kullanıyorsanız
import '../views/home/home_screen.dart';
import '../views/login/login_screen.dart';
import '../views/register/register_screen.dart';
import '../views/splash/splash_screen.dart'; // SplashScreen'i kullanıyorsanız
import '../views/suggestion/suggestion_screen.dart';
import '../views/goal_details/goal_detail_screen.dart'; // GoalDetailScreen importu

// Model sınıflarını import et (argümanlar için)
import '../models/goal.dart';

class AppRoutes {
  // --- Rota İsimleri (Statik Sabitler) ---
  static const String splash = '/'; // Genellikle başlangıç ekranı
  static const String login = '/login';
  static const String auth = '/auth'; // Login veya Register için genel bir yönlendirme olabilir
  static const String register = '/register';
  static const String home = '/home';
  static const String addGoal = '/add-goal'; // Hem yeni ekleme hem düzenleme için kullanılabilir
  static const String editGoal = '/edit-goal'; // Ayrı bir düzenleme ekranınız varsa
  static const String goalDetails = '/goal-details';
  static const String suggestions = '/suggestions';

  // --- MaterialApp'in `routes` parametresi için Map ---
  // Bu Map, argüman almayan, basit rotalar için kullanılır.
  // Argüman alan rotalar `onGenerateRoute` içinde ele alınmalıdır.
  static final Map<String, WidgetBuilder> routes = {
    // splash: (context) => const SplashScreen(), // Eğer `home` parametresi SplashScreen ise bu gereksiz
    login: (context) => const LoginScreen(),
    auth: (context) => const LoginScreen(), // Genellikle LoginScreen'e yönlendirir veya bir AuthWrapper widget'ı olabilir
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    // addGoal, editGoal, goalDetails, suggestions gibi argüman alanlar buradan kaldırıldı.
  };

  // --- MaterialApp'in `onGenerateRoute` parametresi için Metot ---
  // Bu metot, `Navigator.pushNamed` ile bir rota çağrıldığında ve bu rota
  // `routes` map'inde bulunmuyorsa veya argümanla çağrılıyorsa çalışır.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    debugPrint("[AppRoutes] generateRoute called for: ${settings.name} with arguments: ${settings.arguments}");

    switch (settings.name) {
      case splash: // Eğer SplashScreen'i de rota ile yönetmek isterseniz
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case addGoal:
        // AddGoalScreen hem yeni hedef ekleme hem de düzenleme için kullanılabilir.
        // Düzenleme için `goalToEdit` argümanı alır.
        final goalToEditForAdd = settings.arguments as Goal?; // Null olabilir
        return MaterialPageRoute(builder: (_) => AddGoalScreen(goalToEdit: goalToEditForAdd));

      case editGoal: // Eğer AddGoalScreen'i düzenleme için kullanıyorsanız bu case gereksiz olabilir.
                     // Ayrı bir EditGoalScreen'iniz varsa bu case'i kullanın.
        if (settings.arguments is Goal) {
          final goalToEdit = settings.arguments as Goal;
          // return MaterialPageRoute(builder: (_) => EditGoalScreen(goalToEdit: goalToEdit));
          // Eğer EditGoalScreen yerine AddGoalScreen'i düzenleme için kullanıyorsanız:
          return MaterialPageRoute(builder: (_) => AddGoalScreen(goalToEdit: goalToEdit));
        }
        debugPrint("[AppRoutes] HATA: /edit-goal rotası için geçersiz Goal argümanı.");
        return _errorRoute("Hedef düzenleme sayfası yüklenemedi.");

      case goalDetails:
        if (settings.arguments is Goal) {
          final goal = settings.arguments as Goal;
          return MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal));
        }
        debugPrint("[AppRoutes] HATA: /goal-details rotası için geçersiz Goal argümanı.");
        return _errorRoute("Hedef detayı yüklenemedi.");

      case suggestions:
        if (settings.arguments is int) {
          final goalId = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => SuggestionScreen(goalId: goalId));
        }
        debugPrint("[AppRoutes] HATA: /suggestions rotası için geçersiz goalId argümanı.");
        return _errorRoute("Öneriler yüklenemedi.");

      default:
        // Tanımlı olmayan bir rota için hata sayfası
        return _errorRoute("Sayfa bulunamadı: ${settings.name}");
    }
  }

  // --- Hata Rotası için Yardımcı Metot ---
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: Center(child: Text(message)),
      );
    });
  }
}