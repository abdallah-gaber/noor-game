import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/challenges/debug_catalog.dart';
import 'package:noor/challenges/game_session.dart';
import 'package:noor/challenges/scored_question.dart';
import 'package:noor/progress/progress_store.dart';
import 'package:noor/review/review_history.dart';
import 'package:noor/review/review_selection.dart';
import 'package:noor/review/review_store.dart';
import 'package:noor/storage/noor_database.dart';
import 'package:sqflite/sqflite.dart';

import 'progress_test_support.dart';

final _choice = debugChallenges['shapes-choice']! as ScoredQuestion;
final _pool = [
  for (final challenge in debugChallenges.values)
    (lessonId: 'geometry', challenge: challenge),
];
final _today = DateTime(2026, 11, 27);

void main() {
  test(
    'weak knowledge and a missed variant win without duplicating prompts',
    () {
      final history = ReviewHistory();
      final round = GameSession.start(
        'first',
        reviewPlan([_choice]),
        Random(0),
      ).submit(['square'])!.advance()!.submit(['triangle'])!.advance()!;
      history.include('geometry', round.encode(), _today);
      final result = history.knowledge(_choice.knowledgeIds.single)!;
      expect(
        (result.firstCorrect, result.recentCorrect, result.eventuallyCorrect),
        (0, 0, 1),
      );
      expect(nextPractice(result, spacingDays), DateTime(2026, 11, 28));
      final samePrompt = ScoredQuestion.fromJson({
        ..._choice.toJson(),
        'id': 'another',
      });
      final selection = selectReview(
        [..._pool, (lessonId: 'geometry', challenge: samePrompt)],
        history,
        spacingDays,
        _today,
      );
      expect(selection.first.id, _choice.id);
      expect(
        selection.map((item) => item.prompt).toSet(),
        hasLength(selection.length),
      );
      expect(selection, hasLength(5));
    },
  );

  test('spacing advances across successful dates, not repeat rounds', () {
    final history = ReviewHistory();
    final round = GameSession.start(
      'right',
      reviewPlan([_choice]),
      Random(0),
    ).submit(['triangle'])!.advance()!;
    for (final day in [1, 1, 2, 3, 4]) {
      history.include('geometry', round.encode(), DateTime(2026, 11, day));
    }
    final result = history.knowledge(_choice.knowledgeIds.single)!;
    expect(result.scored, 1);
    expect(result.recentScored, 5);
    expect(nextPractice(result, spacingDays), DateTime(2026, 11, 18));
    expect(nextPractice(result, [1, 7]), DateTime(2026, 11, 11));
  });

  test(
    'daily selection, answers and interval preferences survive a new store',
    () async {
      final database = _MemoryNoorDatabase();
      final store = ReviewStore(database);
      await store.setIntervals({1, 7});
      final first = (await store.open(
        ReviewMode.daily,
        [_pool.first],
        ReviewHistory(),
        await store.intervals(),
        _today,
      ))!;
      final answered = first.session.submit(['triangle'])!;
      await store.save(first.key, answered);
      final restarted = ReviewStore(database);
      expect(await restarted.intervals(), [1, 7]);

      final edited = ScoredQuestion.fromJson({
        ..._choice.toJson(),
        'prompt': 'A compatible edit',
      });
      final resumed = (await restarted.open(
        ReviewMode.daily,
        [(lessonId: 'geometry', challenge: edited)],
        await restarted.history(),
        [1, 7],
        _today,
      ))!;
      expect(resumed.session.id, first.session.id);
      expect(resumed.session.feedback?.correct, true);
      expect(resumed.session.current?.prompt, 'A compatible edit');
      final finished = resumed.session.advance()!;
      await restarted.save(resumed.key, finished);
      final today = (await restarted.open(
        ReviewMode.daily,
        _pool,
        await restarted.history(),
        [1, 7],
        _today,
        replayOf: finished.id,
      ))!;
      expect(today.session.id, finished.id);
      expect(today.session.finished, true);
      final tomorrow = (await restarted.open(
        ReviewMode.daily,
        _pool,
        await restarted.history(),
        [1, 7],
        DateTime(2026, 11, 28),
      ))!;
      expect(tomorrow.key, isNot(today.key));
      expect(tomorrow.session.attempts, isEmpty);
    },
  );

  testWidgets('preview launches daily play and public routes fall back home', (
    tester,
  ) async {
    final router = createNoorRouter(initialLocation: '/review');
    addTearDown(router.dispose);
    final progress = MemoryProgressStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noorDatabaseProvider.overrideWithValue(_MemoryNoorDatabase()),
          progressStoreProvider.overrideWithValue(progress),
        ],
        child: NoorApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('تحدّي اليوم'));
    await tester.pumpAndSettle();
    expect(find.textContaining('النشاط'), findsOneWidget);
    expect(find.textContaining('مجموع نقاط الخبرة'), findsNothing);
    expect(progress.value.records, isEmpty);
    expect(progress.approved.records, isEmpty);

    final public = createNoorRouter(
      initialLocation: '/review/daily',
      enablePreview: false,
    );
    addTearDown(public.dispose);
    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey("public"),
        child: NoorApp(router: public),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('اختر عالمًا'), findsOneWidget);
    expect(find.text('تحدّي اليوم'), findsNothing);
  });
}

class _MemoryNoorDatabase extends NoorDatabase {
  final _database = _MemoryDatabase();
  @override
  Future<Database> open() async => _database;
}

class _MemoryDatabase implements Database, Transaction {
  final _rows = <Map<String, Object?>>[];
  Map<String, Object?>? _settings;

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) => action(this);

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    if (table == 'preview_review_settings') {
      _settings = values;
    } else {
      expect(table, 'game_sessions');
      expect(values['scope'], 'preview');
      expect(values['lesson_id'], startsWith(reviewHistoryPrefix));
      _rows.add(values);
    }
    return 1;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    expect(table, 'game_sessions');
    final [scope, id, key, compatibility, revision] = whereArgs!;
    expect(scope, 'preview');
    final row = _rows.singleWhere(
      (row) =>
          row['id'] == id &&
          row['lesson_id'] == key &&
          row['compatibility'] == compatibility &&
          row['revision'] == revision,
    );
    row.addAll(values);
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (table == 'preview_review_settings') return [?_settings];
    expect(table, 'game_sessions');
    expect(whereArgs!.first, 'preview');
    if (whereArgs.length == 2) {
      return _rows.reversed
          .where((row) => row['lesson_id'] == whereArgs[1])
          .take(1)
          .toList();
    }
    return _rows.skip(offset ?? 0).take(limit ?? _rows.length).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
