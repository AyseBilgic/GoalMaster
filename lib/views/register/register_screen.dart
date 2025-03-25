import 'package:flutter/material.dart';
import 'package:flutter_application1/providers/auth_provider.dart';
import 'package:flutter_application1/routes/app_routes.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController(); //Email Controller

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose(); //Email controller dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaydol'),
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
                controller: _emailController,  //Email TextFied
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress, //Klavye Tipi
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen Email Adresinizi Giriniz.';
                  }
                  if(!value.contains('@') || !value.contains('.')){  //Basit email format kontrolü
                      return "Geçersiz Email Adresi";
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
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifrenizi girin';
                  }
                  if(value.length < 6){  //Minimum şifre uzunluğu kontrolü
                    return "Şifre en az 6 Karakter Olmalıdır.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              authProvider.isLoading ? const CircularProgressIndicator() :
              ElevatedButton(
                onPressed: () async{
                  if (_formKey.currentState!.validate()) {
                    // Provider ile kaydol
                    await authProvider.register(_usernameController.text, _passwordController.text, _emailController.text);

                    if(authProvider.isLoggedIn){ //Kayıt başarılı ve giriş yapıldıysa:
                       if(!mounted) return;
                       Navigator.pushReplacementNamed(context, AppRoutes.home);
                    }
                  }
                },
                child: const Text('Kaydol'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Giriş ekranına geri dön
                },
                child: const Text('Zaten hesabınız var mı? Giriş yapın'),
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