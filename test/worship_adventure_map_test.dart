import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/adventure/worship_adventure_map.dart';
import 'package:noor/adventure/wudu_challenge.dart';
import 'package:noor/adventure/wudu_preview.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/challenges/arrangement.dart';
import 'package:noor/challenges/game_session.dart';
import 'package:noor/challenges/game_store.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/content/packs/bundled_catalog.dart';
import 'package:noor/content/packs/catalog.dart';
import 'package:noor/home/noor_lantern.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';
import 'package:noor/progress/reward_progress.dart';
import 'package:noor/progress/reward_store.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';

import 'progress_test_support.dart';

const _mission = WuduChallenge.progressId;
final _fountain = find.bySemanticsLabel('نافورة الوضوء');
final _intro = find.text('ابدأ هنا');
final _gate = find.bySemanticsLabel('بوابة النخيل');
final _arcade = find.bySemanticsLabel('رواق الفوانيس');
final _challenge = find.bySemanticsLabel('التحدّي');
final _replay = find.bySemanticsLabel('أعد التحدّي');
final _map = find.byType(WorshipAdventureMap);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IntegratedCatalog catalog;

  setUpAll(() async {
    catalog = (await loadBundledCatalog(rootBundle))!;
  });

  testWidgets(
    'debug map opens W06 activities and future landmarks explain availability',
    (tester) async {
      _viewport(tester, const Size(1024, 640));
      final progress = _PreviewProgress();
      final games = _AdventureRounds(progress);
      await _open(tester, catalog, games, location: '/preview');

      await _tap(tester, find.text('خريطة عالم العبادة'));
      expect(_intro, findsOneWidget);
      expect(find.bySemanticsLabel(NoorMood.curious.label), findsOneWidget);
      await _tap(tester, _gate);
      expect(find.text('بوابة النخيل · غير متاح في المعاينة'), findsOneWidget);
      await _tap(tester, _arcade);
      expect(find.text('رواق الفوانيس · غير متاح في المعاينة'), findsOneWidget);
      expect(games.sessions, isEmpty);

      await _tap(tester, _fountain);
      expect(find.byType(WuduPreview), findsOneWidget);
      await _tap(tester, find.byTooltip('العودة إلى الخريطة'));
      expect(_map, findsOneWidget);
      expect(_intro, findsOneWidget);

      await _tap(tester, _challenge);
      expect(find.byType(WuduChallenge), findsOneWidget);
      expect(games.sessions, hasLength(1));
      await _tap(tester, find.byTooltip('العودة إلى الخريطة'));
      await _tap(tester, _challenge);
      expect(
        games.sessions,
        hasLength(1),
        reason: 'An unfinished round resumes.',
      );
      expect(progress.reads, everyElement(ProgressScope.preview));
    },
  );

  testWidgets(
    'map shows assisted completion, then independent replay under the same key',
    (tester) async {
      _viewport(tester, const Size(1024, 640));
      final progress = _PreviewProgress();
      final games = _AdventureRounds(progress, firstRoundWithHelp: true);
      await _open(tester, catalog, games);
      await _tap(tester, _challenge);
      expect(games.latest.usesAssistance, isTrue);
      await _solve(tester, games.ordering);
      await _tap(tester, find.text('إلى الخريطة'));
      expect(find.text('أكملتها مع نور'), findsOneWidget);
      expect(find.text('أكملتها بنفسك'), findsNothing);
      expect(_intro, findsNothing);

      await _tap(tester, _fountain);
      expect(find.byType(WuduPreview), findsOneWidget);
      await _tap(tester, find.byTooltip('العودة إلى الخريطة'));
      expect(find.text('أكملتها مع نور'), findsOneWidget);
      final original = games.latest.id;
      await _tap(tester, _replay);
      expect(games.latest.id, isNot(original));
      expect(games.latest.attempts, isEmpty);

      // Independence can be earned with a retry even when the best rating is 1.
      await _arrange(
        tester,
        games.ordering,
        games.ordering.correctOrder.reversed,
      );
      await _tap(tester, find.text('تحقّق'));
      await _tap(tester, find.text('جرّب مجددًا'));
      await _solve(tester, games.ordering);
      await _tap(tester, find.text('إلى الخريطة'));
      expect(find.text('أكملتها بنفسك'), findsOneWidget);
      expect(find.text('أكملتها مع نور'), findsNothing);
      expect(progress.value.records.keys, [_mission]);
      expect(progress.approved.records.keys, ['W06']);
      expect(games.rewards().xp, 10);
      expect(games.rewards().starsByLesson[_mission], 1);
    },
  );

  testWidgets(
    'portrait map keeps all four landmarks reachable at enlarged text',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _open(tester, catalog, _AdventureRounds(_PreviewProgress()));

      for (final landmark in [_fountain, _challenge, _gate, _arcade]) {
        expect(tester.getSize(landmark).shortestSide, greaterThanOrEqualTo(48));
        expect(landmark.hitTestable(), findsOneWidget);
      }
      await _tap(tester, _arcade);
      expect(find.text('رواق الفوانيس · غير متاح في المعاينة'), findsOneWidget);
      await _tap(tester, _fountain);
      expect(find.byType(WuduPreview), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'adventure map rejects disabled preview, missing catalog and draft mode',
    (tester) async {
      final progress = _PreviewProgress();
      final games = _AdventureRounds(progress);
      for (final (source, enabled, draft) in [
        (catalog, false, null),
        (null, true, null),
        (
          catalog,
          true,
          const Curriculum(
            version: 'draft-test',
            isPreview: true,
            isDraftPilot: true,
          ),
        ),
      ]) {
        await _open(
          tester,
          source,
          games,
          enablePreview: enabled,
          draftPilot: draft,
        );
        expect(_map, findsNothing);
        expect(
          find.text(
            draft == null ? 'أهلًا يا نور!' : 'أنا بالغ وأريد مراجعة المسودات',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      expect(progress.reads, isEmpty);
      expect(games.sessions, isEmpty);
    },
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _arrange(
  WidgetTester tester,
  Arrangement definition,
  Iterable<String> order,
) async {
  final labels = {for (final item in definition.items) item.id: item.label};
  for (final id in order) {
    await _tap(tester, find.bySemanticsLabel(labels[id]!));
  }
}

Future<void> _solve(WidgetTester tester, Arrangement definition) async {
  await _arrange(tester, definition, definition.correctOrder);
  await _tap(tester, find.text('تحقّق'));
  await _tap(tester, find.text('إنهاء التحدّي'));
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(
  WidgetTester tester,
  IntegratedCatalog? catalog,
  _AdventureRounds games, {
  bool enablePreview = true,
  Curriculum? draftPilot,
  String location = worshipMapPath,
}) async {
  final router = createNoorRouter(
    initialLocation: location,
    catalog: catalog,
    enablePreview: enablePreview,
    draftPilot: draftPilot,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameStoreProvider.overrideWithValue(games),
        progressStoreProvider.overrideWithValue(games.progress),
        previewRewardsProvider.overrideWith((ref) => games.rewards()),
        settingsStoreProvider.overrideWithValue(_SilentSettings()),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
}

class _PreviewProgress extends MemoryProgressStore {
  _PreviewProgress() {
    approved = const JourneyProgress({
      'W06': LessonProgress(
        world: WorldId.ibadah,
        lessonId: 'W06',
        contentVersion: 'starter',
        stepIndex: 1,
        completed: true,
        updatedAt: 1,
      ),
    });
  }

  final reads = <ProgressScope>[];

  @override
  Future<JourneyProgress> load(ProgressScope scope) {
    reads.add(scope);
    return super.load(scope);
  }
}

class _AdventureRounds implements GameStore {
  _AdventureRounds(this.progress, {this.firstRoundWithHelp = false});

  final _PreviewProgress progress;
  final bool firstRoundWithHelp;
  final sessions = <String, GameSession>{};

  GameSession get latest => sessions.values.last;
  Arrangement get ordering =>
      latest.plan.definitions.values.single as Arrangement;

  @override
  Future<GameSession> open(
    ProgressScope scope,
    String lessonId,
    GameSession draft, {
    String? replayOf,
  }) async {
    expect((scope, lessonId), (ProgressScope.preview, _mission));
    if (sessions.isNotEmpty && (!latest.finished || latest.id != replayOf)) {
      return latest;
    }
    var session = draft;
    if (sessions.isEmpty && firstRoundWithHelp) {
      final definition = draft.plan.definitions.values.single as Arrangement;
      final miss = definition.correctOrder.reversed.toList();
      session = draft.submit(miss)!.advance()!.submit(miss)!.advance()!;
    }
    sessions[draft.id] = session;
    return session;
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
      (ProgressScope.preview, WorldId.ibadah, _mission),
    );
    sessions[session.id] = session;
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
      history.include(_mission, round.encode());
    }
    return history.summarize();
  }
}

class _SilentSettings implements SettingsStore {
  @override
  Future<AudioPreferences> load() async =>
      const AudioPreferences(effects: false);

  @override
  Future<void> save(AudioPreferences preferences) async {}
}
