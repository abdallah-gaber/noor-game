import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../progress/lesson_progress.dart';

final noorDatabaseProvider = Provider<NoorDatabase>((ref) => NoorDatabase());

class NoorDatabase {
  Future<Database>? _database;

  Future<Database> open() => _database ??= _open();

  Future<Database> _open() async {
    try {
      final path = await getDatabasesPath();
      return await openDatabase(
        '$path/noor.db',
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE audio_preferences (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              speech INTEGER NOT NULL CHECK (speech IN (0, 1)),
              effects INTEGER NOT NULL CHECK (effects IN (0, 1))
            )
            ''');
          await _createProgress(db, ProgressScope.approved);
          await _createProgress(db, ProgressScope.preview);
          await _createGames(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            if (oldVersion == 2) {
              // All schema 2 records were written by the SPEC-002 debug catalog.
              await db.execute(
                'ALTER TABLE lesson_progress RENAME TO preview_lesson_progress',
              );
            } else {
              await _createProgress(db, ProgressScope.preview);
            }
            await _createProgress(db, ProgressScope.approved);
          }
          if (oldVersion < 4) await _createGames(db);
        },
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  Future<void> _createProgress(Database db, ProgressScope scope) =>
      db.execute('''
    CREATE TABLE ${scope.table} (
      lesson_id TEXT PRIMARY KEY,
      world_id TEXT NOT NULL,
      content_version TEXT NOT NULL,
      step_index INTEGER NOT NULL CHECK (step_index >= 0),
      completed INTEGER NOT NULL CHECK (completed IN (0, 1)),
      updated_at INTEGER NOT NULL
    )
    ''');
  Future<void> _createGames(Database db) => db.execute('''
    CREATE TABLE game_sessions (
      scope TEXT NOT NULL,
      id TEXT NOT NULL,
      lesson_id TEXT NOT NULL,
      compatibility TEXT NOT NULL,
      revision INTEGER NOT NULL,
      snapshot TEXT NOT NULL,
      PRIMARY KEY (scope, id)
    )
    ''');
}
