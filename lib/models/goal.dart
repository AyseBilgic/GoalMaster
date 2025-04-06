// lib/models/goal.dart

class Goal {
  final int goalId;       // BIGINT -> int
  final int userId;       // BIGINT -> int
  final String title;      // VARCHAR -> String
  final String? description; // TEXT -> String? (nullable)
  final DateTime? targetDate;// DATE -> DateTime? (nullable)
  final bool isCompleted;  // TINYINT(1) -> bool
  final String? category;   // VARCHAR -> String? (nullable)
  final double progress;   // FLOAT -> double
  final DateTime? createdAt; // TIMESTAMP -> DateTime?
  final DateTime? updatedAt; // TIMESTAMP -> DateTime?

  Goal({
    required this.goalId,
    required this.userId,
    required this.title,
    this.description,
    this.targetDate,
    required this.isCompleted, // DB'de DEFAULT 0 var
    this.category,
    required this.progress, // DB'de DEFAULT 0.0 var
    this.createdAt,
    this.updatedAt,
  });

  // API'den gelen JSON Map'ini Goal objesine çevirir
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      goalId: _parseInt(json['goal_id']),
      userId: _parseInt(json['user_id']),
      title: json['title'] ?? 'Başlık Yok',
      description: json['description'] as String?,
      targetDate: _parseDate(json['target_date']),
      isCompleted: _parseBool(json['is_completed']),
      category: json['category'] as String?,
      progress: _parseDouble(json['progress']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  // Goal objesini API'ye göndermek için JSON'a çevirir (POST/PUT için)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId, // API user_id bekliyorsa
      'title': title,
      'description': description,
      'target_date': targetDate?.toIso8601String().split('T')[0], // YYYY-MM-DD
      'is_completed': isCompleted ? 1 : 0, // TINYINT(1) için 0/1
      'category': category,
      'progress': progress,
    };
  }

  // --- Statik Yardımcı Parse Fonksiyonları ---
  static int _parseInt(dynamic value) {
    if (value == null) return 0; if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt(); return 0;
  }
  static bool _parseBool(dynamic value) {
    if (value == null) return false; if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1'; return false;
  }
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0; if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0; return 0.0;
  }
  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    // Hem 'YYYY-MM-DD' hem de ISO formatını deneyebilir
    return DateTime.tryParse(value.toString());
  }
}