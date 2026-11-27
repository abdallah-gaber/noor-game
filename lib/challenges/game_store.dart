import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../content/curriculum.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import '../storage/noor_database.dart';
import 'game_session.dart';

final gameStoreProvider = Provider<GameStore>(
  (ref) => SqliteGameStore(ref.watch(noorDatabaseProvider)),
);

abstract interface class GameStore {
  Future<GameSession> open(
    ProgressScope scope,
    String lessonId,
    GameSession draft, {
    String? replayOf,
  });
  Future<void> save(
    ProgressScope scope,
    WorldId world,
    String lessonId,
    GameSession session,
  );
}

class SqliteGameStore implements GameStore {
  SqliteGameStore(this.database);
  final NoorDatabase database;

  @override
  Future<GameSession> open(
    ProgressScope scope,
    String lessonId,
    GameSession draft, {
    String? replayOf,
  }) async {
    final db = await database.open();
    return db.transaction((tx) async {
      final rows = await tx.query(
        'game_sessions',
        columns: ['snapshot'],
        where: 'scope = ? AND lesson_id = ? AND compatibility = ?',
        whereArgs: [scope.name, lessonId, draft.plan.compatibility],
        orderBy: 'rowid DESC',
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final previous = GameSession.restore(
          rows.single['snapshot'] as String,
          draft.plan,
        );
        if (!previous.finished || previous.id != replayOf) return previous;
      }
      await tx.insert('game_sessions', {
        'scope': scope.name,
        'id': draft.id,
        'lesson_id': lessonId,
        'compatibility': draft.plan.compatibility,
        'revision': 0,
        'snapshot': draft.encode(),
      });
      return draft;
    });
  }

  @override
  Future<void> save(
    ProgressScope scope,
    WorldId world,
    String lessonId,
    GameSession session,
  ) async {
    final db = await database.open();
    await db.transaction((tx) async {
      await writeGameSnapshot(tx, scope, lessonId, session);
      if (session.finished) {
        await writeLessonProgress(
          tx,
          scope,
          LessonProgress(
            world: world,
            lessonId: lessonId,
            contentVersion: session.plan.contentVersion,
            stepIndex: 0,
            completed: true,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    });
  }
}

Future<void> writeGameSnapshot(
  DatabaseExecutor transaction,
  ProgressScope scope,
  String lessonId,
  GameSession session,
) async {
  final updated = await transaction.update(
    'game_sessions',
    {
      'revision': session.revision,
      'snapshot': session.encode(),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    },
    where: 'scope = ? AND id = ? AND lesson_id = ? AND compatibility = ? AND revision = ?',
    whereArgs: [
      scope.name,
      session.id,
      lessonId,
      session.plan.compatibility,
      session.revision - 1,
    ],
  );
  if (updated != 1) throw StateError('Stale game session');
}
