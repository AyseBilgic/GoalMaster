import 'package:flutter/material.dart';
import 'package:flutter_application1/providers/auth_provider.dart'; // Yeni
import 'package:flutter_application1/providers/goal_provider.dart';
import 'package:flutter_application1/routes/app_routes.dart';
import 'package:flutter_application1/utils/theme.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()), // Yeni
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedef Takip Uygulaması',
      theme: appTheme,
      // initialRoute: AppRoutes.splash, // İsteğe bağlı splash screen
      initialRoute: AppRoutes.login, // Doğrudan login ekranıyla başla (şimdilik)
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false, // Debug banner'ını kaldır
    );
  }
}