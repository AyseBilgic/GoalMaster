// lib/models/user.dart

class User {
  final int userId;
  final String username;
  final String email;
  // Şifre hash'i burada tutulmaz!

  User({
    required this.userId,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int? ?? 0, // Null kontrolü
      username: json['username'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? 'Unknown',
    );
  }
}