import 'package:sqflite/sqflite.dart';
import 'package:do_it_now/data/database/database_service.dart';
import 'package:do_it_now/data/models/task_model.dart';

class TaskRepository {
  final DatabaseService _databaseService = DatabaseService();

  // Create a new task
  Future<int> createTask(Task task) async {
    try {
      final db = await _databaseService.database;
      final id = await db.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get all tasks
  Future<List<Task>> getAllTasks() async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query('tasks', orderBy: 'created_timestamp DESC');
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  // Get completed tasks
  Future<List<Task>> getCompletedTasks() async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        'tasks',
        where: 'is_done = ?',
        whereArgs: [1],
        orderBy: 'completed_timestamp DESC',
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch completed tasks: $e');
    }
  }

  // Get pending tasks
  Future<List<Task>> getPendingTasks() async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        'tasks',
        where: 'is_done = ?',
        whereArgs: [0],
        orderBy: 'priority DESC, created_timestamp ASC',
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch pending tasks: $e');
    }
  }

  // Get tasks by date range
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        'tasks',
        where: 'created_date BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'created_timestamp DESC',
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch tasks by date range: $e');
    }
  }

  // Update task
  Future<void> updateTask(Task task) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(int taskId, bool isDone) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now();

      await db.update(
        'tasks',
        {
          'is_done': isDone ? 1 : 0,
          'completed_date': isDone ? now.toIso8601String() : null,
          'completed_timestamp': isDone ? now.millisecondsSinceEpoch : null,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  // Delete task
  Future<void> deleteTask(int taskId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Get task by ID
  Future<Task?> getTaskById(int id) async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Task.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch task: $e');
    }
  }

  // Get tasks by category
  Future<List<Task>> getTasksByCategory(String category) async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        'tasks',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'created_timestamp DESC',
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to fetch tasks by category: $e');
    }
  }

  // Count total tasks
  Future<int> getTotalTasksCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to count tasks: $e');
    }
  }

  // Count completed tasks
  Future<int> getCompletedTasksCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM tasks WHERE is_done = 1',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to count completed tasks: $e');
    }
  }

  // Get completion rate
  Future<double> getCompletionRate() async {
    try {
      final total = await getTotalTasksCount();
      if (total == 0) return 0.0;

      final completed = await getCompletedTasksCount();
      return (completed / total) * 100;
    } catch (e) {
      throw Exception('Failed to calculate completion rate: $e');
    }
  }

  // Delete all tasks
  Future<void> deleteAllTasks() async {
    try {
      final db = await _databaseService.database;
      await db.delete('tasks');
    } catch (e) {
      throw Exception('Failed to delete all tasks: $e');
    }
  }
}
