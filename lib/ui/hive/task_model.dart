import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
class TaskModel {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int priority;

  @HiveField(4)
  bool isDone;

  /// The SQL row id — stored after first write so we can update/delete by id
  /// instead of fragile array index.
  @HiveField(5)
  int? sqlId;

  /// Optional due date stored properly (not appended to description string)
  @HiveField(6)
  DateTime? dueDate;

  /// Category
  @HiveField(7)
  String category;

  TaskModel({
    required this.title,
    required this.description,
    required this.date,
    required this.priority,
    required this.isDone,
    this.sqlId,
    this.dueDate,
    this.category = 'General',
  });

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? date,
    int? priority,
    bool? isDone,
    int? sqlId,
    DateTime? dueDate,
    String? category,
  }) {
    return TaskModel(
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      sqlId: sqlId ?? this.sqlId,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
    );
  }
}
