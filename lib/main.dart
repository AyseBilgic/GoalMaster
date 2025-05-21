// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tarih formatlama için
import 'package:provider/provider.dart';

// --- Kendi Dosyalarını Import Et ---
// Providerlar
import 'package:flutter_application1/providers/auth_provider.dart';
import 'package:flutter_application1/providers/goal_provider.dart';
// Rotalar
import 'package:flutter_application1/routes/app_routes.dart';
// Ekranlar
import 'package:flutter_application1/views/splash/splash_screen.dart'; // Başlangıç ekranı
// Utils (Tema vb.)
import 'package:flutter_application1/utils/theme.dart'; // Tema dosyan varsa

// --- Uygulama Başlangıcı ---
void main() async { // main fonksiyonunu async yap
  // runApp öncesi async işlemler için bu satır gerekli:
  WidgetsFlutterBinding.ensureInitialized();
  // Tarih formatlama için lokasyon verilerini yükle (örneğin Türkçe için 'tr_TR')
  // Uygulamanızda desteklemek istediğiniz tüm lokasyonları burada initialize edebilirsiniz.
  await initializeDateFormatting('tr_TR', null);
  runApp(const MyApp());
}

// --- Ana Uygulama Widget'ı ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // State yönetimi için Provider'ları en üste yerleştir
    return MultiProvider(
      providers: [
        // 1. AuthProvider: Bağımsız olarak oluşturulur.
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
          // lazy: false, // Uygulama başlar başlamaz oluşturulsun (opsiyonel)
        ),

        // 2. GoalProvider: AuthProvider'a bağımlıdır (userId için).
        //    ChangeNotifierProxyProvider kullanılır.
        ChangeNotifierProxyProvider<AuthProvider, GoalProvider>(
          // create: Başlangıçta bir GoalProvider örneği oluşturur.
          //         Bu context, henüz AuthProvider'ı İÇERMEZ.
          create: (context) => GoalProvider(),

          // update: AuthProvider (auth) veya GoalProvider (previousGoalProvider)
          //         değiştiğinde veya ilk oluşturulduğunda çalışır.
          //         Bu context, artık AuthProvider'a erişebilir.
          update: (context, auth, previousGoalProvider) {
            // previousGoalProvider null olmamalı, ! ile erişebiliriz.
            print("ProxyProvider Update: Auth changed? ${auth.isLoggedIn}, UserID: ${auth.userId}"); // Debug

            // GoalProvider'daki updateAuth metodunu çağırarak kimlik bilgilerini ilet.
            // Bu metot GoalProvider içinde tanımlı olmalı.
            previousGoalProvider!.updateAuth(
                null, // Token (şimdilik null)
                auth.userId // AuthProvider'dan gelen güncel userId
            );

            // Güncellenmiş GoalProvider'ı widget ağacına geri ver.
            return previousGoalProvider;
          },
          // lazy: false, // AuthProvider hazır olur olmaz oluşturulsun (opsiyonel)
        ),

        // Başka Provider'lar varsa buraya eklenebilir:
        // ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],

      // MultiProvider'ın alt widget'ı MaterialApp
      child: MaterialApp(
        title: 'GoalMaster',
        theme: appTheme, // Tema (theme.dart içinde tanımlı olmalı)
        debugShowCheckedModeBanner: false, // Debug etiketini kaldır

        // --- Rota Yönetimi ---
        // Başlangıç Ekranı: Uygulama ilk açıldığında bu gösterilir.
        // Bu, '/' (kök) rotasını otomatik olarak yönetir.
        home: const SplashScreen(),

        // İsimlendirilmiş Rotalar: Diğer sayfalar için kullanılır.
        // AppRoutes.routes Map'i routes/app_routes.dart içinde tanımlanır.
        // `onGenerateRoute` kullanıldığı için `routes` genellikle gereksizdir
        // ve tüm rotalar onGenerateRoute ile yönetiliyorsa kaldırılabilir.
        // routes: AppRoutes.routes, // Bu satırı yorumlayabilir veya silebilirsiniz.

        // Dinamik ve argümanlı rotalar için onGenerateRoute kullanılır.
        onGenerateRoute: AppRoutes.generateRoute,

        // Bilinmeyen Rota Yönetimi (onGenerateRoute içinde zaten ele alınıyor):
        // Tanımlı olmayan bir rotaya gidilmeye çalışılırsa fallback.
        onUnknownRoute: (settings) {
          print("Bilinmeyen Rota Denemesi: ${settings.name}");
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Hata')),
              body: Center(child: Text('Sayfa bulunamadı: ${settings.name}')),
            ),
          );
        },
      ),
    );
  }
}