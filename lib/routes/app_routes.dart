import 'package:flutter/material.dart';
import 'package:flutter_application1/views/add_goal/add_goal_screen.dart';
import 'package:flutter_application1/views/home/home_screen.dart';
import 'package:flutter_application1/views/login/login_screen.dart'; // Yeni
import 'package:flutter_application1/views/register/register_screen.dart'; // Yeni
import 'package:flutter_application1/views/splash_screen.dart'; // Yeni (isteğe bağlı)

class AppRoutes {
  static const String home = '/home';
  static const String addGoal = '/add_goal';
  static const String login = '/login'; // Yeni
  static const String register = '/register'; // Yeni
  static const String splash = '/splash'; // Yeni (isteğe bağlı)

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    addGoal: (context) => const AddGoalScreen(),
    login: (context) => const LoginScreen(), // Yeni
    register: (context) => const RegisterScreen(), // Yeni
    splash: (context) => const SplashScreen(), // Yeni (isteğe bağlı)
  };
}