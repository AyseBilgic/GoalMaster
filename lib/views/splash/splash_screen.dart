// lib/views/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application1/providers/auth_provider.dart';
import 'package:flutter_application1/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // initState bittikten sonra kontrolü başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkLoginStatusAndNavigate();
    });
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    // Gerekirse kısa bir bekleme (logo vs. göstermek için)
    // await Future.delayed(const Duration(seconds: 1));

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Otomatik giriş denemesi
      bool isLoggedIn = await authProvider.tryAutoLogin();

      // Widget hala ağaçta mı diye kontrol et (önemli!)
      if (!mounted) return;

      // Duruma göre yönlendir
      if (isLoggedIn) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (error) {
       // Otomatik giriş sırasında bir hata olursa (örn: ağ hatası, beklenmedik durum)
       // yine de login ekranına yönlendirmek genellikle en güvenlisidir.
       print("Error during auto-login check: $error");
       if (!mounted) return;
       Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basit bir yükleniyor ekranı
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'GoalMaster Yükleniyor...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}