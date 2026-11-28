import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/adventure/wudu_challenge.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/challenges/arrangement.dart';
import 'package:noor/challenges/game_session.dart';
import 'package:noor/challenges/game_store.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/content/packs/bundled_catalog.dart';
import 'package:noor/content/packs/catalog.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/reward_progress.dart';
import 'package:noor/progress/reward_store.dart';
import 'package:noor/review/review_history.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';

const _route = '/preview/adventure/w06/challenge';
const _key = WuduChallenge.progressId;
const _independent = 'رتّبتها بنفسك! أحسنت!';
const _withNoor = 'أكملت الترتيب مع نور!';
const _hint = 'ضع القطعة المضيئة في مكانها.';
final _check = find.widgetWithText(FilledButton, 'تحقّق');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IntegratedCatalog catalog;
  late Arrangement ordering;
  late GamePlan plan;

  setUpAll(() async {
    catalog = (await loadBundledCatalog(rootBundle))!;
    ordering = catalog
        .toCurriculum()
        .lesson(WorldId.ibadah, 'W06')!
        .challenges
        .whereType<Arrangement>()
        .singleWhere((item) => item.id == 'W06.E01');
    plan = GamePlan('test-W06', [ordering], allowAssistedRetries: true);
  });

  test(
    'the approved evaluator records independent correctness after a retry',
    () {
      final right = ordering.correctOrder;
      final wrong = right.reversed.toList();
      var session = GameSession.start('independent', plan, _UnshuffledRandom());
      expect(session.optionsFor(ordering).map((item) => item.id), isNot(right));
      expect(session.submit(right.take(4).toList()), isNull);
      expect(session.assistedOrder, isNull);
      session = session.submit(wrong)!;
      expect(session.feedback?.correct, isFalse);
      expect(session.submit(right), isNull);
      session = session.advance()!;
      expect(session.assistedOrder, isNull);
      session = session.submit(right)!;
      expect(session.feedback?.assisted, isFalse);
      expect(session.feedback?.variantId, 'W06.E01');
      expect(session.feedback?.knowledgeIds, ['W06.K1', 'W06.K2']);
      session = session.advance()!;
      expect(session.finished, isTrue);
      expect(session.score, (scored: 1, firstCorrect: 0, eventuallyCorrect: 1));
    },
  );

  test(
    'assisted restoration completes once without crediting independent mastery',
    () {
      final wrong = ordering.correctOrder.reversed.toList();
      final started = GameSession.start('assisted', plan, Random(10));
      var session = started.submit(wrong)!.advance()!.submit(wrong)!;
      session = GameSession.restore(session.encode(), plan);
      expect(session.feedback?.correct, isFalse);
      expect(session.attempts.map((attempt) => attempt.assisted), [
        false,
        false,
      ]);
      session = session.advance()!;
      expect(session.assistedOrder, ordering.correctOrder);
      session = GameSession.restore(session.encode(), plan);
      expect(session.id, started.id);
      expect(session.optionOrder, started.optionOrder);
      final feedback = session.submit(ordering.correctOrder)!;
      expect(feedback.feedback?.correct, isTrue);
      expect(feedback.feedback?.assisted, isTrue);
      final completed = feedback.advance()!;
      final restored = GameSession.restore(completed.encode(), plan);
      expect(restored.finished, isTrue);
      expect(restored.attempts.last.assisted, isTrue);
      expect(restored.score, (
        scored: 1,
        firstCorrect: 0,
        eventuallyCorrect: 0,
      ));
      expect(restored.submit(ordering.correctOrder), isNull);

      final history = RewardHistory()..include(_key, feedback.encode());
      expect(history.summarize().xp, 0);
      history
        ..include(_key, completed.encode())
        ..include(_key, completed.encode());
      expect(history.summarize().xp, 10);
      expect(history.summarize().starsByLesson, {_key: 1});
      expect(history.summarize().knowledge['W06.K1']?.eventuallyCorrect, 0);
      final review = ReviewHistory()
        ..include(_key, restored.encode(), DateTime(2026, 11, 28));
      expect(review.knowledge('W06.K1')?.eventuallyCorrect, 0);

      final replay = GameSession.start(
        'replay',
        plan,
        Random(20),
      ).submit(ordering.correctOrder)!.advance()!;
      history
        ..include(_key, replay.encode())
        ..include(_key, replay.encode());
      expect(history.summarize().xp, 10);
      expect(history.summarize().starsByLesson, {_key: 3});
      expect(history.summarize().knowledge['W06.K1']?.firstCorrect, 0);
      expect(history.summarize().knowledge['W06.K1']?.eventuallyCorrect, 1);
      expect(
        GamePlan(plan.contentVersion, [ordering]).compatibility,
        isNot(plan.compatibility),
      );
    },
  );

  testWidgets(
    'drag and tap build one independent submission and one completion',
    (tester) async {
      _viewport(tester, const Size(1024, 640));
      final store = _PreviewGames();
      await _open(tester, catalog, store);
      final correct = ordering.correctOrder;
      expect(_button(tester, _check).onPressed, isNull);
      expect(find.text(_hint), findsNothing);
      expect(find.bySemanticsLabel('مقبض الصنبور'), findsNothing);

      // Place out of order spatially, then move it to the first slot by dragging.
      await _drag(tester, _piece(ordering, correct.first), _slot(2));
      await _drag(tester, _slot(2), _slot(0));
      expect(store.saved, isEmpty);
      for (final id in correct.skip(1)) {
        await tester.tap(_piece(ordering, id));
        await tester.pumpAndSettle();
      }
      expect(_button(tester, _check).onPressed, isNotNull);
      // Both calls use the same button closure before Flutter redraws it.
      final submit = _button(tester, _check).onPressed!;
      submit();
      submit();
      await tester.pumpAndSettle();
      expect(store.saved, hasLength(1));
      expect(store.session.attempts.single.answer, correct);
      expect(find.text(_independent), findsOneWidget);
      await _press(tester, 'إنهاء التحدّي');
      expect(store.saved, hasLength(2));
      expect(store.session.finished, isTrue);
      expect(store.session.attempts.single.assisted, isFalse);
      expect(find.text('العب مجددًا'), findsOneWidget);
    },
  );

  testWidgets(
    'portrait taps recover, restore assisted feedback, and replay in preview',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final store = _PreviewGames();
      var router = await _open(tester, catalog, store);
      final right = ordering.correctOrder;
      final wrong = right.reversed;
      final first = _piece(ordering, wrong.first);
      expect(tester.getSize(first).shortestSide, greaterThanOrEqualTo(48));
      await _fill(tester, ordering, wrong);
      await _press(tester, 'تحقّق');
      expect(find.text('اقتربت! جرّب ترتيبًا آخر.'), findsOneWidget);

      // A new router/widget reads the saved attempt and uses the same shuffle.
      final originalOrder = store.session.optionOrder;
      await tester.pumpWidget(const SizedBox.shrink());
      router = await _open(tester, catalog, store);
      expect(find.text('اقتربت! جرّب ترتيبًا آخر.'), findsOneWidget);
      expect(store.session.optionOrder, originalOrder);
      expect(store.session.attempts, hasLength(1));
      await _press(tester, 'جرّب مجددًا');
      expect(find.text(_hint), findsNothing);
      expect(_button(tester, _check).onPressed, isNull);
      await _fill(tester, ordering, wrong);
      await _press(tester, 'تحقّق');
      await _press(tester, 'جرّب مجددًا');
      expect(find.text(_hint), findsOneWidget);

      await tester.tap(first);
      await tester.pumpAndSettle();
      expect(first, findsOneWidget);
      await _fill(tester, ordering, right);
      await _press(tester, 'تحقّق');
      expect(find.text(_withNoor), findsOneWidget);
      await _press(tester, 'إنهاء التحدّي');
      expect(store.session.attempts.map((attempt) => attempt.assisted), [
        false,
        false,
        true,
      ]);
      expect(tester.takeException(), isNull);

      final firstId = store.session.id;
      router.go('/preview');
      await tester.pumpAndSettle();
      await tester.tap(find.text('معاينة تحدّي الوضوء'));
      await tester.pumpAndSettle();
      expect(find.text(_withNoor), findsOneWidget);
      await _press(tester, 'العب مجددًا');
      expect(store.session.id, isNot(firstId));
      expect(store.session.attempts, isEmpty);
      expect(store.sessions, hasLength(2));
      expect(_button(tester, _check).onPressed, isNull);
    },
  );

  testWidgets(
    'direct challenge access requires debug preview and approved catalog',
    (tester) async {
      final store = _PreviewGames();
      for (final (available, enabled) in [(catalog, false), (null, true)]) {
        await _open(tester, available, store, enablePreview: enabled);
        expect(find.byType(WuduChallenge), findsNothing);
        expect(find.text('أهلًا يا نور!'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      expect(store.sessions, isEmpty);
    },
  );
}

Finder _slot(int index) => find.byKey(ValueKey('wudu-slot-$index'));

Finder _piece(Arrangement definition, String id) => find.bySemanticsLabel(
  definition.items.singleWhere((item) => item.id == id).label,
);

FilledButton _button(WidgetTester tester, Finder finder) =>
    tester.widget<FilledButton>(finder);

Future<void> _fill(
  WidgetTester tester,
  Arrangement ordering,
  Iterable<String> ids,
) async {
  for (final id in ids) {
    await tester.tap(_piece(ordering, id));
    await tester.pumpAndSettle();
  }
}

Future<void> _press(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  expect(_button(tester, button).onPressed, isNotNull);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _drag(WidgetTester tester, Finder item, Finder target) async {
  final start = tester.getCenter(item);
  final end = tester.getCenter(target);
  final gesture = await tester.startGesture(start);
  await gesture.moveBy((end - start) / (end - start).distance * 24);
  await tester.pump();
  await gesture.moveTo(end);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<GoRouter> _open(
  WidgetTester tester,
  IntegratedCatalog? catalog,
  _PreviewGames store, {
  bool enablePreview = true,
}) async {
  final router = createNoorRouter(
    initialLocation: _route,
    catalog: catalog,
    enablePreview: enablePreview,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameStoreProvider.overrideWithValue(store),
        settingsStoreProvider.overrideWithValue(_SilentSettings()),
        previewRewardsProvider.overrideWith((ref) => const RewardProgress()),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _PreviewGames implements GameStore {
  final sessions = <String, String>{};
  final saved = <GameSession>[];
  late GameSession session;

  @override
  Future<GameSession> open(
    ProgressScope scope,
    String lessonId,
    GameSession draft, {
    String? replayOf,
  }) async {
    expect((scope, lessonId), (ProgressScope.preview, _key));
    if (sessions.isNotEmpty) {
      final previous = GameSession.restore(sessions.values.last, draft.plan);
      if (!previous.finished || previous.id != replayOf) {
        return session = previous;
      }
    }
    sessions[draft.id] = draft.encode();
    return session = draft;
  }

  @override
  Future<void> save(
    ProgressScope scope,
    WorldId world,
    String lessonId,
    GameSession next,
  ) async {
    expect(
      (scope, world, lessonId),
      (ProgressScope.preview, WorldId.ibadah, _key),
    );
    expect(next.revision, session.revision + 1);
    sessions[next.id] = next.encode();
    saved.add(next);
    session = next;
  }
}

class _SilentSettings implements SettingsStore {
  @override
  Future<AudioPreferences> load() async =>
      const AudioPreferences(effects: false);

  @override
  Future<void> save(AudioPreferences preferences) async {}
}

class _UnshuffledRandom implements Random {
  @override
  int nextInt(int max) => max - 1;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}
