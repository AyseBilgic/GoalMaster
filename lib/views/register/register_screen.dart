// lib/views/register/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_application1/providers/auth_provider.dart';
import 'package:provider/provider.dart';

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

   @override
  void dispose() { /* ... controller'lar dispose edilir ... */ }

  @override
  Widget build(BuildContext context) {
     final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar( title: const Text('Hesap Oluştur'), ), // AppBar kalsın
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık
                 Text('Yeni Hesap Oluştur', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                 const SizedBox(height: 30),

                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration( labelText: 'Kullanıcı Adı', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder(), ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Kullanıcı adı gerekli' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration( labelText: 'E-posta Adresi', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder(), ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) { return 'E-posta gerekli'; }
                    if (!value.contains('@') || !value.contains('.')) { return 'Geçerli bir e-posta girin';}
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration( labelText: 'Şifre (min 6 karakter)', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder(), ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) { return 'Şifre gerekli'; }
                    if (value.length < 6) { return 'Şifre en az 6 karakter olmalı'; }
                    return null;
                  },
                ),
                 // TODO: Şifre Tekrarı Alanı Eklenebilir
                const SizedBox(height: 24),

                if (authProvider.errorMessage != null) ...[
                  Text( authProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center, ),
                  const SizedBox(height: 10),
                ],

                authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                       icon: const Icon(Icons.person_add_alt_1),
                       label: const Text('Kaydol'),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        if (_formKey.currentState!.validate()) {
                           bool success = await authProvider.register(
                              _usernameController.text.trim(),
                              _emailController.text.trim(),
                              _passwordController.text,
                           );
                           if (success && mounted) {
                              // Kayıt sonrası login ekranına yönlendir ve mesaj göster
                              ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.'), backgroundColor: Colors.green,)
                              );
                              Navigator.pop(context); // Login'e geri dön
                           }
                        }
                      },
                      style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 12), textStyle: const TextStyle(fontSize: 16) ),
                    ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context), // Geri dön
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