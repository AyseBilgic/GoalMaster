// lib/routes/app_routes.dart
import 'package:flutter/widgets.dart';
// Ekranları import et
import 'package:flutter_application1/views/splash/splash_screen.dart';
import 'package:flutter_application1/views/login/login_screen.dart';
import 'package:flutter_application1/views/register/register_screen.dart';
import 'package:flutter_application1/views/home/home_screen.dart';
import 'package:flutter_application1/views/add_goal/add_goal_screen.dart';

class AppRoutes {
  // Rota isimleri
  static const String splash = '/'; // Düzeltme: Başlangıç rotası '/' olmalı
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String addGoal = '/add_goal';

  // Rotalar map'i
  static Map<String, WidgetBuilder> get routes {
    return {
      // Düzeltme: '/' rotası için SplashScreen tanımlı olmalı
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      home: (context) => const HomeScreen(),
      addGoal: (context) => const AddGoalScreen(),
    };
  }
}