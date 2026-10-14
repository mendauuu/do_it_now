import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Opens (and creates) the local SQLite database this feature uses
/// for topics and session history. Deliberately self-contained —
/// this screen runs standalone right now, so it can't assume a host
/// app has its own Database instance to share. If this ever does get
/// embedded in a larger app with its own SQLite database, point
/// TopicsRepository and PomodoroSessionsRepository at that Database
/// instead and this file becomes unnecessary.
class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static Future<Database> open() async {
    final existing = _db;
    if (existing != null) return existing;

    final path = join(await getDatabasesPath(), 'musketeer_pomodoro.db');
    final opened = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE topics (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            is_builtin INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE pomodoro_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phase TEXT NOT NULL,
            topic_id TEXT,
            topic_name TEXT,
            duration_seconds INTEGER NOT NULL,
            completed_at TEXT NOT NULL
          )
        ''');
      },
    );
    _db = opened;
    return opened;
  }
}
