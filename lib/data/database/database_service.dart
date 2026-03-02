import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'do_it_now.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        priority INTEGER DEFAULT 1,
        is_done INTEGER DEFAULT 0,
        created_date TEXT NOT NULL,
        completed_date TEXT,
        created_timestamp INTEGER NOT NULL,
        completed_timestamp INTEGER,
        category TEXT DEFAULT 'General'
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_tasks_created_date ON tasks(created_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_is_done ON tasks(is_done)
    ''');
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
