// lib/models/reminder.dart
import 'package:flutter/foundation.dart'; // UniqueKey için

class Reminder {
  final String reminderId; // Backend'den gelen ID (String veya int olabilir, String daha esnek)
  final int userId;       // Bu hatırlatıcının sahibi
  final int? goalId;      // Bağlı olduğu ana hedefin ID'si (opsiyonel)
  final int? subtaskId;   // Bağlı olduğu alt görevin ID'si (opsiyonel)
  final DateTime reminderTime; // Hatırlatma zamanı
  final String? message;    // Hatırlatma mesajı
  bool isSent;         // Gönderilip gönderilmediği (backend'de is_sent TINYINT(1))
  final DateTime? createdAt;  // Oluşturulma tarihi (backend'den gelir)

  Reminder({
    String? reminderId, // Artık nullable ve varsayılan değer alacak
    required this.userId,
    this.goalId,
    this.subtaskId,
    required this.reminderTime,
    this.message,
    this.isSent = false, // Varsayılan olarak gönderilmemiş
    this.createdAt,
  }) : reminderId = reminderId ?? UniqueKey().toString(); // reminderId null ise UniqueKey ata

  // copyWith metodu, bazı alanları değiştirerek yeni bir Reminder objesi oluşturur
  Reminder copyWith({
    String? reminderId,
    int? userId,
    int? goalId,
    int? subtaskId,
    DateTime? reminderTime,
    String? message,
    bool? isSent,
    DateTime? createdAt,
  }) {
    return Reminder(
      reminderId: reminderId ?? this.reminderId,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      subtaskId: subtaskId ?? this.subtaskId,
      reminderTime: reminderTime ?? this.reminderTime,
      message: message ?? this.message, // Eğer message null ise null kalır
      isSent: isSent ?? this.isSent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // API'den gelen JSON'ı Reminder objesine çevirir
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      // reminder_id backend'den int olarak geliyorsa String'e çevir
      reminderId: _parseStringId(json['reminder_id']),
      userId: _parseInt(json['user_id']),
      goalId: json['goal_id'] != null ? _parseInt(json['goal_id']) : null,
      subtaskId: json['subtask_id'] != null ? _parseInt(json['subtask_id']) : null,
      // reminder_time backend'den ISO 8601 string olarak gelmeli
      reminderTime: DateTime.parse(json['reminder_time'] as String),
      message: json['message'] as String?,
      isSent: _parseBool(json['is_sent']), // Backend'den 0/1 veya true/false gelebilir
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  // Reminder objesini API'ye göndermek için JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      // reminderId genellikle yeni oluştururken gönderilmez, backend atar
      // 'reminder_id': reminderId,
      'user_id': userId,
      if (goalId != null) 'goal_id': goalId,
      if (subtaskId != null) 'subtask_id': subtaskId,
      'reminder_time': reminderTime.toIso8601String(), // ISO formatında gönder
      'message': message,
      'is_sent': isSent, // Backend bool veya 0/1 bekleyebilir (true/false daha yaygın JSON'da)
      // createdAt backend tarafından yönetilir, gönderilmez
    };
  }

  // --- Yardımcı Parse Fonksiyonları ---
  static String _parseStringId(dynamic value) {
    if (value == null) return UniqueKey().toString(); // ID yoksa geçici bir ID ata
    return value.toString();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0; // Veya hata fırlat
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

   static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}