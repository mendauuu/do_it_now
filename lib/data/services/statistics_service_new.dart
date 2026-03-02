import 'package:sqflite/sqflite.dart';
import 'package:do_it_now/data/database/database_service.dart';
import 'package:do_it_now/data/models/task_statistics.dart';
import 'package:do_it_now/data/repositories/task_repository.dart';

class StatisticsService {
  final TaskRepository _taskRepository = TaskRepository();
  final DatabaseService _databaseService = DatabaseService();

  // Get statistics for a specific time period
  Future<TaskStatistics> getStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final tasks =
          await _taskRepository.getTasksByDateRange(startDate, endDate);

      // Calculate basic metrics
      final totalTasks = tasks.length;
      final completedTasks = tasks.where((t) => t.isDone).length;
      final pendingTasks = totalTasks - completedTasks;
      final completionRate =
          totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

      // Priority breakdown
      final highPriorityTasks = tasks.where((t) => t.priority == 3).length;
      final mediumPriorityTasks = tasks.where((t) => t.priority == 2).length;
      final lowPriorityTasks = tasks.where((t) => t.priority == 1).length;

      // Average completion time
      final completedTasksFiltered =
          tasks.where((t) => t.isDone && t.completedDate != null).toList();
      double averageCompletionTime = 0.0;
      if (completedTasksFiltered.isNotEmpty) {
        final totalTime = completedTasksFiltered.fold<int>(0, (sum, task) {
          final diff = task.completedDate!.difference(task.createdDate).inDays;
          return sum + diff;
        });
        averageCompletionTime = totalTime / completedTasksFiltered.length;
      }

      // Tasks by category
      final tasksByCategory = <String, int>{};
      for (final task in tasks) {
        tasksByCategory[task.category] =
            (tasksByCategory[task.category] ?? 0) + 1;
      }

      // Tasks completed by day (last 7 days)
      final tasksCompletedByDay = await _getTasksCompletedByDay(7);

      return TaskStatistics(
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        pendingTasks: pendingTasks,
        completionRate: completionRate,
        highPriorityTasks: highPriorityTasks,
        mediumPriorityTasks: mediumPriorityTasks,
        lowPriorityTasks: lowPriorityTasks,
        averageCompletionTime: averageCompletionTime,
        tasksCompletedThisWeek: 0,
        tasksCompletedThisMonth: 0,
        tasksByCategory: tasksByCategory,
        tasksCompletedByDay: tasksCompletedByDay,
      );
    } catch (e) {
      return TaskStatistics.empty();
    }
  }

  // Get weekly statistics
  Future<TaskStatistics> getWeeklyStatistics() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    return getStatistics(startDate: weekAgo, endDate: now);
  }

  // Get monthly statistics
  Future<TaskStatistics> getMonthlyStatistics() async {
    final now = DateTime.now();
    final monthAgo = now.subtract(Duration(days: 30));
    return getStatistics(startDate: monthAgo, endDate: now);
  }

  // Get all-time statistics
  Future<TaskStatistics> getAllTimeStatistics() async {
    final now = DateTime.now();
    final veryOld = DateTime(2000);
    return getStatistics(startDate: veryOld, endDate: now);
  }

  // Get tasks completed by day (last N days)
  Future<Map<String, int>> _getTasksCompletedByDay(int days) async {
    try {
      final db = await _databaseService.database;
      final result = <String, int>{};

      for (int i = 0; i < days; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(Duration(days: 1));

        final count = await db.rawQuery('''
          SELECT COUNT(*) as count FROM tasks 
          WHERE is_done = 1 
          AND completed_date BETWEEN ? AND ?
        ''', [dayStart.toIso8601String(), dayEnd.toIso8601String()]);

        final dayName = _getDayName(date);
        result[dayName] = Sqflite.firstIntValue(count) ?? 0;
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  // Get productivity trend (last 4 weeks)
  Future<List<int>> getProductivityTrend() async {
    try {
      final db = await _databaseService.database;
      final result = <int>[];

      for (int week = 0; week < 4; week++) {
        final weekStart =
            DateTime.now().subtract(Duration(days: 7 * (week + 1)));
        final weekEnd = DateTime.now().subtract(Duration(days: 7 * week));

        final count = await db.rawQuery('''
          SELECT COUNT(*) as count FROM tasks 
          WHERE is_done = 1 
          AND completed_date BETWEEN ? AND ?
        ''', [weekStart.toIso8601String(), weekEnd.toIso8601String()]);

        result.add(Sqflite.firstIntValue(count) ?? 0);
      }

      return result.reversed.toList();
    } catch (e) {
      return [0, 0, 0, 0];
    }
  }

  // Get priority distribution
  Future<Map<String, int>> getPriorityDistribution() async {
    try {
      final tasks = await _taskRepository.getAllTasks();
      return {
        'High': tasks.where((t) => t.priority == 3).length,
        'Medium': tasks.where((t) => t.priority == 2).length,
        'Low': tasks.where((t) => t.priority == 1).length,
      };
    } catch (e) {
      return {'High': 0, 'Medium': 0, 'Low': 0};
    }
  }

  // Get streak (consecutive days with completed tasks)
  Future<int> getStreak() async {
    try {
      final db = await _databaseService.database;
      int streak = 0;

      for (int i = 0; i < 365; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(Duration(days: 1));

        final result = await db.rawQuery('''
          SELECT COUNT(*) as count FROM tasks 
          WHERE is_done = 1 
          AND completed_date BETWEEN ? AND ?
        ''', [dayStart.toIso8601String(), dayEnd.toIso8601String()]);

        final count = Sqflite.firstIntValue(result) ?? 0;
        if (count > 0) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
