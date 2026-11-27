import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/challenges/debug_catalog.dart';
import 'package:noor/challenges/game_session.dart';
import 'package:noor/progress/reward_progress.dart';
import 'package:noor/progress/reward_store.dart';
import 'package:noor/storage/noor_database.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  test(
    'old snapshots and improved replay earn XP once and keep first accuracy',
    () {
      final history = RewardHistory()
        ..include(
          'lesson',
          _round('original', 'v1', ['square', 'triangle']).encode(),
        );
      final first = history.summarize();
      expect(first.starsByLesson, {'lesson': 1});
      expect(first.xp, 10);
      expect(first.knowledge['preview.geometry.triangle'], (
        scored: 1,
        firstCorrect: 0,
        eventuallyCorrect: 1,
      ));

      final replay = _round('replayed', 'v2', ['triangle']).encode();
      history
        ..include('lesson', replay)
        ..include('lesson', replay);
      final after = history.summarize();
      expect(after.starsByLesson, {'lesson': 3});
      expect(after.xp, 10);
      expect(after.knowledge, first.knowledge);
      expect(first.starsByLesson['lesson'], 1);

      history.include('other-lesson', replay);
      final another = history.summarize();
      expect(another.stars, 6);
      expect(another.xp, 20);
      expect(another.knowledge, first.knowledge);
    },
  );

  test('open feedback and unscored flashcards award nothing', () {
    final pending = _round('pending', 'v1', []);
    final answered = pending.submit(['triangle'])!;
    final card = GameSession.start(
      'flashcard',
      GamePlan('v1', [debugChallenges['shapes-flashcard']!]),
      Random(0),
    ).submit(['remembered'])!.advance()!;
    final history = RewardHistory()
      ..include('empty', pending.encode())
      ..include('answered', answered.encode())
      ..include('flashcard', card.encode());
    expect(history.summarize().xp, 0);
    expect(history.summarize().knowledge, isEmpty);
  });

  test('rewards read through the preview scope only', () async {
    final database = _TestDatabase(
      _round('preview', 'v1', ['triangle']).encode(),
    );
    final container = ProviderContainer(
      overrides: [noorDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final progress = await container.read(previewRewardsProvider.future);
    expect(progress.xp, 10);
    expect(progress.starsByLesson, {'preview-lesson': 3});
  });
}

GameSession _round(String id, String version, List<String> answers) {
  var current = GameSession.start(
    id,
    GamePlan(version, [debugChallenges['shapes-choice']!]),
    Random(0),
  );
  for (final answer in answers) {
    current = current.submit([answer])!.advance()!;
  }
  return current;
}

class _TestDatabase extends NoorDatabase {
  _TestDatabase(String preview) : _database = _RewardDatabase(preview);
  final _RewardDatabase _database;

  @override
  Future<Database> open() async => _database;
}

class _RewardDatabase implements Database {
  _RewardDatabase(this.preview);
  final String preview;

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) => action(_RewardTransaction(preview));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RewardTransaction implements Transaction {
  _RewardTransaction(this.preview);
  final String preview;

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    expect(sql, contains('WHERE scope = ? AND rowid > ?'));
    expect(arguments, ['preview', 0, 32]);
    return [
      {'rowid': 1, 'lesson_id': 'preview-lesson', 'snapshot': preview},
      {
        'rowid': 2,
        'lesson_id': '@review/daily/2026-11-27',
        'snapshot': preview,
      },
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
