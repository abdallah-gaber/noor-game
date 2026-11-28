import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/adventure/worship_adventure_map.dart';
import 'package:noor/adventure/wudu_discovery.dart';
import 'package:noor/adventure/wudu_treasure.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/audio/pilot_effects.dart';
import 'package:noor/audio/speech_service.dart';
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

final _chest = find.bySemanticsLabel('افتح الصندوق');
final _reveal = find.text('جوهرة القطرة');
final _collection = find.byType(WuduTreasures);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IntegratedCatalog catalog;

  setUpAll(() async => catalog = (await loadBundledCatalog(rootBundle))!);

  testWidgets(
    'completion opens a chest, rapid taps save one gem, and restart restores it',
    (tester) async {
      final progress = _TreasureProgress(eligible: true)
        ..hold = Completer<void>();
      final calls = _audioCalls(tester);
      await _launch(
        tester,
        catalog,
        progress,
        location: '/preview/adventure/w06/challenge',
      );

      await tester.tap(find.text('افتح صندوق الكنز'));
      await tester.pumpAndSettle();
      expect(_collection, findsOneWidget);
      expect(tester.getSize(_chest).shortestSide, greaterThanOrEqualTo(48));
      expect(_chest.hitTestable(), findsOneWidget);
      await tester.tap(_chest);
      await tester.tap(_chest);
      await tester.pump();
      expect(progress.writes, [(ProgressScope.preview, wuduTreasureId)]);
      expect(_reveal, findsNothing);

      progress.hold!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(_reveal, findsOneWidget);
      expect(find.bySemanticsLabel(NoorMood.celebrating.label), findsOneWidget);
      expect(
        find.text(catalog.records['W06.K3']!.text('text').split('. ').last),
        findsOneWidget,
      );
      expect(calls, [('effect', 'wudu_reveal')]);

      await tester.tap(find.text('إلى الخريطة'));
      await tester.pumpAndSettle();
      expect(find.byType(WuduGem), findsOneWidget);
      expect(find.text('أكملتها مع نور'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await _launch(tester, catalog, progress, location: worshipMapPath);
      expect(find.byType(WuduGem), findsOneWidget);
      await tester.tap(find.byTooltip('كنوزي'));
      await tester.pumpAndSettle();
      expect(_reveal, findsOneWidget);
      expect(_chest, findsNothing);
      expect(calls, [('effect', 'wudu_reveal')]);

      // Returning to the saved mission result advertises the map and replay, so
      // a completed replay cannot re-award the existing treasure.
      await tester.pumpWidget(const SizedBox.shrink());
      await _launch(
        tester,
        catalog,
        progress,
        location: '/preview/adventure/w06/challenge',
      );
      expect(find.text('افتح صندوق الكنز'), findsNothing);
      await tester.tap(find.text('العب مجددًا'));
      await tester.pumpAndSettle();
      final challenge = catalog
          .toCurriculum()
          .lesson(WorldId.ibadah, 'W06')!
          .challenges
          .whereType<Arrangement>()
          .singleWhere((item) => item.id == 'W06.E01');
      final labels = {for (final item in challenge.items) item.id: item.label};
      for (final id in challenge.correctOrder) {
        await tester.tap(find.bySemanticsLabel(labels[id]!));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('تحقّق'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إنهاء التحدّي'));
      await tester.pumpAndSettle();
      expect(find.text('افتح صندوق الكنز'), findsNothing);
      expect(progress.writes, hasLength(1));
      expect(
        progress.value.records.keys,
        containsAll([wuduMissionProgressId, wuduTreasureId]),
      );
      expect(progress.approved.records.keys, ['W06']);
    },
  );

  testWidgets(
    'reduced motion and muted audio show the earned treasure immediately',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final progress = _TreasureProgress(eligible: true);
      final calls = _audioCalls(tester);
      await _launch(tester, catalog, progress, effects: false);
      await tester.tap(_chest);
      await tester.pump();
      expect(_reveal, findsOneWidget);
      final chestMotion =
          tester
                  .widget<AnimatedBuilder>(
                    find.byKey(const ValueKey('wudu-chest-motion')),
                  )
                  .listenable
              as AnimationController;
      expect(chestMotion.isAnimating, isFalse);
      expect(chestMotion.value, 1);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving during a save still refreshes the map gem', (
    tester,
  ) async {
    final progress = _TreasureProgress(eligible: true)
      ..hold = Completer<void>();
    final calls = _audioCalls(tester);
    await _launch(tester, catalog, progress);
    await tester.tap(_chest);
    await tester.pump();
    expect(progress.writes, hasLength(1));
    await tester.tap(find.byTooltip('العودة إلى الخريطة'));
    await tester.pumpAndSettle();
    expect(find.byType(WuduGem), findsNothing);

    progress.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(WuduGem), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets(
    'a lesson completion in approved storage does not unlock the chest',
    (tester) async {
      final progress = _TreasureProgress(eligible: false);
      await _launch(tester, catalog, progress);
      expect(find.text('أكمل مهمة الوضوء'), findsOneWidget);
      expect(_chest, findsNothing);
      expect(_reveal, findsNothing);
      expect(progress.reads, [ProgressScope.preview]);
      expect(progress.writes, isEmpty);
    },
  );

  testWidgets('treasures follow the approved debug and draft gates', (
    tester,
  ) async {
    final progress = _TreasureProgress(eligible: true);
    for (final (source, enabled, pilot) in [
      (catalog, false, null),
      (null, true, null),
      (
        catalog,
        true,
        const Curriculum(version: 'draft', isPreview: true, isDraftPilot: true),
      ),
    ]) {
      await _launch(tester, source, progress, preview: enabled, draft: pilot);
      expect(_collection, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
    expect(progress.reads, isEmpty);
    expect(progress.writes, isEmpty);
  });

  test(
    'adventure effects use distinct cues, stop on opt-out and stay muted',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <(String, Object?)>[];
      messenger.setMockMethodCallHandler(PlatformSpeech.channel, (call) async {
        calls.add((call.method, call.arguments));
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(PlatformSpeech.channel, null),
      );
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(_Settings(true))],
      );
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);
      final player = container.read(pilotEffectsProvider);
      for (final effect in AdventureEffect.values) {
        player.playAdventure(effect);
      }
      await container
          .read(settingsProvider.notifier)
          .savePreferences(effects: false);
      player.playAdventure(AdventureEffect.reveal);
      expect(calls, [
        for (final effect in AdventureEffect.values)
          ('effect', 'wudu_${effect.name}'),
        ('stopEffects', null),
      ]);
    },
  );
}

List<(String, Object?)> _audioCalls(WidgetTester tester) {
  final calls = <(String, Object?)>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(PlatformSpeech.channel, (call) async {
    calls.add((call.method, call.arguments));
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(PlatformSpeech.channel, null),
  );
  return calls;
}

Future<void> _launch(
  WidgetTester tester,
  IntegratedCatalog? catalog,
  _TreasureProgress progress, {
  String location = worshipTreasuresPath,
  bool effects = true,
  bool preview = true,
  Curriculum? draft,
}) async {
  final router = createNoorRouter(
    initialLocation: location,
    catalog: catalog,
    enablePreview: preview,
    draftPilot: draft,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(progress),
        settingsStoreProvider.overrideWithValue(_Settings(effects)),
        gameStoreProvider.overrideWithValue(_FinishedRound()),
        previewRewardsProvider.overrideWith(
          (ref) =>
              const RewardProgress(starsByLesson: {wuduMissionProgressId: 1}),
        ),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
}

class _TreasureProgress extends MemoryProgressStore {
  _TreasureProgress({required bool eligible})
    : super(
        JourneyProgress(eligible ? {wuduMissionProgressId: _completed} : {}),
      ) {
    approved = const JourneyProgress({
      'W06': LessonProgress(
        world: WorldId.ibadah,
        lessonId: 'W06',
        contentVersion: 'approved',
        stepIndex: 0,
        completed: true,
        updatedAt: 1,
      ),
    });
  }

  static const _completed = LessonProgress(
    world: WorldId.ibadah,
    lessonId: wuduMissionProgressId,
    contentVersion: 'courtyard.W06.1',
    stepIndex: 0,
    completed: true,
    updatedAt: 1,
  );

  final writes = <(ProgressScope, String)>[];
  final reads = <ProgressScope>[];
  Completer<void>? hold;

  @override
  Future<JourneyProgress> load(ProgressScope scope) {
    reads.add(scope);
    return super.load(scope);
  }

  @override
  Future<LessonProgress> save(
    ProgressScope scope,
    LessonProgress record,
  ) async {
    writes.add((scope, record.lessonId));
    await hold?.future;
    return super.save(scope, record);
  }
}

class _FinishedRound implements GameStore {
  GameSession? _session;

  @override
  Future<GameSession> open(
    ProgressScope scope,
    String lessonId,
    GameSession draft, {
    String? replayOf,
  }) async {
    if (_session case final saved?) {
      if (saved.finished && saved.id == replayOf) return _session = draft;
      return saved;
    }
    final order = (draft.current! as Arrangement).correctOrder;
    final wrong = order.reversed.toList();
    return _session = draft
        .submit(wrong)!
        .advance()!
        .submit(wrong)!
        .advance()!
        .submit(order)!
        .advance()!;
  }

  @override
  Future<void> save(
    ProgressScope scope,
    WorldId world,
    String lessonId,
    GameSession session,
  ) async {
    _session = session;
  }
}

class _Settings implements SettingsStore {
  _Settings(this.effects);
  final bool effects;

  @override
  Future<AudioPreferences> load() async =>
      AudioPreferences(speech: true, effects: effects);

  @override
  Future<void> save(AudioPreferences preferences) async {}
}
