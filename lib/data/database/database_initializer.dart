/// Database Integration Helper
/// This file provides utility methods to integrate SQL database with your app
/// During migration: Reads from Hive, writes to both (dual-source)

import 'package:do_it_now/data/database/database_service.dart';
import 'package:do_it_now/data/repositories/task_repository.dart';
import 'package:do_it_now/data/repositories/dual_repository.dart';
import 'package:do_it_now/data/models/task_statistics.dart';
import 'package:do_it_now/data/services/statistics_service.dart';
import 'package:do_it_now/ui/hive/task_model.dart' as hive_model;

class DatabaseInitializer {
  static DatabaseService? _databaseService;
  static TaskRepository? _sqlRepository;
  static DualRepository? _dualRepository;
  static StatisticsService? _statisticsService;

  /// Initialize the database on app startup
  /// Call this in main() before runApp()
  /// This sets up both Hive and SQL, with automatic migration
  static Future<void> initialize() async {
    try {
      // Initialize DatabaseService singleton
      _databaseService = DatabaseService();
      // Ensure database is initialized and tables are created
      await _databaseService!.database;
      print('✅ SQL database initialized');

      // Initialize SQL repository
      _sqlRepository = TaskRepository();

      // Initialize dual repository (manages both Hive and SQL)
      _dualRepository = DualRepository(sqlRepository: _sqlRepository!);
      await _dualRepository!.initialize();
      print('✅ DualRepository initialized');

      // Initialize statistics service (uses SQL repository)
      _statisticsService = StatisticsService(taskRepository: _sqlRepository!);

      // Log migration status
      final stats = await _dualRepository!.getMigrationStats();
      print(
          '📊 Migration stats: ${stats['hive_tasks']} Hive tasks, ${stats['sql_tasks']} SQL tasks');
    } catch (e) {
      print('❌ Database initialization error: $e');
      rethrow;
    }
  }

  /// Get the DualRepository for managing tasks during migration
  static DualRepository getDualRepository() {
    if (_dualRepository == null) {
      throw Exception(
        'Database not initialized. Call DatabaseInitializer.initialize() in main().',
      );
    }
    return _dualRepository!;
  }

  /// Get the SQL TaskRepository (for direct SQL operations)
  static TaskRepository getSQLRepository() {
    if (_sqlRepository == null) {
      throw Exception(
        'Database not initialized. Call DatabaseInitializer.initialize() in main().',
      );
    }
    return _sqlRepository!;
  }

  /// Get the singleton StatisticsService instance
  static StatisticsService getStatisticsService() {
    if (_statisticsService == null) {
      throw Exception(
        'Database not initialized. Call DatabaseInitializer.initialize() in main().',
      );
    }
    return _statisticsService!;
  }

  // ============================================================
  // DUAL REPOSITORY METHODS (Read from Hive, Write to Both)
  // ============================================================

  /// Get all tasks (from active source: Hive or SQL)
  static Future<List<hive_model.TaskModel>> getAllTasks() {
    return getDualRepository().getAllTasks();
  }

  /// Get pending tasks
  static Future<List<hive_model.TaskModel>> getPendingTasks() {
    return getDualRepository().getPendingTasks();
  }

  /// Get completed tasks
  static Future<List<hive_model.TaskModel>> getCompletedTasks() {
    return getDualRepository().getCompletedTasks();
  }

  /// Create a new task (saves to both Hive and SQL)
  static Future<void> createTask({
    required String title,
    required String description,
    required int priority,
    String category = 'General',
  }) {
    final hiveTask = hive_model.TaskModel(
      title: title,
      description: description,
      priority: priority,
      isDone: false,
      date: DateTime.now(),
    );
    return getDualRepository().createTask(hiveTask);
  }

  /// Update task
  static Future<void> updateTask(
    int index,
    hive_model.TaskModel updatedTask,
  ) {
    return getDualRepository().updateTask(index, updatedTask);
  }

  /// Toggle task completion
  static Future<void> toggleTaskCompletion(int index, bool isDone) {
    return getDualRepository().toggleTaskCompletion(index, isDone);
  }

  /// Delete task
  static Future<void> deleteTask(int index) {
    return getDualRepository().deleteTask(index);
  }

  // ============================================================
  // MIGRATION MANAGEMENT METHODS
  // ============================================================

  /// Get migration statistics
  static Future<Map<String, int>> getMigrationStats() {
    return getDualRepository().getMigrationStats();
  }

  /// Verify data consistency between Hive and SQL
  static Future<bool> verifyDataConsistency() {
    return getDualRepository().verifyDataConsistency();
  }

  /// Force sync all Hive data to SQL
  static Future<void> forceSyncHiveToSQL() {
    return getDualRepository().forceSyncHiveToSQL();
  }

  /// Switch between data sources
  /// Set to true to use SQL as primary source
  /// Set to false to use Hive as primary source (default)
  static void switchToSQLSource(bool useSql) {
    getDualRepository().switchToSQLSource(useSql);
    print(useSql
        ? '🔄 Switched to SQL as primary source'
        : '🔄 Switched to Hive as primary source');
  }

  /// Check if currently using SQL as source
  static bool isUsingSQLSource() {
    return getDualRepository().isUsingSQLSource();
  }

  // ============================================================
  // SQL ANALYTICS METHODS (Direct SQL for statistics)
  // ============================================================

  /// Get all-time statistics
  static Future<TaskStatistics> getStatistics() {
    return getStatisticsService().getStatistics();
  }

  /// Get weekly statistics
  static Future<TaskStatistics> getWeeklyStatistics() {
    return getStatisticsService().getWeeklyStatistics();
  }

  /// Get monthly statistics
  static Future<TaskStatistics> getMonthlyStatistics() {
    return getStatisticsService().getMonthlyStatistics();
  }

  /// Get current streak
  static Future<int> getStreak() {
    return getStatisticsService().getStreak();
  }

  /// Get productivity trend
  static Future<Map<String, double>> getProductivityTrend() {
    return getStatisticsService().getProductivityTrend();
  }
}
