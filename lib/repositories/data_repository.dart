import 'package:my_daily_plus/database/database_helper.dart';
import 'package:my_daily_plus/models/category.dart';
import 'package:my_daily_plus/models/event.dart';
import 'package:my_daily_plus/models/note.dart';
import 'package:sqflite/sqflite.dart';

class DataRepository {
  DataRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<Database> get _db => _dbHelper.database;

  // --- Categories ---

  Future<List<Category>> getCategories() async {
    final rows = await (await _db).query('categories', orderBy: 'name');
    return rows.map(Category.fromMap).toList();
  }

  // --- Events ---

  Future<int> insertEvent(CalendarEvent e) async {
    return (await _db).insert('events', e.toMap());
  }

  Future<void> updateEvent(CalendarEvent e) async {
    if (e.id == null) return;
    await (await _db).update(
      'events',
      e.toMap(),
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  Future<void> deleteEvent(int id) async {
    await (await _db).delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<CalendarEvent?> getEventById(int id) async {
    final rows = await (await _db).query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CalendarEvent.fromMap(rows.first);
  }

  Future<List<CalendarEvent>> getAllEvents() async {
    final rows = await (await _db).query('events', orderBy: 'start_time');
    return rows.map(CalendarEvent.fromMap).toList();
  }

  Future<List<CalendarEvent>> getEventsForDay(DateTime day) async {
    final all = await getAllEvents();
    final d = DateTime(day.year, day.month, day.day);
    return all.where((e) => e.occursOnDay(d)).toList()
      ..sort((a, b) => a.startOnDay(d).compareTo(b.startOnDay(d)));
  }

  /// Неделя с понедельника: события, у которых есть хотя бы один день в этой неделе.
  Future<List<CalendarEvent>> getEventsForWeek(DateTime anyDayInWeek) async {
    final monday = anyDayInWeek.subtract(
      Duration(days: anyDayInWeek.weekday - 1),
    );
    final all = await getAllEvents();
    final out = <CalendarEvent>[];
    for (final e in all) {
      for (var i = 0; i < 7; i++) {
        final d = monday.add(Duration(days: i));
        if (e.occursOnDay(d)) {
          out.add(e);
          break;
        }
      }
    }
    out.sort((a, b) => a.anchorStart.compareTo(b.anchorStart));
    return out;
  }

  /// Для месяца: уникальные события, у которых есть хотя бы один день в месяце.
  Future<List<CalendarEvent>> getEventsTouchingMonth(DateTime month) async {
    final all = await getAllEvents();
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final out = <CalendarEvent>[];
    for (final e in all) {
      var hit = false;
      for (var d = first;
          !d.isAfter(last);
          d = d.add(const Duration(days: 1))) {
        if (e.occursOnDay(d)) {
          hit = true;
          break;
        }
      }
      if (hit) out.add(e);
    }
    return out;
  }

  // --- Notes ---

  Future<int> insertNote(Note n) async {
    return (await _db).insert('notes', n.toMap());
  }

  Future<void> updateNote(Note n) async {
    if (n.id == null) return;
    await (await _db).update(
      'notes',
      n.toMap(),
      where: 'id = ?',
      whereArgs: [n.id],
    );
  }

  Future<void> deleteNote(int id) async {
    await (await _db).delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Note?> getNoteById(int id) async {
    final rows = await (await _db).query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  Future<List<Note>> getAllNotes() async {
    final rows =
        await (await _db).query('notes', orderBy: 'created_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) return getAllNotes();
    final q = '%${query.trim()}%';
    final rows = await (await _db).query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: [q, q],
      orderBy: 'created_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  int _dayStartMillis(DateTime day) =>
      DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;

  Future<List<Note>> getNotesForDay(DateTime day) async {
    final dayMs = _dayStartMillis(day);
    final db = await _db;

    final byDate = await db.query(
      'notes',
      where: 'linked_date = ?',
      whereArgs: [dayMs],
    );

    final eventsThisDay = await getEventsForDay(day);
    final eventIds = eventsThisDay.map((e) => e.id).whereType<int>().toList();
    final byEvent = <Note>[];
    if (eventIds.isNotEmpty) {
      final placeholders = List.filled(eventIds.length, '?').join(',');
      final rows = await db.rawQuery(
        '''
SELECT n.* FROM notes n
INNER JOIN event_notes en ON en.note_id = n.id
WHERE en.event_id IN ($placeholders)
''',
        eventIds,
      );
      byEvent.addAll(rows.map(Note.fromMap));
    }

    final map = <int, Note>{};
    for (final n in [...byDate.map(Note.fromMap), ...byEvent]) {
      if (n.id != null) map[n.id!] = n;
    }
    final list = map.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<Note>> getNotesLinkedToEvent(int eventId) async {
    final rows = await (await _db).rawQuery(
      '''
SELECT n.* FROM notes n
INNER JOIN event_notes en ON en.note_id = n.id
WHERE en.event_id = ?
ORDER BY n.created_at DESC
''',
      [eventId],
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<void> linkNoteToEvent(int noteId, int eventId) async {
    await (await _db).insert(
      'event_notes',
      {'note_id': noteId, 'event_id': eventId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> unlinkNoteFromEvent(int noteId, int eventId) async {
    await (await _db).delete(
      'event_notes',
      where: 'note_id = ? AND event_id = ?',
      whereArgs: [noteId, eventId],
    );
  }

  Future<List<int>> getLinkedEventIdsForNote(int noteId) async {
    final rows = await (await _db).query(
      'event_notes',
      columns: ['event_id'],
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
    return rows.map((r) => r['event_id']! as int).toList();
  }
}
