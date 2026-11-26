import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../content/curriculum.dart';
import '../storage/noor_database.dart';
import 'lesson_progress.dart';

final progressStoreProvider = Provider<ProgressStore>(
  (ref) => SqliteProgressStore(ref.watch(noorDatabaseProvider)),
);

final progressProvider =
    AsyncNotifierProvider.family<
      ProgressController,
      JourneyProgress,
      ProgressScope
    >(ProgressController.new, retry: (count, error) => null);

abstract interface class ProgressStore {
  Future<JourneyProgress> load(ProgressScope scope);
  Future<LessonProgress> save(ProgressScope scope, LessonProgress record);
}

class SqliteProgressStore implements ProgressStore {
  SqliteProgressStore(this._database);

  final NoorDatabase _database;

  @override
  Future<JourneyProgress> load(ProgressScope scope) async {
    final db = await _database.open();
    final rows = await db.query(scope.table);
    return JourneyProgress(
      Map.unmodifiable({
        for (final row in rows)
          if (WorldId.fromId(row['world_id'] as String) case final world?)
            row['lesson_id'] as String: LessonProgress(
              world: world,
              lessonId: row['lesson_id'] as String,
              contentVersion: row['content_version'] as String,
              stepIndex: row['step_index'] as int,
              completed: row['completed'] == 1,
              updatedAt: row['updated_at'] as int,
            ),
      }),
    );
  }

  @override
  Future<LessonProgress> save(
    ProgressScope scope,
    LessonProgress record,
  ) async {
    final db = await _database.open();
    return db.transaction((transaction) async {
      final previous = await transaction.query(
        scope.table,
        columns: ['completed'],
        where: 'lesson_id = ?',
        whereArgs: [record.lessonId],
        limit: 1,
      );
      final saved = LessonProgress(
        world: record.world,
        lessonId: record.lessonId,
        contentVersion: record.contentVersion,
        stepIndex: record.stepIndex,
        completed:
            record.completed || (previous.firstOrNull?['completed'] == 1),
        updatedAt: record.updatedAt,
      );
      await transaction.insert(scope.table, {
        'lesson_id': saved.lessonId,
        'world_id': saved.world.id,
        'content_version': saved.contentVersion,
        'step_index': saved.stepIndex,
        'completed': saved.completed ? 1 : 0,
        'updated_at': saved.updatedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return saved;
    });
  }
}

class ProgressController extends AsyncNotifier<JourneyProgress> {
  ProgressController(this.scope);

  final ProgressScope scope;

  @override
  Future<JourneyProgress> build() =>
      ref.watch(progressStoreProvider).load(scope);

  Future<void> saveStep({
    required WorldId world,
    required LearningLesson lesson,
    required String contentVersion,
    required int index,
    required bool completed,
  }) async {
    final saved = await ref
        .read(progressStoreProvider)
        .save(
          scope,
          LessonProgress(
            world: world,
            lessonId: lesson.id,
            contentVersion: contentVersion,
            stepIndex: index,
            completed: completed,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    state = AsyncData(state.requireValue.withRecord(saved));
  }
}
