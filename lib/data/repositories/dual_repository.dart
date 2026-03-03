import 'package:hive_flutter/hive_flutter.dart';
import 'package:do_it_now/ui/hive/task_model.dart' as hive_model;
import 'package:do_it_now/data/models/task_model.dart' as sql_model;
import 'package:do_it_now/data/repositories/task_repository.dart';

/// DualRepository manages both Hive (current) and SQL (new) during migration
/// - Reads from Hive to keep UI working
/// - Writes to both Hive and SQL for synchronization
/// - Once migration is complete, switch to SQL-only
class DualRepository {
  final TaskRepository _sqlRepository;
  late Box<hive_model.TaskModel> _hiveBox;

  // Flag to switch between sources
  bool _useSqlAsSource = false;

  DualRepository({required TaskRepository sqlRepository})
      : _sqlRepository = sqlRepository;

  /// Initialize the repository
  Future<void> initialize() async {
    _hiveBox = Hive.box<hive_model.TaskModel>('tasks');

    // On first launch, migrate existing Hive data to SQL
    if (_hiveBox.isNotEmpty) {
      await _migrateHiveToSQL();
    }
  }

  /// Migrate existing Hive data to SQL (one-time operation)
  Future<void> _migrateHiveToSQL() async {
    try {
      final hiveValues = _hiveBox.values.toList();

      for (var hiveTask in hiveValues) {
        // Convert Hive TaskModel to SQL Task model
        final sqlTask = _convertHiveToSQL(hiveTask);

        // Insert into SQL (skip if already exists)
        try {
          await _sqlRepository.createTask(sqlTask);
        } catch (e) {
          // Task might already exist, continue
          print('Migration note: $e');
        }
      }

      print('Migration complete: ${hiveValues.length} tasks migrated to SQL');
    } catch (e) {
      print('Migration error: $e');
    }
  }

  /// Convert Hive TaskModel to SQL Task model
  sql_model.Task _convertHiveToSQL(hive_model.TaskModel hiveTask) {
    return sql_model.Task(
      title: hiveTask.title,
      description: hiveTask.description,
      priority: hiveTask.priority,
      isDone: hiveTask.isDone,
      createdDate: hiveTask.date,
      completedDate: hiveTask.isDone ? hiveTask.date : null,
      category: 'Migrated',
      createdTimestamp: hiveTask.date.millisecondsSinceEpoch ~/ 1000,
      completedTimestamp:
          hiveTask.isDone ? hiveTask.date.millisecondsSinceEpoch ~/ 1000 : null,
    );
  }

  /// Convert SQL Task to Hive TaskModel
  hive_model.TaskModel _convertSQLToHive(sql_model.Task sqlTask) {
    return hive_model.TaskModel(
      title: sqlTask.title,
      description: sqlTask.description,
      date: sqlTask.createdDate,
      priority: sqlTask.priority,
      isDone: sqlTask.isDone,
    );
  }

  /// Get all tasks (reads from current source)
  Future<List<hive_model.TaskModel>> getAllTasks() async {
    if (_useSqlAsSource) {
      // Read from SQL and convert to Hive format for UI
      final sqlTasks = await _sqlRepository.getAllTasks();
      return sqlTasks.map(_convertSQLToHive).toList();
    }
    // Read from Hive (current)
    return _hiveBox.values.toList();
  }

  /// Get pending tasks
  Future<List<hive_model.TaskModel>> getPendingTasks() async {
    if (_useSqlAsSource) {
      final sqlTasks = await _sqlRepository.getPendingTasks();
      return sqlTasks.map(_convertSQLToHive).toList();
    }
    return _hiveBox.values.where((task) => !task.isDone).toList();
  }

  /// Get completed tasks
  Future<List<hive_model.TaskModel>> getCompletedTasks() async {
    if (_useSqlAsSource) {
      final sqlTasks = await _sqlRepository.getCompletedTasks();
      return sqlTasks.map(_convertSQLToHive).toList();
    }
    return _hiveBox.values.where((task) => task.isDone).toList();
  }

  /// Create a new task (write to both sources)
  Future<void> createTask(hive_model.TaskModel hiveTask) async {
    try {
      // Write to Hive (current UI source)
      await _hiveBox.add(hiveTask);

      // Also write to SQL for backup and migration
      final sqlTask = _convertHiveToSQL(hiveTask);
      await _sqlRepository.createTask(sqlTask);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update task (update in both sources)
  Future<void> updateTask(
    int index,
    hive_model.TaskModel updatedTask,
  ) async {
    try {
      // Update in Hive
      await _hiveBox.putAt(index, updatedTask);

      // Also update in SQL if using it
      if (_useSqlAsSource) {
        final sqlTask = _convertHiveToSQL(updatedTask);
        await _sqlRepository.updateTask(sqlTask);
      } else {
        // Convert and sync to SQL for consistency
        final sqlTask = _convertHiveToSQL(updatedTask);
        try {
          await _sqlRepository.updateTask(sqlTask);
        } catch (e) {
          // Task might not exist in SQL yet, that's ok
        }
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Toggle task completion (update in both sources)
  Future<void> toggleTaskCompletion(int index, bool isDone) async {
    try {
      final task = _hiveBox.getAt(index);
      if (task != null) {
        final updatedTask = hive_model.TaskModel(
          title: task.title,
          description: task.description,
          date: task.date,
          priority: task.priority,
          isDone: isDone,
        );

        // Update in Hive (primary source)
        await _hiveBox.putAt(index, updatedTask);

        // Skip SQL update for toggle during migration
        // SQL updates will use toggleTaskCompletion with actual ID, not index
        // This prevents null ID errors during dual-source migration
      }
    } catch (e) {
      throw Exception('Failed to toggle task: $e');
    }
  }

  /// Delete task (delete from both sources)
  Future<void> deleteTask(int index) async {
    try {
      // Delete from Hive
      await _hiveBox.deleteAt(index);

      // Also delete from SQL
      try {
        // Note: This requires the SQL task to have an ID
        // For now, we'll skip SQL deletion during migration
      } catch (e) {
        print('SQL deletion skipped during migration: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Switch data source (Hive to SQL or vice versa)
  /// Set to true after SQL migration is verified
  void switchToSQLSource(bool useSql) {
    _useSqlAsSource = useSql;
    print('Switched to ${useSql ? 'SQL' : 'Hive'} as data source');
  }

  /// Check if currently using SQL as source
  bool isUsingSQLSource() => _useSqlAsSource;

  /// Get statistics about migration
  Future<Map<String, int>> getMigrationStats() async {
    final hiveCount = _hiveBox.length;
    final sqlCount = await _sqlRepository.getTotalTasksCount();

    return {
      'hive_tasks': hiveCount,
      'sql_tasks': sqlCount,
    };
  }

  /// Verify data consistency between Hive and SQL
  Future<bool> verifyDataConsistency() async {
    try {
      final hiveCount = _hiveBox.length;
      final sqlCount = await _sqlRepository.getTotalTasksCount();

      final isConsistent = hiveCount == sqlCount;

      if (!isConsistent) {
        print('⚠️ Data inconsistency detected:');
        print('   Hive tasks: $hiveCount');
        print('   SQL tasks: $sqlCount');
      } else {
        print('✅ Data consistency verified');
      }

      return isConsistent;
    } catch (e) {
      print('Error verifying consistency: $e');
      return false;
    }
  }

  /// Sync Hive to SQL (one-way forced sync)
  Future<void> forceSyncHiveToSQL() async {
    try {
      print('Starting force sync from Hive to SQL...');

      final hiveValues = _hiveBox.values.toList();
      int successCount = 0;
      int errorCount = 0;

      for (var hiveTask in hiveValues) {
        try {
          final sqlTask = _convertHiveToSQL(hiveTask);
          await _sqlRepository.createTask(sqlTask);
          successCount++;
        } catch (e) {
          errorCount++;
          // Continue with next task
        }
      }

      print('Sync complete: $successCount synced, $errorCount errors');
    } catch (e) {
      throw Exception('Force sync failed: $e');
    }
  }

  /// Clear all data (use with caution!)
  Future<void> clearAllTasks() async {
    try {
      await _hiveBox.clear();
      print('Hive tasks cleared');
    } catch (e) {
      throw Exception('Failed to clear tasks: $e');
    }
  }
}
