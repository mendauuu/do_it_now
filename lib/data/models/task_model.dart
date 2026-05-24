class Task {
  final int? id;
  final String title;
  final String description;
  final int priority;
  final bool isDone;
  final DateTime createdDate;
  final DateTime? completedDate;
  final DateTime? dueDate;
  final String category;
  final int createdTimestamp;
  final int? completedTimestamp;

  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isDone,
    required this.createdDate,
    this.completedDate,
    this.dueDate,
    this.category = 'General',
    required this.createdTimestamp,
    this.completedTimestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'is_done': isDone ? 1 : 0,
      'created_date': createdDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'category': category,
      'created_timestamp': createdTimestamp,
      'completed_timestamp': completedTimestamp,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      priority: map['priority'] as int? ?? 1,
      isDone: (map['is_done'] as int? ?? 0) == 1,
      createdDate: DateTime.parse(map['created_date'] as String),
      completedDate: map['completed_date'] != null
          ? DateTime.parse(map['completed_date'] as String)
          : null,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      category: map['category'] as String? ?? 'General',
      createdTimestamp: map['created_timestamp'] as int,
      completedTimestamp: map['completed_timestamp'] as int?,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    int? priority,
    bool? isDone,
    DateTime? createdDate,
    DateTime? completedDate,
    DateTime? dueDate,
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
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      createdTimestamp: createdTimestamp ?? this.createdTimestamp,
      completedTimestamp: completedTimestamp ?? this.completedTimestamp,
    );
  }

  @override
  String toString() =>
      'Task(id: $id, title: $title, priority: $priority, isDone: $isDone)';
}
