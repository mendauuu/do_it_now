import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'do_it_now.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        title               TEXT    NOT NULL,
        description         TEXT    DEFAULT '',
        priority            INTEGER DEFAULT 1,
        is_done             INTEGER DEFAULT 0,
        created_date        TEXT    NOT NULL,
        completed_date      TEXT,
        due_date            TEXT,
        created_timestamp   INTEGER NOT NULL,
        completed_timestamp INTEGER,
        category            TEXT    DEFAULT 'General'
      )
    ''');

    await db
        .execute('CREATE INDEX idx_tasks_created_date ON tasks(created_date)');
    await db.execute('CREATE INDEX idx_tasks_is_done ON tasks(is_done)');
    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks(due_date)');
  }

  /// Migrate v1 → v2: add due_date column
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN due_date TEXT');
    }
  }

  Future<void> closeDatabase() async => (await database).close();
}
