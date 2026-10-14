import 'package:sqflite/sqflite.dart';

import '../models.dart';
import 'app_database.dart';

/// Manages the list of topics a session can be tagged with. Seeds
/// "Studying" and "Work" the first time it's used; anything else is
/// whatever the person typed in through the settings screen.
class TopicsRepository {
  static const table = 'topics';

  static const List<Topic> builtInTopics = [
    Topic(id: 'studying', name: 'Studying', isBuiltIn: true),
    Topic(id: 'work', name: 'Work', isBuiltIn: true),
  ];

  Future<List<Topic>> loadAll() async {
    final db = await AppDatabase.open();
    await _seedIfEmpty(db);

    final rows = await db.query(table, orderBy: 'is_builtin DESC, name ASC');
    return rows
        .map((r) => Topic(
              id: r['id'] as String,
              name: r['name'] as String,
              isBuiltIn: (r['is_builtin'] as int) == 1,
            ))
        .toList();
  }

  Future<void> _seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
        0;
    if (count > 0) return;

    for (final topic in builtInTopics) {
      await db.insert(table, {
        'id': topic.id,
        'name': topic.name,
        'is_builtin': 1,
      });
    }
  }

  /// Adds a custom topic and returns it (with a generated id).
  Future<Topic> add(String name) async {
    final trimmed = name.trim();
    final db = await AppDatabase.open();
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    await db.insert(table, {
      'id': id,
      'name': trimmed,
      'is_builtin': 0,
    });

    return Topic(id: id, name: trimmed);
  }

  /// Only ever deletes custom topics — the `is_builtin = 0` guard
  /// means a stray call with a built-in id is a silent no-op rather
  /// than something that needs its own error handling everywhere.
  Future<void> delete(String id) async {
    final db = await AppDatabase.open();
    await db.delete(table, where: 'id = ? AND is_builtin = 0', whereArgs: [id]);
  }
}
