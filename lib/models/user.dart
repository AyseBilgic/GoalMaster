// c:\Users\ablgc\OneDrive\Masaüstü\hedeftakip\goal-tracker\mobil\lib\models\user.dart
class User {
  final String id;
  final String username;
  final String email;
  // Web projenizdeki User modeline göre diğer alanları ekleyebilirsiniz

  User({
    required this.id,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Backend'den 'user_id' olarak gelen ve sayı olabilen ID'yi
      // String'e çevirip modeldeki 'id' alanına atıyoruz.
      id: json['user_id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
    );
  }
}