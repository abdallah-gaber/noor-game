import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/adventure/adventure_routes.dart';
import 'package:noor/adventure/worship_adventure_map.dart';
import 'package:noor/adventure/wudu_discovery.dart';
import 'package:noor/adventure/wudu_treasure.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/audio/speech_service.dart';
import 'package:noor/challenges/arrangement.dart';
import 'package:noor/challenges/game_session.dart';
import 'package:noor/challenges/game_store.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/content/packs/bundled_catalog.dart';
import 'package:noor/content/packs/catalog.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';
import 'package:noor/progress/reward_progress.dart';
import 'package:noor/progress/reward_store.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';

import 'progress_test_support.dart';

final _map = find.byType(WorshipAdventureMap);
final _fountain = find.bySemanticsLabel('نافورة الوضوء');
final _treasures = find.byTooltip('كنوزي');
final _next = find.text('هيا نكمل');
final _toChallenge = find.text('جرّب التحدّي');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IntegratedCatalog catalog;

  setUpAll(() async => catalog = (await loadBundledCatalog(rootBundle))!);

  testWidgets('playtest starts at the map and redirects outside routes', (
    tester,
  ) async {
    final storage = _PlaytestStorage();
    tester.platformDispatcher.defaultRouteNameTestValue =
        '/preview/adventure/w06/challenge';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    final router = await _launch(tester, catalog, storage);
    expect(_map, findsOneWidget);
    expect(find.byTooltip('كتم الصوت'), findsOneWidget);
    expect(find.byTooltip('العودة إلى المعاينة'), findsNothing);
    expect(find.text('ابدأ هنا'), findsOneWidget);
    expect(Directionality.of(tester.element(_fountain)), TextDirection.rtl);

    for (final path in [
      '/preview',
      '/settings',
      '/parent',
      '/review',
      '/adult-review',
      '/worlds/ibadah',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(_map, findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/');
    }

    await _restart(tester, null, storage);
    expect(_map, findsNothing);
    expect(find.text('مغامرة الوضوء غير متاحة الآن.'), findsOneWidget);
    expect(storage.games.sessions, isEmpty);
    expect(storage.progress.value.records, isEmpty);
  });

  testWidgets(
    'W06 flows from discovery through saved assisted completion to independent replay',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final storage = _PlaytestStorage();
      final calls = <(String, Object?)>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(PlatformSpeech.channel, (call) async {
        calls.add((call.method, call.arguments));
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(PlatformSpeech.channel, null),
      );
      await _launch(tester, catalog, storage);

      await _tap(tester, find.byTooltip('كتم الصوت'));
      expect(storage.settings.preferences.effects, isFalse);
      await _tap(tester, _fountain);
      expect(_next, findsNothing);
      await _tap(tester, find.bySemanticsLabel('الكفّان'));
      expect(_next, findsNothing);
      await _tap(tester, find.bySemanticsLabel('قطرة الماء'));
      await _tap(tester, find.bySemanticsLabel('الكفّان'));
      await _tap(tester, _next);

      for (final station in [
        [WuduObject.mouth, WuduObject.nose],
        [WuduObject.face],
        [WuduObject.rightArm, WuduObject.leftArm],
        [WuduObject.head],
        [WuduObject.rightFoot, WuduObject.leftFoot],
      ]) {
        for (final object in station) {
          expect(_next, findsNothing);
          await _tap(tester, find.bySemanticsLabel(object.label));
        }
        await _tap(tester, _next);
      }

      expect(_toChallenge, findsNothing);
      await _tap(tester, find.bySemanticsLabel(WuduObject.tap.label));
      expect(storage.progress.value.records, isEmpty);
      expect(storage.games.sessions, isEmpty);
      await _tap(tester, _toChallenge);
      final match = storage.games.plan.definitions.values.single as Arrangement;
      final good = match.correctOrder;
      final wrong = good.reversed;
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'تحقّق'))
            .onPressed,
        isNull,
      );
      await _submit(tester, match, wrong);
      expect(find.text('اقتربت! جرّب ترتيبًا آخر.'), findsOneWidget);
      final firstRound = storage.games.current;
      expect(firstRound.attempts, hasLength(1));
      expect(storage.progress.value.records, isEmpty);

      tester.view.physicalSize = const Size(390, 844);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _restart(tester, catalog, storage);
      expect(find.byTooltip('تشغيل الصوت'), findsOneWidget);
      await _tap(tester, find.bySemanticsLabel('التحدّي'));
      expect(find.text('اقتربت! جرّب ترتيبًا آخر.'), findsOneWidget);
      expect(storage.games.current.optionOrder, firstRound.optionOrder);
      await _tap(tester, find.text('جرّب مجددًا'));
      expect(find.text('ضع القطعة المضيئة في مكانها.'), findsNothing);
      await _submit(tester, match, wrong);
      await _tap(tester, find.text('جرّب مجددًا'));
      expect(find.text('ضع القطعة المضيئة في مكانها.'), findsOneWidget);
      await _submit(tester, match, good);
      expect(find.text('أكملت الترتيب مع نور!'), findsOneWidget);
      await _tap(tester, find.text('إنهاء التحدّي'));
      expect(storage.games.current.attempts.last.assisted, isTrue);
      await _tap(tester, find.text('افتح صندوق الكنز'));

      final chest = find.bySemanticsLabel('افتح الصندوق');
      expect(tester.getSize(chest).shortestSide, greaterThanOrEqualTo(48));
      await _tap(tester, chest);
      expect(find.text('جوهرة القطرة'), findsOneWidget);
      expect(
        find.text(catalog.records['W06.K3']!.text('text').split('. ').last),
        findsOneWidget,
      );
      await _tap(tester, find.text('إلى الخريطة'));
      expect(find.text('أكملتها مع نور'), findsOneWidget);
      expect(find.byType(WuduGem), findsOneWidget);
      expect(calls, isEmpty);

      await _restart(tester, catalog, storage);
      expect(find.byType(WuduGem), findsOneWidget);
      await _tap(tester, _treasures);
      expect(find.text('جوهرة القطرة'), findsOneWidget);
      expect(chest, findsNothing);
      await _tap(tester, find.text('إلى الخريطة'));
      await _tap(tester, find.bySemanticsLabel('أعد التحدّي'));
      expect(storage.games.current.id, isNot(firstRound.id));
      await _submit(tester, match, good);
      expect(find.text('رتّبتها بنفسك! أحسنت!'), findsOneWidget);
      await _tap(tester, find.text('إنهاء التحدّي'));
      expect(find.text('افتح صندوق الكنز'), findsNothing);
      await _tap(tester, find.text('إلى الخريطة'));
      expect(find.text('أكملتها بنفسك'), findsOneWidget);
      expect(find.byType(WuduGem), findsOneWidget);
      expect(
        storage.progress.value.records.keys,
        unorderedEquals([wuduMissionProgressId, wuduTreasureId]),
      );
      expect(storage.progress.approved.records, isEmpty);
      expect(storage.games.rewards().xp, 10);
      expect(storage.games.sessions, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _submit(
  WidgetTester tester,
  Arrangement match,
  Iterable<String> ids,
) async {
  final labels = {for (final item in match.items) item.id: item.label};
  for (final id in ids) {
    await _tap(tester, find.bySemanticsLabel(labels[id]!));
  }
  await _tap(tester, find.text('تحقّق'));
}

Future<GoRouter> _launch(
  WidgetTester tester,
  IntegratedCatalog? catalog,
  _PlaytestStorage storage,
) async {
  final router = createAdventurePlaytestRouter(catalog: catalog);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameStoreProvider.overrideWithValue(storage.games),
        progressStoreProvider.overrideWithValue(storage.progress),
        settingsStoreProvider.overrideWithValue(storage.settings),
        previewRewardsProvider.overrideWith((ref) => storage.games.rewards()),
      ],
      child: NoorApp(router: router, title: 'نور — المغامرة'),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _restart(
  WidgetTester tester,
  IntegratedCatalog? catalog,
  _PlaytestStorage storage,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await _launch(tester, catalog, storage);
}

class _PlaytestStorage {
  final progress = MemoryProgressStore();
  final settings = _PlaytestSettings();
  late final games = _PlaytestRounds(progress);
}

class _PlaytestRounds implements GameStore {
  _PlaytestRounds(this.progress);
  final MemoryProgressStore progress;
  final sessions = <String, String>{};
  late GamePlan plan;

  GameSession get current => GameSession.restore(sessions.values.last, plan);

  @override
  Future<GameSession> open(
    ProgressScope scope,
    String lessonId,
    GameSession draft, {
    String? replayOf,
  }) async {
    expect((scope, lessonId), (ProgressScope.preview, wuduMissionProgressId));
    plan = draft.plan;
    if (sessions.isNotEmpty && (!current.finished || current.id != replayOf)) {
      return current;
    }
    final started = GameSession.start(draft.id, plan, Random(sessions.length));
    sessions[started.id] = started.encode();
    return started;
  }

  @override
  Future<void> save(
    ProgressScope scope,
    WorldId world,
    String lessonId,
    GameSession session,
  ) async {
    expect(
      (scope, world, lessonId),
      (ProgressScope.preview, WorldId.ibadah, wuduMissionProgressId),
    );
    expect(session.revision, current.revision + 1);
    sessions[session.id] = session.encode();
    if (!session.finished) return;
    await progress.save(
      scope,
      LessonProgress(
        world: world,
        lessonId: lessonId,
        contentVersion: session.plan.contentVersion,
        stepIndex: 0,
        completed: true,
        updatedAt: session.revision,
      ),
    );
  }

  RewardProgress rewards() {
    final history = RewardHistory();
    for (final round in sessions.values) {
      history.include(wuduMissionProgressId, round);
    }
    return history.summarize();
  }
}

class _PlaytestSettings implements SettingsStore {
  AudioPreferences preferences = const AudioPreferences();

  @override
  Future<AudioPreferences> load() async => preferences;

  @override
  Future<void> save(AudioPreferences value) async => preferences = value;
}
