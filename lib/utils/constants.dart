// lib/utils/constants.dart
import 'dart:io' show Platform;

// API Temel URL'si
// Android Emulator için 10.0.2.2, diğer platformlar için localhost
// Gerçek cihazda test ederken bilgisayarınızın IP adresini kullanın
final String apiBaseUrl = Platform.isAndroid ? 'http://10.0.2.2:8080/api' : 'http://localhost:8080/api';

// Rota İsimleri (AppRoutes ile senkronize olmalı)
class AppRouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String addGoal = '/add_goal';
  // static const String goalDetail = '/goal_detail'; // Gelecekteki rotalar
}

// Diğer sabitler (renkler, metin stilleri vb.) buraya eklenebilir
// Örneğin:
// import 'package:flutter/material.dart';
// const Color primaryColor = Colors.blue;
// const Color accentColor = Colors.amber;