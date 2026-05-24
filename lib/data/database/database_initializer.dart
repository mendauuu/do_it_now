import 'package:do_it_now/data/database/database_service.dart';
import 'package:do_it_now/data/repositories/task_repository.dart';
import 'package:do_it_now/data/models/task_model.dart';
import 'package:do_it_now/data/models/task_statistics.dart';
import 'package:do_it_now/data/services/statistics_service.dart';
import 'package:do_it_now/ui/hive/task_model.dart' as hive;

/// Central access point for database services.
/// No more DualRepository — pure SQL only.
class DatabaseInitializer {
  static late TaskRepository _repo;
  static late StatisticsService _stats;

  static bool _initialized = false;

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    if (_initialized) return;

    // Warm up the database (runs onCreate / onUpgrade if needed)
    await DatabaseService().database;

    _repo = TaskRepository();
    _stats = StatisticsService(taskRepository: _repo);

    _initialized = true;
  }

  // ── Task CRUD ────────────────────────────────────────────────────────────────

  /// Creates a task and returns a [hive.TaskModel] with the SQL id attached.
  static Future<hive.TaskModel> createTask({
    required String title,
    required String description,
    required int priority,
    String category = 'General',
    DateTime? dueDate,
  }) async {
    _check();
    final now = DateTime.now();
    final sqlTask = Task(
      title: title,
      description: description,
      priority: priority,
      isDone: false,
      createdDate: now,
      dueDate: dueDate,
      category: category,
      createdTimestamp: now.millisecondsSinceEpoch ~/ 1000,
    );

    final id = await _repo.createTask(sqlTask);

    // Return a HiveTaskModel carrying the new SQL id so BLoC state stays in sync.
    return hive.TaskModel(
      title: title,
      description: description,
      date: now,
      priority: priority,
      isDone: false,
      sqlId: id,
      dueDate: dueDate,
      category: category,
    );
  }

  static Future<List<hive.TaskModel>> getAllTasks() async {
    _check();
    final tasks = await _repo.getAllTasks();
    return tasks.map(_toHive).toList();
  }

  static Future<List<hive.TaskModel>> getPendingTasks() async {
    _check();
    final tasks = await _repo.getPendingTasks();
    return tasks.map(_toHive).toList();
  }

  static Future<List<hive.TaskModel>> getCompletedTasks() async {
    _check();
    final tasks = await _repo.getCompletedTasks();
    return tasks.map(_toHive).toList();
  }

  /// Toggle by SQL id. Throws if sqlId is null.
  static Future<void> toggleTaskCompletion(int sqlId, bool isDone) async {
    _check();
    await _repo.toggleTaskCompletion(sqlId, isDone);
  }

  /// Delete by SQL id. Throws if sqlId is null.
  static Future<void> deleteTask(int sqlId) async {
    _check();
    await _repo.deleteTask(sqlId);
  }

  /// Full update — task.sqlId must be set.
  static Future<void> updateTask(hive.TaskModel task) async {
    _check();
    assert(task.sqlId != null, 'updateTask: task has no sqlId');
    final now = DateTime.now();
    final sqlTask = Task(
      id: task.sqlId,
      title: task.title,
      description: task.description,
      priority: task.priority,
      isDone: task.isDone,
      createdDate: task.date,
      dueDate: task.dueDate,
      category: task.category,
      createdTimestamp: task.date.millisecondsSinceEpoch ~/ 1000,
      completedDate: task.isDone ? now : null,
      completedTimestamp:
          task.isDone ? now.millisecondsSinceEpoch ~/ 1000 : null,
    );
    await _repo.updateTask(sqlTask);
  }

  // ── Statistics ───────────────────────────────────────────────────────────────

  static Future<TaskStatistics> getStatistics() {
    _check();
    return _stats.getStatistics();
  }

  static Future<TaskStatistics> getWeeklyStatistics() {
    _check();
    return _stats.getWeeklyStatistics();
  }

  static Future<TaskStatistics> getMonthlyStatistics() {
    _check();
    return _stats.getMonthlyStatistics();
  }

  static Future<int> getStreak() {
    _check();
    return _stats.getStreak();
  }

  static Future<Map<String, double>> getProductivityTrend() {
    _check();
    return _stats.getProductivityTrend();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static hive.TaskModel _toHive(Task t) => hive.TaskModel(
        title: t.title,
        description: t.description,
        date: t.createdDate,
        priority: t.priority,
        isDone: t.isDone,
        sqlId: t.id,
        dueDate: t.dueDate,
        category: t.category,
      );

  static void _check() {
    if (!_initialized) {
      throw StateError(
          'DatabaseInitializer not initialized — call initialize() in main()');
    }
  }
}
