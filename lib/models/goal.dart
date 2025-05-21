// lib/models/goal.dart
import 'package:intl/intl.dart'; // Tarih formatlama için (gerekirse)

import 'subtask.dart';    // Subtask modelini import et
import 'reminder.dart';  // Reminder modelini import et

class Goal {
  final int goalId;       // Veritabanı: BIGINT AUTO_INCREMENT PRIMARY KEY
  final int userId;       // Veritabanı: BIGINT NOT NULL
  final String title;      // Veritabanı: VARCHAR(255) NOT NULL
  final String? description; // Veritabanı: TEXT (nullable)
  final DateTime? targetDate;// Veritabanı: DATE (nullable)
  final bool isCompleted;  // Veritabanı: TINYINT(1) DEFAULT 0
  final String? category;   // Veritabanı: VARCHAR(255) (nullable)
  final double progress;   // Veritabanı: FLOAT DEFAULT 0.0
  final DateTime? createdAt; // Veritabanı: TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  final DateTime? updatedAt; // Veritabanı: TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE ...
  final List<Subtask> subtasks;
  final List<Reminder> reminders; // Bu liste doğrudan Goal ile birlikte gelmeyebilir, ayrı çekilebilir.
  final String? emotionNotes; // add_goal_screen.dart ile uyumlu hale getirildi
  final String? analyzedEmotionPrimary;
  final String? analyzedEmotionDetailsJson;

  // Constructor (tüm zorunlu alanları içerir)
  Goal({
    required this.goalId,
    required this.userId,
    required this.title,
    this.description,
    this.targetDate,
    required this.isCompleted,
    this.category,
    required this.progress,
    this.createdAt,
    this.updatedAt,
    List<Subtask>? subtasks,
    List<Reminder>? reminders,
    this.emotionNotes,
    this.analyzedEmotionPrimary,
    this.analyzedEmotionDetailsJson,
  })  : subtasks = subtasks ?? [],
        reminders = reminders ?? [];

  // API'den gelen JSON Map'ini Goal objesine çeviren factory constructor
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      goalId: _parseInt(json['goal_id']),          // Veritabanı sütun adı
      userId: _parseInt(json['user_id']),          // Veritabanı sütun adı
      title: json['title'] as String? ?? 'Başlık Yok', // Null ise varsayılan ata
      description: json['description'] as String?,
      targetDate: _parseDate(json['target_date']),   // Veritabanı sütun adı
      isCompleted: _parseBool(json['is_completed']), // Veritabanı sütun adı
      category: json['category'] as String?,
      progress: _parseDouble(json['progress']),   // Veritabanı sütun adı
      createdAt: _parseDate(json['created_at']),   // Veritabanı sütun adı
      updatedAt: _parseDate(json['updated_at']),   // Veritabanı sütun adı
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((subtaskJson) =>
                  Subtask.fromJson(subtaskJson as Map<String, dynamic>))
              .toList() ??
          [],
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((reminderJson) =>
                  Reminder.fromJson(reminderJson as Map<String, dynamic>))
              .toList() ??
          [],
      emotionNotes: json['emotion_notes'] ?? json['feelings_notes'] as String?, // Eski ve yeni anahtarı destekle
      analyzedEmotionPrimary: json['analyzed_emotion_primary'] as String?,
      analyzedEmotionDetailsJson: json['analyzed_emotion_details_json'] as String?,
    );
  }

  // Goal objesini API'ye göndermek için JSON Map'ine çeviren metot (POST/PUT için)
  Map<String, dynamic> toJson() {
    // YYYY-MM-DD formatı için DateFormat kullanmak daha güvenli olabilir
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return {
      // goalId genellikle gönderilmez (yeni eklerken) veya URL'de belirtilir (güncellerken)
      'user_id': userId, // API user_id bekliyorsa eklenir
      'title': title,
      'description': description,
      // Tarih varsa formatla, yoksa null gönder
      'target_date': targetDate != null ? formatter.format(targetDate!) : null,
      'is_completed': isCompleted ? 1 : 0, // Veritabanı TINYINT(1) için 0/1
      'category': category,
      'progress': progress, // Değer 0.0 - 1.0 arası olmalı
      // createdAt ve updatedAt genellikle gönderilmez
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
      'emotion_notes': emotionNotes, // Backend'e gönderilecek anahtar
      'analyzed_emotion_primary': analyzedEmotionPrimary,
      'analyzed_emotion_details_json': analyzedEmotionDetailsJson,
    };
  }

  // Goal objesinin bir kopyasını oluştururken bazı alanları değiştirme metodu
  // (Örneğin, optimistic UI güncellemelerinde kullanışlı)
  Goal copyWith({
    int? goalId,
    int? userId,
    String? title,
    String? description, // Nullable yapmak için ? eklendi
    DateTime? targetDate, // Nullable yapmak için ? eklendi
    bool? isCompleted,
    String? category, // Nullable yapmak için ? eklendi
    double? progress,
    DateTime? createdAt, // Nullable yapmak için ? eklendi
    DateTime? updatedAt, // Nullable yapmak için ? eklendi
    List<Subtask>? subtasks,
    List<Reminder>? reminders,
    String? emotionNotes,
    String? analyzedEmotionPrimary,
    String? analyzedEmotionDetailsJson,
  }) {
    return Goal(
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
      reminders: reminders ?? this.reminders,
      emotionNotes: emotionNotes ?? this.emotionNotes,
      analyzedEmotionPrimary: analyzedEmotionPrimary ?? this.analyzedEmotionPrimary,
      analyzedEmotionDetailsJson: analyzedEmotionDetailsJson ?? this.analyzedEmotionDetailsJson,
    );
  }


  // --- Statik Yardımcı Parse Fonksiyonları ---
  // Bu fonksiyonlar, API'den gelen farklı veri tiplerini güvenli bir şekilde dönüştürür.

  static int _parseInt(dynamic value) {
    if (value == null) return 0; // Varsayılan veya hata? Projeye göre karar ver.
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt(); // Double gelirse int'e çevir
    print("Warning: Could not parse int from value: $value (type: ${value.runtimeType})");
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    // Veritabanından 0 veya 1 gelebilir (TINYINT)
    if (value is int) return value == 1;
    // API'den string "true"/"false" veya "1"/"0" gelebilir
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    print("Warning: Could not parse bool from value: $value (type: ${value.runtimeType})");
    return false;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble(); // Int gelirse double'a çevir
    if (value is String) return double.tryParse(value) ?? 0.0;
    print("Warning: Could not parse double from value: $value (type: ${value.runtimeType})");
    return 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    // Hem ISO 8601 (YYYY-MM-DDTHH:mm:ss...) hem de sadece YYYY-MM-DD formatını dene
    // Backend DATE döndürüyorsa sadece YYYY-MM-DD gelir.
    // Backend TIMESTAMP döndürüyorsa ISO formatı gelir.
    try {
      return DateTime.tryParse(value.toString());
    } catch (e) {
      print("Warning: Could not parse date from value: $value (type: ${value.runtimeType}) - Error: $e");
      return null;
    }
  }
}