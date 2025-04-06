// lib/views/register/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application1/providers/auth_provider.dart';
// import 'package:flutter_application1/routes/app_routes.dart'; // Login'e yönlendirme için gerekebilir

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Şifre tekrarı
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Kayıt olma fonksiyonu
  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus(); // Klavyeyi kapat

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        _usernameController.text.trim(),
        _passwordController.text.trim(), // Şifreyi gönder
        _emailController.text.trim(), // Email'i gönder
      );

      if (success && mounted) {
        // Kayıt başarılıysa kullanıcıya bilgi ver ve login ekranına dön
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Lütfen giriş yapın.'),
            backgroundColor: Colors.green,
          ),
        );
        // Login ekranına geri dön (Register ekranını stack'ten çıkar)
        Navigator.pop(context);
        // VEYA Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
      // Hata mesajı Provider tarafından gösterilecek
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Oluştur'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 // Kullanıcı Adı
                 TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Kullanıcı Adı', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Kullanıcı adı gerekli.';
                    if (value.trim().length < 3) return 'Kullanıcı adı en az 3 karakter olmalı.';
                    // Başka kontroller eklenebilir (örn: boşluk içermemeli)
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // E-posta
                 TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta Adresi', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'E-posta gerekli.';
                    // Basit e-posta format kontrolü
                    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                    if (!emailRegex.hasMatch(value.trim())) return 'Geçerli bir e-posta adresi girin.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                 // Şifre
                 TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Şifre', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(),
                     suffixIcon: IconButton( icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)), ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Şifre gerekli.';
                    if (value.length < 6) return 'Şifre en az 6 karakter olmalı.';
                    // Daha güçlü şifre kontrolleri eklenebilir
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre Tekrarı
                 TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Şifre (Tekrar)', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(),
                    suffixIcon: IconButton( icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Şifreyi tekrar girin.';
                    if (value != _passwordController.text) return 'Şifreler eşleşmiyor.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Kayıt Butonu veya Yükleme İndikatörü
                 authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Kaydol'),
                      onPressed: _submitRegister,
                      style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 14),),
                    ),

                // Hata Mesajı
                 if (authProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text( authProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center,),
                    ),

                // Giriş Yap Butonu
                TextButton(
                  onPressed: authProvider.isLoading ? null : () => Navigator.pop(context), // Login ekranına dön
                  child: const Text('Zaten hesabınız var mı? Giriş yapın'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}