class TaskStatistics {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final double completionRate;
  final int highPriorityTasks;
  final int mediumPriorityTasks;
  final int lowPriorityTasks;
  final double averageCompletionTime; // in days
  final int tasksCompletedThisWeek;
  final int tasksCompletedThisMonth;
  final Map<String, int> tasksByCategory;
  final Map<String, int> tasksCompletedByDay; // Last 7 days

  TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.completionRate,
    required this.highPriorityTasks,
    required this.mediumPriorityTasks,
    required this.lowPriorityTasks,
    required this.averageCompletionTime,
    required this.tasksCompletedThisWeek,
    required this.tasksCompletedThisMonth,
    required this.tasksByCategory,
    required this.tasksCompletedByDay,
  });

  factory TaskStatistics.empty() {
    return TaskStatistics(
      totalTasks: 0,
      completedTasks: 0,
      pendingTasks: 0,
      completionRate: 0.0,
      highPriorityTasks: 0,
      mediumPriorityTasks: 0,
      lowPriorityTasks: 0,
      averageCompletionTime: 0.0,
      tasksCompletedThisWeek: 0,
      tasksCompletedThisMonth: 0,
      tasksByCategory: {},
      tasksCompletedByDay: {},
    );
  }

  @override
  String toString() {
    return '''
TaskStatistics(
  total: $totalTasks,
  completed: $completedTasks,
  pending: $pendingTasks,
  completionRate: ${completionRate.toStringAsFixed(2)}%,
  highPriority: $highPriorityTasks,
  mediumPriority: $mediumPriorityTasks,
  lowPriority: $lowPriorityTasks
)
    ''';
  }
}
