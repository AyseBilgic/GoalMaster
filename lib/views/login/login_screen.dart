// lib/views/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application1/providers/auth_provider.dart';
import 'package:flutter_application1/routes/app_routes.dart'; // Rotalar için

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true; // Şifre görünürlüğü için

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Giriş yapma fonksiyonu
  Future<void> _submitLogin() async {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      // Giriş başarılıysa ve widget hala ekrandaysa Ana ekrana git
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
      // Hata mesajı zaten AuthProvider dinlenerek gösterilecek (build metodu içinde)
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthProvider'ı dinle (isLoading ve errorMessage için)
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      // AppBar isteğe bağlı, kaldırılabilir
      // appBar: AppBar(
      //   title: const Text('Giriş Yap'),
      // ),
      body: Center( // İçeriği ortalamak için
        child: SingleChildScrollView( // Klavye açılınca taşmayı engeller
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Dikeyde ortala
              crossAxisAlignment: CrossAxisAlignment.stretch, // Yatayda genişlet
              children: [
                // Logo veya Başlık (Opsiyonel)
                Icon(Icons.track_changes, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'GoalMaster\'a Hoş Geldiniz!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),

                // Kullanıcı Adı Alanı
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen kullanıcı adınızı girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre Alanı
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    // Şifreyi göster/gizle butonu
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword, // Şifreyi gizle
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifrenizi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Giriş Butonu veya Yükleme İndikatörü
                authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Giriş Yap'),
                      onPressed: _submitLogin, // Giriş fonksiyonunu çağır
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                const SizedBox(height: 12),

                 // Hata Mesajı Alanı
                 if (authProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),

                // Kayıt Ol Butonu
                TextButton(
                  onPressed: authProvider.isLoading ? null : () { // Yükleniyorsa butonu devre dışı bırak
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  child: const Text('Hesabınız yok mu? Kaydolun'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}