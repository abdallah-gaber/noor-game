import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../review/review_history.dart';
import '../storage/noor_database.dart';
import 'lesson_progress.dart';
import 'reward_progress.dart';

final previewRewardsProvider = FutureProvider.autoDispose<RewardProgress>((
  ref,
) async {
  final database = await ref.watch(noorDatabaseProvider).open();
  return database.transaction((transaction) async {
    final history = RewardHistory();
    var cursor = 0;
    const pageSize = 32;
    while (true) {
      final rows = await transaction.rawQuery(
        'SELECT rowid, lesson_id, snapshot FROM game_sessions '
        'WHERE scope = ? AND rowid > ? ORDER BY rowid LIMIT ?',
        [ProgressScope.preview.name, cursor, pageSize],
      );
      for (final row in rows) {
        final lessonId = row['lesson_id'] as String;
        if (!lessonId.startsWith(reviewHistoryPrefix)) {
          history.include(lessonId, row['snapshot'] as String);
        }
        cursor = row['rowid'] as int;
      }
      if (rows.length < pageSize) return history.summarize();
    }
  });
}, retry: (count, error) => null);
