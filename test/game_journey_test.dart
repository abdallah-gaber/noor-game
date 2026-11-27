import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/challenges/game_session.dart';
import 'package:noor/challenges/game_store.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';
import 'package:noor/progress/reward_progress.dart';
import 'package:noor/progress/reward_store.dart';

import 'progress_test_support.dart';

const _lesson = '/worlds/iman/lessons/iman-activities';

void main() {
  testWidgets(
    'mixed lesson persists feedback, gates unlocks, then keeps replay history',
    (tester) async {
      final progress = MemoryProgressStore();
      final games = _Games(progress);
      await _launch(tester, _lesson, games);
      expect(find.text('أنهِ الدرس'), findsNothing);
      expect(progress.value.records['iman-activities'], isNull);
      await _tap(tester, 'إلى التحدّيات');
      games.fail = true;
      await _tap(tester, 'مربّع');
      expect(
        find.text('تعذّر فتح التقدّم أو حفظه. حاول مرة أخرى.'),
        findsOneWidget,
      );
      expect(games.sessions.single.attempts, isEmpty);
      games.fail = false;
      await _tap(tester, 'مربّع');
      expect(progress.value.records['iman-activities'], isNull);

      await _launch(tester, '$_lesson/play', games);
      expect(find.text('إجابة غير صحيحة. لنتعلّم معًا.'), findsOneWidget);
      await _tap(tester, 'التالي');
      await _tap(tester, 'صح');
      await _tap(tester, 'التالي');
      await _tap(tester, 'اكشف الإجابة');
      await _tap(tester, 'أريد المراجعة');
      await _tap(tester, 'التالي');
      await _tap(tester, 'مثلّث');
      await _tap(tester, 'ثلاث زوايا');
      await _tap(tester, 'مربّع');
      await _tap(tester, 'أربع زوايا');
      await _tap(tester, 'تحقّق');
      await _tap(tester, 'التالي');
      await _tap(tester, 'واحد');
      await _tap(tester, 'اثنان');
      await _tap(tester, 'ثلاثة');
      await _tap(tester, 'تحقّق');
      await _tap(tester, 'التالي');
      expect(find.text('لِنراجع ما تعلّمناه'), findsOneWidget);
      await _tap(tester, 'مثلّث');
      expect(progress.value.records['iman-activities'], isNull);
      await _tap(tester, 'النتيجة');
      expect(find.text('أكملتَ التحدّيات!'), findsOneWidget);
      expect(find.textContaining('نجوم الدرس:'), findsOneWidget);
      expect(find.textContaining('مجموع نقاط الخبرة:'), findsOneWidget);
      expect(games.sessions.single.score, (
        scored: 4,
        firstCorrect: 3,
        eventuallyCorrect: 4,
      ));
      expect(progress.value.records['iman-activities']?.completed, isTrue);
      expect(progress.approved.records, isEmpty);

      await _tap(tester, 'أعد التحدّيات');
      expect(games.sessions, hasLength(2));
      expect(games.sessions.first.finished, isTrue);
      expect(games.sessions.last.attempts, isEmpty);
      await _launch(tester, '/worlds/iman', games);
      expect(find.bySemanticsLabel('تحدّيات الأشكال، مكتمل'), findsOneWidget);
      final unlocked = find.bySemanticsLabel('خطوة بعد التحدّيات، متاح');
      await tester.ensureVisible(unlocked);
      expect(unlocked, findsOneWidget);
    },
  );

  test('reading progress API rejects completion for a mixed lesson', () async {
    final container = ProviderContainer(
      overrides: [
        progressStoreProvider.overrideWithValue(MemoryProgressStore()),
      ],
    );
    addTearDown(container.dispose);
    final curriculum = loadCurriculum();
    final lesson = curriculum.lesson(WorldId.iman, 'iman-activities')!;
    final provider = progressProvider(ProgressScope.preview);
    await container.read(provider.future);
    await expectLater(
      container
          .read(provider.notifier)
          .saveStep(
            world: WorldId.iman,
            lesson: lesson,
            contentVersion: curriculum.version,
            index: 0,
            completed: true,
          ),
      throwsStateError,
    );
    expect(container.read(provider).requireValue.records, isEmpty);
  });

  testWidgets(
    'public mode and a reading-only lesson reject direct game routes',
    (tester) async {
      await _launch(
        tester,
        '$_lesson/play',
        _Games(MemoryProgressStore()),
        preview: false,
      );
      expect(find.text('الدروس قيد الإعداد.'), findsOneWidget);
      expect(find.text('التحدّيات'), findsNothing);
      await _launch(
        tester,
        '/worlds/iman/lessons/iman-colors/play',
        _Games(MemoryProgressStore()),
      );
      expect(find.text('لونُ السماء'), findsOneWidget);
      expect(find.text('التحدّيات'), findsNothing);
    },
  );
}

Future<void> _launch(
  WidgetTester tester,
  String path,
  _Games games, {
  bool preview = true,
}) async {
  final router = createNoorRouter(
    initialLocation: path,
    enablePreview: preview,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey(router),
      overrides: [
        progressStoreProvider.overrideWithValue(games.progress),
        gameStoreProvider.overrideWithValue(games),
        previewRewardsProvider.overrideWith((ref) {
          final history = RewardHistory();
          for (final session in games.sessions) {
            history.include('iman-activities', session.encode());
          }
          return history.summarize();
        }),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

class _Games implements GameStore {
  _Games(this.progress);

  final MemoryProgressStore progress;
  final List<GameSession> sessions = [];
  bool fail = false;

  @override
  Future<GameSession> open(
    ProgressScope scope,
    String lessonId,
    GameSession draft, {
    String? replayOf,
  }) async {
    expect(scope, ProgressScope.preview);
    final prior = sessions.lastOrNull;
    if (prior != null && (!prior.finished || prior.id != replayOf)) {
      return GameSession.restore(prior.encode(), draft.plan);
    }
    sessions.add(draft);
    return draft;
  }

  @override
  Future<void> save(
    ProgressScope scope,
    WorldId world,
    String lessonId,
    GameSession session,
  ) async {
    if (fail) throw StateError('Test save error');
    expect(session.revision, sessions.last.revision + 1);
    sessions[sessions.length - 1] = session;
    if (session.finished) {
      await progress.save(
        scope,
        LessonProgress(
          world: world,
          lessonId: lessonId,
          contentVersion: session.plan.contentVersion,
          stepIndex: 0,
          completed: true,
          updatedAt: 0,
        ),
      );
    }
  }
}
