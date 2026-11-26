import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

final noorDatabaseProvider = Provider<NoorDatabase>((ref) => NoorDatabase());

class NoorDatabase {
  Future<Database>? _database;

  Future<Database> open() => _database ??= _open();

  Future<Database> _open() async {
    try {
      final path = await getDatabasesPath();
      return await openDatabase(
        '$path/noor.db',
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE audio_preferences (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              speech INTEGER NOT NULL CHECK (speech IN (0, 1)),
              effects INTEGER NOT NULL CHECK (effects IN (0, 1))
            )
            ''');
          await _createLessonProgress(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createLessonProgress(db);
        },
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  Future<void> _createLessonProgress(Database db) => db.execute('''
    CREATE TABLE lesson_progress (
      lesson_id TEXT PRIMARY KEY,
      world_id TEXT NOT NULL,
      content_version TEXT NOT NULL,
      step_index INTEGER NOT NULL CHECK (step_index >= 0),
      completed INTEGER NOT NULL CHECK (completed IN (0, 1)),
      updated_at INTEGER NOT NULL
    )
    ''');
}
