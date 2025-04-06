// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application1/providers/auth_provider.dart';
import 'package:flutter_application1/providers/goal_provider.dart';
import 'package:flutter_application1/routes/app_routes.dart'; // Rotaları import et
// import 'package:flutter_application1/views/splash/splash_screen.dart'; // Artık burada gerek yok
import 'package:flutter_application1/utils/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, GoalProvider>(
          create: (context) => GoalProvider(),
          update: (context, auth, previousGoalProvider) {
            // print("ProxyProvider Update: Auth changed, updating GoalProvider. UserID: ${auth.userId}");
            previousGoalProvider!.updateAuth(null, auth.userId);
            return previousGoalProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'GoalMaster Mobil',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        // Düzeltme: home parametresini kaldır
        // home: const SplashScreen(),
        // Düzeltme: initialRoute kullanarak başlangıç rotasını belirt
        initialRoute: AppRoutes.splash, // '/' rotasını işaret eder
        // Düzeltme: routes parametresi AppRoutes'tan gelen map'i kullanır
        routes: AppRoutes.routes,
      ),
    );
  }
}