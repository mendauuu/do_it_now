import 'package:hive/hive.dart';

// part 'task_model.g.dart';

@HiveType(typeId: 1)
class Task {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int priority; // 1: Low, 2: Medium, 3: High

  @HiveField(4)
  final bool isDone;

  @HiveField(5)
  final DateTime createdDate;

  @HiveField(6)
  final DateTime? completedDate;

  @HiveField(7)
  final String category;

  @HiveField(8)
  final int createdTimestamp;

  @HiveField(9)
  final int? completedTimestamp;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isDone,
    required this.createdDate,
    this.completedDate,
    this.category = 'General',
    required this.createdTimestamp,
    this.completedTimestamp,
  });

  // Convert Task to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'is_done': isDone ? 1 : 0,
      'created_date': createdDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'category': category,
      'created_timestamp': createdTimestamp,
      'completed_timestamp': completedTimestamp,
    };
  }

  // Create Task from Map (from database)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      priority: map['priority'] ?? 1,
      isDone: map['is_done'] == 1,
      createdDate: DateTime.parse(map['created_date']),
      completedDate: map['completed_date'] != null
          ? DateTime.parse(map['completed_date'])
          : null,
      category: map['category'] ?? 'General',
      createdTimestamp: map['created_timestamp'],
      completedTimestamp: map['completed_timestamp'],
    );
  }

  // Create a copy of Task with modified fields
  Task copyWith({
    int? id,
    String? title,
    String? description,
    int? priority,
    bool? isDone,
    DateTime? createdDate,
    DateTime? completedDate,
    String? category,
    int? createdTimestamp,
    int? completedTimestamp,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      createdDate: createdDate ?? this.createdDate,
      completedDate: completedDate ?? this.completedDate,
      category: category ?? this.category,
      createdTimestamp: createdTimestamp ?? this.createdTimestamp,
      completedTimestamp: completedTimestamp ?? this.completedTimestamp,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: $priority, isDone: $isDone)';
  }
}
