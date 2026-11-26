import 'package:sqflite/sqflite.dart';

import '../storage/noor_database.dart';

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
  SqliteSettingsStore(this._database);

  final NoorDatabase _database;

  @override
  Future<AudioPreferences> load() async {
    final db = await _database.open();
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
    final db = await _database.open();
    // A single SQLite statement commits the complete preference pair.
    await db.insert('audio_preferences', {
      'id': 1,
      'speech': preferences.speech ? 1 : 0,
      'effects': preferences.effects ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
