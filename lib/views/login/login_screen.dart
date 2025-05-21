// lib/views/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_application1/providers/auth_provider.dart';
import 'package:flutter_application1/routes/app_routes.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
   void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose(); // <-- BU SATIR ÇOK ÖNEMLİ!
  }

  @override
  Widget build(BuildContext context) {
    // Hem state'i dinlemek hem de metot çağırmak için
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      // AppBar yerine doğrudan body kullanabiliriz
      // appBar: AppBar(title: const Text('Giriş Yap')),
      body: SafeArea( // Ekran çentikleri vb. için
        child: Center(
          child: SingleChildScrollView( // Klavye açılınca taşmayı önler
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Butonları genişletir
                children: [
                  // Logo veya Başlık
                  Icon(Icons.track_changes, size: 80, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 20),
                  Text('GoalMaster\'a Hoş Geldiniz!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 40),

                  // Kullanıcı Adı
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration( labelText: 'Kullanıcı Adı', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder(), ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Kullanıcı adı gerekli' : null,
                  ),
                  const SizedBox(height: 16),

                  // Şifre
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration( labelText: 'Şifre', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder(), ),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty) ? 'Şifre gerekli' : null,
                  ),
                  const SizedBox(height: 24),

                  // Hata Mesajı Alanı
                  if (authProvider.errorMessage != null) ...[
                    Text( authProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center,),
                    const SizedBox(height: 10),
                  ],

                  // Giriş Butonu (Yükleme durumu ile)
                  authProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Giriş Yap'),
                        onPressed: () async {
                          // Klavyeyi kapat
                          FocusScope.of(context).unfocus();
                          if (_formKey.currentState!.validate()) {
                            bool success = await authProvider.login( _usernameController.text.trim(), _passwordController.text, );
                            if (success && mounted) { // mounted kontrolü
                              Navigator.pushReplacementNamed(context, AppRoutes.home);
                            }
                            // Hata mesajı zaten provider tarafından gösterilecek
                          }
                        },
                        style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 12), textStyle: const TextStyle(fontSize: 16) ),
                      ),
                  const SizedBox(height: 16),

                  // Kayıt Ol Butonu
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Hesabınız yok mu? Kaydolun'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}