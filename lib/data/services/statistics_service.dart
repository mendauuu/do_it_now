import 'package:intl/intl.dart';
import 'package:do_it_now/data/models/task_model.dart';
import 'package:do_it_now/data/models/task_statistics.dart';
import 'package:do_it_now/data/repositories/task_repository.dart';

/// Single canonical StatisticsService.
/// All stat calculations are done in-memory from fetched tasks —
/// no raw SQL queries — so they stay correct and testable.
class StatisticsService {
  final TaskRepository _repo;

  StatisticsService({required TaskRepository taskRepository})
      : _repo = taskRepository;

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<TaskStatistics> getStatistics() async {
    final tasks = await _repo.getAllTasks();
    return _calculate(tasks);
  }

  Future<TaskStatistics> getWeeklyStatistics() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final tasks = await _repo.getTasksByDateRange(start, now);
    return _calculate(tasks);
  }

  Future<TaskStatistics> getMonthlyStatistics() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final tasks = await _repo.getTasksByDateRange(start, now);
    return _calculate(tasks);
  }

  /// Consecutive days (going back from today) where at least one task was completed.
  Future<int> getStreak() async {
    final tasks = await _repo.getAllTasks();
    final completed = tasks.where((t) => t.isDone && t.completedDate != null);

    int streak = 0;
    var day = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final target = DateTime(day.year, day.month, day.day);
      final hasCompletion = completed.any((t) {
        final d = t.completedDate!;
        return d.year == target.year &&
            d.month == target.month &&
            d.day == target.day;
      });

      if (hasCompletion) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<Map<String, double>> getProductivityTrend() async {
    final tasks = await _repo.getAllTasks();
    final trend = <String, double>{};

    for (int week = 3; week >= 0; week--) {
      final start = DateTime.now().subtract(Duration(days: (week + 1) * 7));
      final end = DateTime.now().subtract(Duration(days: week * 7));

      final weekTasks = tasks.where(
          (t) => t.createdDate.isAfter(start) && t.createdDate.isBefore(end));
      final total = weekTasks.length;
      final done = weekTasks.where((t) => t.isDone).length;
      trend['Week ${4 - week}'] = total == 0 ? 0 : (done / total) * 100;
    }
    return trend;
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  TaskStatistics _calculate(List<Task> tasks) {
    if (tasks.isEmpty) return TaskStatistics.empty();

    final completed = tasks.where((t) => t.isDone).toList();
    final pending = tasks.where((t) => !t.isDone).toList();
    final completionRate =
        tasks.isEmpty ? 0.0 : (completed.length / tasks.length) * 100;

    final high = tasks.where((t) => t.priority == 3).length;
    final med = tasks.where((t) => t.priority == 2).length;
    final low = tasks.where((t) => t.priority == 1).length;

    // Average hours to complete
    double avgTime = 0;
    final withTime = completed.where((t) => t.completedDate != null).toList();
    if (withTime.isNotEmpty) {
      final total = withTime.fold<int>(0,
          (sum, t) => sum + t.completedDate!.difference(t.createdDate).inHours);
      avgTime = total / withTime.length;
    }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final thisWeek = completed
        .where(
            (t) => t.completedDate != null && t.completedDate!.isAfter(weekAgo))
        .length;
    final thisMonth = completed
        .where((t) =>
            t.completedDate != null && t.completedDate!.isAfter(monthAgo))
        .length;

    return TaskStatistics(
      totalTasks: tasks.length,
      completedTasks: completed.length,
      pendingTasks: pending.length,
      completionRate: completionRate,
      highPriorityTasks: high,
      mediumPriorityTasks: med,
      lowPriorityTasks: low,
      averageCompletionTime: avgTime,
      tasksCompletedThisWeek: thisWeek,
      tasksCompletedThisMonth: thisMonth,
      tasksByCategory: _categoryBreakdown(tasks),
      // Keys are "MMM dd" strings — last 7 days oldest→newest
      tasksCompletedByDay: _dailyCompletions(completed),
    );
  }

  /// Returns a LinkedHashMap with keys like "May 17", oldest first.
  Map<String, int> _dailyCompletions(List<Task> completed) {
    final result = <String, int>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = DateFormat('MMM dd').format(day);
      result[key] = completed.where((t) {
        final d = t.completedDate;
        return d != null &&
            d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }).length;
    }
    return result;
  }

  Map<String, int> _categoryBreakdown(List<Task> tasks) {
    final map = <String, int>{};
    for (final t in tasks) {
      map[t.category] = (map[t.category] ?? 0) + 1;
    }
    return map;
  }
}
