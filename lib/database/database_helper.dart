import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'my_daily_plus.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
)''');
        await db.execute('''
CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  start_time INTEGER NOT NULL,
  end_time INTEGER NOT NULL,
  color TEXT NOT NULL DEFAULT '#2196F3',
  is_recurring INTEGER NOT NULL DEFAULT 0,
  recurrence_rule TEXT,
  reminder_minutes_before INTEGER NOT NULL DEFAULT 15
)''');
        await db.execute('''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT,
  category_id INTEGER,
  created_at INTEGER NOT NULL,
  linked_date INTEGER,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
)''');
        await db.execute('''
CREATE TABLE event_notes (
  event_id INTEGER NOT NULL,
  note_id INTEGER NOT NULL,
  PRIMARY KEY (event_id, note_id),
  FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
  FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
)''');
        await db.execute(
            'CREATE INDEX idx_notes_category ON notes(category_id)');
        await db.execute(
            'CREATE INDEX idx_notes_linked_date ON notes(linked_date)');
        await db.execute(
            'CREATE INDEX idx_events_start ON events(start_time)');

        await _seedCategories(db);
      },
    );
  }

  Future<void> _seedCategories(Database db) async {
    const names = ['Идеи', 'Список покупок', 'Важное', 'Разное'];
    for (final name in names) {
      await db.insert('categories', {'name': name});
    }
  }
}
