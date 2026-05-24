import 'package:sqflite/sqflite.dart';
import 'package:do_it_now/data/database/database_service.dart';
import 'package:do_it_now/data/models/task_model.dart';

class TaskRepository {
  final DatabaseService _db = DatabaseService();

  // ── Create ──────────────────────────────────────────────────────────────────

  /// Returns the new SQL row id.
  Future<int> createTask(Task task) async {
    final db = await _db.database;
    return db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  Future<List<Task>> getAllTasks() async {
    final db = await _db.database;
    final maps = await db.query('tasks', orderBy: 'created_timestamp DESC');
    return maps.map(Task.fromMap).toList();
  }

  Future<List<Task>> getPendingTasks() async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'is_done = ?',
      whereArgs: [0],
      orderBy: 'priority DESC, created_timestamp ASC',
    );
    return maps.map(Task.fromMap).toList();
  }

  Future<List<Task>> getCompletedTasks() async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'is_done = ?',
      whereArgs: [1],
      orderBy: 'completed_timestamp DESC',
    );
    return maps.map(Task.fromMap).toList();
  }

  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'created_date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_timestamp DESC',
    );
    return maps.map(Task.fromMap).toList();
  }

  Future<Task?> getTaskById(int id) async {
    final db = await _db.database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Task.fromMap(maps.first);
  }

  Future<List<Task>> getTasksByCategory(String category) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_timestamp DESC',
    );
    return maps.map(Task.fromMap).toList();
  }

  Future<List<Task>> getOverdueTasks() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'tasks',
      where: 'is_done = 0 AND due_date IS NOT NULL AND due_date < ?',
      whereArgs: [now],
      orderBy: 'due_date ASC',
    );
    return maps.map(Task.fromMap).toList();
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  /// Update by SQL id. Task.id must not be null.
  Future<void> updateTask(Task task) async {
    assert(task.id != null, 'updateTask requires a non-null id');
    final db = await _db.database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Toggle completion by SQL id.
  Future<void> toggleTaskCompletion(int taskId, bool isDone) async {
    final db = await _db.database;
    final now = DateTime.now();
    await db.update(
      'tasks',
      {
        'is_done': isDone ? 1 : 0,
        'completed_date': isDone ? now.toIso8601String() : null,
        'completed_timestamp':
            isDone ? now.millisecondsSinceEpoch ~/ 1000 : null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  /// Delete by SQL id.
  Future<void> deleteTask(int taskId) async {
    final db = await _db.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  Future<void> deleteAllTasks() async {
    final db = await _db.database;
    await db.delete('tasks');
  }

  // ── Counts ───────────────────────────────────────────────────────────────────

  Future<int> getTotalTasksCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM tasks');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCompletedTasksCount() async {
    final db = await _db.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as c FROM tasks WHERE is_done = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getCompletionRate() async {
    final total = await getTotalTasksCount();
    if (total == 0) return 0.0;
    final completed = await getCompletedTasksCount();
    return (completed / total) * 100;
  }

  Future<List<String>> getCategories() async {
    final db = await _db.database;
    final result = await db
        .rawQuery('SELECT DISTINCT category FROM tasks ORDER BY category');
    return result.map((r) => r['category'] as String).toList();
  }
}
