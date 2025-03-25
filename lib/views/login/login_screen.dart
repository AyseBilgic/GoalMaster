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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Yap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen kullanıcı adınızı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // Şifreyi gizle
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifrenizi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
               authProvider.isLoading ? const CircularProgressIndicator() :
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    //Provider ile Giriş Yap:
                   await authProvider.login(_usernameController.text, _passwordController.text);

                    if(authProvider.isLoggedIn){ //Giriş Başarılıysa
                        if(!mounted) return; //context hatasını engelle.
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                    }

                  }
                },
                child: const Text('Giriş Yap'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                child: const Text('Hesabınız yok mu? Kaydolun'),
              ),
                if(authProvider.errorMessage != null) ...[  //Hata mesajı varsa göster
                  const SizedBox(height: 10),
                  Text(authProvider.errorMessage!, style: TextStyle(color: Colors.red),)

                ]
            ],
          ),
        ),
      ),
    );
  }
}