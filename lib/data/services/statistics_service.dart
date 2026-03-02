import 'package:intl/intl.dart';
import 'package:do_it_now/data/models/task_model.dart';
import 'package:do_it_now/data/models/task_statistics.dart';
import 'package:do_it_now/data/repositories/task_repository.dart';

class StatisticsService {
  final TaskRepository _taskRepository;

  StatisticsService({required TaskRepository taskRepository})
      : _taskRepository = taskRepository;

  /// Get all-time statistics
  Future<TaskStatistics> getStatistics() async {
    try {
      final allTasks = await _taskRepository.getAllTasks();
      return _calculateStatistics(allTasks);
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }

  /// Get statistics for the current week
  Future<TaskStatistics> getWeeklyStatistics() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final weeklyTasks =
          await _taskRepository.getTasksByDateRange(startOfWeek, endOfWeek);

      return _calculateStatistics(weeklyTasks);
    } catch (e) {
      throw Exception('Failed to fetch weekly statistics: $e');
    }
  }

  /// Get statistics for the current month
  Future<TaskStatistics> getMonthlyStatistics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(days: 1));

      final monthlyTasks =
          await _taskRepository.getTasksByDateRange(startOfMonth, endOfMonth);

      return _calculateStatistics(monthlyTasks);
    } catch (e) {
      throw Exception('Failed to fetch monthly statistics: $e');
    }
  }

  /// Calculate statistics from a list of tasks
  TaskStatistics _calculateStatistics(List<Task> tasks) {
    if (tasks.isEmpty) {
      return TaskStatistics.empty();
    }

    final completedTasks = tasks.where((t) => t.isDone).toList();
    final pendingTasks = tasks.where((t) => !t.isDone).toList();

    final completionRate =
        tasks.isEmpty ? 0.0 : (completedTasks.length / tasks.length) * 100;

    // Priority distribution
    final highPriority = tasks.where((t) => t.priority == 3).length;
    final mediumPriority = tasks.where((t) => t.priority == 2).length;
    final lowPriority = tasks.where((t) => t.priority == 1).length;

    // Average completion time (only for completed tasks)
    double averageCompletionTime = 0.0;
    if (completedTasks.isNotEmpty) {
      final totalTime = completedTasks.fold<int>(0, (sum, task) {
        if (task.completedDate != null) {
          return sum + task.completedDate!.difference(task.createdDate).inHours;
        }
        return sum;
      });
      averageCompletionTime = totalTime / completedTasks.length;
    }

    // Tasks completed this week and month
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final tasksThisWeek = completedTasks
        .where((t) =>
            t.completedDate != null &&
            t.completedDate!.isAfter(weekAgo) &&
            t.isDone)
        .length;

    final tasksThisMonth = completedTasks
        .where((t) =>
            t.completedDate != null &&
            t.completedDate!.isAfter(monthAgo) &&
            t.isDone)
        .length;

    // Category breakdown
    final categoryBreakdown = _getCategoryBreakdown(tasks);

    // Daily completion data
    final dailyCompletionData = _getDailyCompletionData(completedTasks);

    return TaskStatistics(
      totalTasks: tasks.length,
      completedTasks: completedTasks.length,
      pendingTasks: pendingTasks.length,
      completionRate: completionRate,
      highPriorityTasks: highPriority,
      mediumPriorityTasks: mediumPriority,
      lowPriorityTasks: lowPriority,
      averageCompletionTime: averageCompletionTime,
      tasksCompletedThisWeek: tasksThisWeek,
      tasksCompletedThisMonth: tasksThisMonth,
      tasksByCategory: categoryBreakdown,
      tasksCompletedByDay: dailyCompletionData,
    );
  }

  /// Get daily completion data for the last 7 days
  Map<String, int> _getDailyCompletionData(List<Task> completedTasks) {
    final dailyData = <String, int>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('MMM dd').format(date);

      final dayCompletions = completedTasks.where((t) {
        return t.completedDate != null &&
            t.completedDate!.year == date.year &&
            t.completedDate!.month == date.month &&
            t.completedDate!.day == date.day;
      }).length;

      dailyData[dateKey] = dayCompletions;
    }

    return dailyData;
  }

  /// Get category breakdown
  Map<String, int> _getCategoryBreakdown(List<Task> tasks) {
    final breakdown = <String, int>{};

    for (final task in tasks) {
      if (task.category.isNotEmpty) {
        breakdown[task.category] = (breakdown[task.category] ?? 0) + 1;
      }
    }

    return breakdown;
  }

  /// Get current streak (consecutive days with completed tasks)
  Future<int> getStreak() async {
    try {
      final allTasks = await _taskRepository.getAllTasks();
      final completedTasks = allTasks.where((t) => t.isDone).toList();

      if (completedTasks.isEmpty) {
        return 0;
      }

      int streak = 0;
      var currentDate = DateTime.now();

      while (true) {
        final hasCompletionToday = completedTasks.any((t) {
          return t.completedDate != null &&
              t.completedDate!.year == currentDate.year &&
              t.completedDate!.month == currentDate.month &&
              t.completedDate!.day == currentDate.day;
        });

        if (hasCompletionToday) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      throw Exception('Failed to calculate streak: $e');
    }
  }

  /// Get productivity trend (comparison between weeks)
  Future<Map<String, double>> getProductivityTrend() async {
    try {
      final allTasks = await _taskRepository.getAllTasks();
      final trend = <String, double>{};

      // Get stats for last 4 weeks
      for (int week = 3; week >= 0; week--) {
        final start = DateTime.now().subtract(Duration(days: (week * 7) + 7));
        final end = DateTime.now().subtract(Duration(days: week * 7));

        final weekTasks = allTasks.where((t) {
          return t.createdDate.isAfter(start) && t.createdDate.isBefore(end);
        }).toList();

        final completed = weekTasks.where((t) => t.isDone).length;
        final rate =
            weekTasks.isEmpty ? 0.0 : (completed / weekTasks.length) * 100;

        final weekLabel = 'Week ${week + 1}';
        trend[weekLabel] = rate;
      }

      return trend;
    } catch (e) {
      throw Exception('Failed to get productivity trend: $e');
    }
  }
}
