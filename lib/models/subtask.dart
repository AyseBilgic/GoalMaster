          // lib/models/subtask.dart
          import 'package:flutter/foundation.dart';
          
          class Subtask {
            final int? id; // Backend tarafından atanır, nullable int
            final int goalId; // Ana hedefin ID'si
            final int userId; // Kullanıcının ID'si
            final String title;
            bool isCompleted;
            final DateTime? createdAt;
            final DateTime? updatedAt;
          
            Subtask({
              this.id,
              required this.goalId,
              required this.userId,
              required this.title,
              this.isCompleted = false,
              this.createdAt,
              this.updatedAt,
            });
          
            Subtask copyWith({
              int? id,
              int? goalId,
              int? userId,
              String? title,
              bool? isCompleted,
              DateTime? createdAt,
              DateTime? updatedAt,
            }) {
              return Subtask(
                id: id ?? this.id,
                goalId: goalId ?? this.goalId,
                userId: userId ?? this.userId,
                title: title ?? this.title,
                isCompleted: isCompleted ?? this.isCompleted,
                createdAt: createdAt ?? this.createdAt,
                updatedAt: updatedAt ?? this.updatedAt,
              );
            }
          
            factory Subtask.fromJson(Map<String, dynamic> json) {
              if (json['goal_id'] == null) {
                throw FormatException("Subtask.fromJson: 'goal_id' alanı eksik veya null.");
              }
              if (json['user_id'] == null) {
                throw FormatException("Subtask.fromJson: 'user_id' alanı eksik veya null.");
              }
          
              return Subtask(
                id: _parseNullableInt(json['id'] ?? json['subtask_id']),
                goalId: _parseInt(json['goal_id']),
                userId: _parseInt(json['user_id']),
                title: json['title'] as String? ?? 'Başlık Yok',
                isCompleted: _parseBool(json['is_completed']),
                createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
                updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
              );
            }
          
            Map<String, dynamic> toJson() {
              return {
                // 'id' alanı genellikle yeni oluştururken gönderilmez, backend atar.
                // Güncelleme yapılıyorsa ve id varsa gönderilebilir.
                if (id != null) 'id': id,
                'goal_id': goalId,
                'user_id': userId,
                'title': title,
                'is_completed': isCompleted,
                // createdAt ve updatedAt genellikle backend tarafından yönetilir.
              };
            }
          
            // --- Yardımcı Parse Fonksiyonları ---
            static int? _parseNullableInt(dynamic value) {
              if (value == null) return null;
              if (value is int) return value;
              if (value is String) return int.tryParse(value);
              if (value is double) return value.toInt();
              debugPrint("Subtask Uyarısı: Nullable int parse edilemedi: $value (tip: ${value.runtimeType})");
              return null;
            }
          
            static int _parseInt(dynamic value) {
              if (value == null) throw FormatException("Gerekli bir alan için null değer int'e parse edilemez.");
              if (value is int) return value;
              if (value is String) {
                final parsed = int.tryParse(value);
                if (parsed == null) throw FormatException("String '$value' int'e parse edilemedi.");
                return parsed;
              }
              if (value is double) return value.toInt();
              debugPrint("Subtask Uyarısı: Int parse edilemedi: $value (tip: ${value.runtimeType})");
              throw FormatException("Desteklenmeyen tip: ${value.runtimeType}");
            }
          
            static bool _parseBool(dynamic value) {
              if (value == null) return false;
              if (value is bool) return value;
              if (value is int) return value == 1;
              if (value is String) return value.toLowerCase() == 'true' || value == '1';
              debugPrint("Subtask Uyarısı: Bool parse edilemedi: $value (tip: ${value.runtimeType})");
              return false;
            }
          }