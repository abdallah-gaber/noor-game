import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../challenges/challenge_definition.dart';
import '../challenges/game_session.dart';
import '../challenges/game_store.dart';
import '../progress/lesson_progress.dart';
import '../storage/noor_database.dart';
import 'review_history.dart';
import 'review_selection.dart';

final reviewStoreProvider = Provider<ReviewStore>(
  (ref) => ReviewStore(ref.watch(noorDatabaseProvider)),
);
final reviewHistoryProvider = FutureProvider.autoDispose<ReviewHistory>(
  (ref) => ref.watch(reviewStoreProvider).history(),
  retry: (count, error) => null,
);
final reviewIntervalsProvider = FutureProvider.autoDispose<List<int>>(
  (ref) => ref.watch(reviewStoreProvider).intervals(),
  retry: (count, error) => null,
);

typedef ReviewRound = ({String key, GameSession session});

class ReviewStore {
  ReviewStore(this._database);
  final NoorDatabase _database;
  static const _scope = ProgressScope.preview;

  Future<ReviewHistory> history() async {
    final database = await _database.open();
    return database.transaction((tx) async {
      final history = ReviewHistory();
      const pageSize = 32;
      var offset = 0;
      while (true) {
        final rows = await tx.query(
          'game_sessions',
          columns: ['lesson_id', 'snapshot', 'updated_at'],
          where: 'scope = ?',
          whereArgs: [_scope.name],
          orderBy: 'COALESCE(updated_at, 0), rowid',
          limit: pageSize,
          offset: offset,
        );
        for (final row in rows) {
          final timestamp = row['updated_at'] as int?;
          history.include(
            row['lesson_id'] as String,
            row['snapshot'] as String,
            timestamp == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(timestamp),
          );
        }
        if (rows.length < pageSize) return history;
        offset += rows.length;
      }
    });
  }

  Future<List<int>> intervals() async {
    final database = await _database.open();
    final rows = await database.query('preview_review_settings');
    final mask = rows.firstOrNull?['interval_mask'] as int? ?? 15;
    return [
      for (final (index, days) in spacingDays.indexed)
        if (mask & (1 << index) != 0) days,
    ];
  }

  Future<void> setIntervals(Set<int> days) async {
    if (days.isEmpty || !spacingDays.toSet().containsAll(days)) {
      throw ArgumentError.value(days, 'days');
    }
    final mask = [
      for (final (index, day) in spacingDays.indexed)
        if (days.contains(day)) 1 << index,
    ].reduce((a, b) => a | b);
    final database = await _database.open();
    await database.insert('preview_review_settings', {
      'id': 1,
      'interval_mask': mask,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ReviewRound?> open(
    ReviewMode mode,
    List<ReviewCandidate> candidates,
    ReviewHistory history,
    List<int> intervals,
    DateTime now, {
    String? replayOf,
  }) async {
    final key = mode == ReviewMode.daily
        ? dailyReviewKey(now)
        : '${reviewHistoryPrefix}adaptive';
    final database = await _database.open();
    return database.transaction((tx) async {
      final rows = await tx.query(
        'game_sessions',
        columns: ['snapshot', 'compatibility'],
        where: 'scope = ? AND lesson_id = ?',
        whereArgs: [_scope.name, key],
        orderBy: 'rowid DESC',
        limit: 1,
      );
      if (rows.firstOrNull case final previous?) {
        final session = restoreReview(
          previous['snapshot'] as String,
          previous['compatibility'] as String,
          candidates,
        );
        if (session != null &&
            (mode == ReviewMode.daily ||
                !session.finished ||
                session.id != replayOf)) {
          return (key: key, session: session);
        }
      }
      final selection = selectReview(candidates, history, intervals, now);
      if (selection.isEmpty) return null;
      final random = Random.secure();
      final session = GameSession.start(
        '${now.microsecondsSinceEpoch}-${random.nextInt(1 << 30)}',
        reviewPlan(selection),
        random,
      );
      await tx.insert('game_sessions', {
        'scope': _scope.name,
        'id': session.id,
        'lesson_id': key,
        'compatibility': session.plan.compatibility,
        'revision': 0,
        'snapshot': session.encode(),
      });
      return (key: key, session: session);
    });
  }

  Future<void> save(String key, GameSession session) async {
    if (!key.startsWith(reviewHistoryPrefix)) {
      throw ArgumentError.value(key, 'key');
    }
    final database = await _database.open();
    await writeGameSnapshot(database, _scope, key, session);
  }
}

GameSession? restoreReview(
  String snapshot,
  String compatibility,
  List<ReviewCandidate> candidates,
) {
  final byId = {
    for (final candidate in candidates)
      candidate.challenge.id: candidate.challenge,
  };
  final data = jsonDecode(snapshot) as Map<String, dynamic>;
  final savedIds = (data['orders'] as Map).keys.cast<String>();
  final selection = <ChallengeDefinition>[];
  for (final id in savedIds) {
    final definition = byId[id];
    if (definition == null) return null;
    selection.add(definition);
  }
  if (selection.isEmpty) return null;
  final plan = reviewPlan(selection);
  return plan.compatibility == compatibility
      ? GameSession.restore(snapshot, plan)
      : null;
}
