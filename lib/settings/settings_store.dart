import 'package:sqflite/sqflite.dart';

class AudioPreferences {
  const AudioPreferences({this.speech = false, this.effects = false});

  final bool speech;
  final bool effects;
}

abstract interface class SettingsStore {
  Future<AudioPreferences> load();
  Future<void> save(AudioPreferences preferences);
}

class SqliteSettingsStore implements SettingsStore {
  Future<Database>? _database;

  Future<Database> _open() async {
    final path = await getDatabasesPath();
    return openDatabase(
      '$path/noor.db',
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE audio_preferences (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          speech INTEGER NOT NULL CHECK (speech IN (0, 1)),
          effects INTEGER NOT NULL CHECK (effects IN (0, 1))
        )
        '''),
    );
  }

  Future<Database> _getDatabase() async {
    try {
      return await (_database ??= _open());
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  @override
  Future<AudioPreferences> load() async {
    final db = await _getDatabase();
    final rows = await db.query('audio_preferences', where: 'id = 1');
    if (rows.isEmpty) return const AudioPreferences();

    final row = rows.single;
    return AudioPreferences(
      speech: row['speech'] == 1,
      effects: row['effects'] == 1,
    );
  }

  @override
  Future<void> save(AudioPreferences preferences) async {
    final db = await _getDatabase();
    // A single SQLite statement commits the complete preference pair.
    await db.insert('audio_preferences', {
      'id': 1,
      'speech': preferences.speech ? 1 : 0,
      'effects': preferences.effects ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
