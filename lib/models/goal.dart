class Goal {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String category;
  bool isCompleted; // Tamamlandı mı?

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.category,
    this.isCompleted = false,
  });

    // Veritabanından/API'den gelen JSON'ı Goal nesnesine çevirme:
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      category: json['category'],
      isCompleted: json['isCompleted'] ?? false, // null gelirse false olsun
    );
  }

    // Goal nesnesini JSON'a çevirme (API'ye göndermek için)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(), // Tarihi string olarak kaydet
      'category': category,
      'isCompleted': isCompleted,
    };
  }

  //CopyWith methodu.  State management kullanırken nesneleri değiştirmek (immutable) için.
    Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? category,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}