import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/audio/speech_service.dart';
import 'package:noor/challenges/arrangement.dart';
import 'package:noor/challenges/flashcard.dart';
import 'package:noor/challenges/game_session.dart';
import 'package:noor/challenges/game_store.dart';
import 'package:noor/challenges/scored_question.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/content/packs/bundled_catalog.dart';
import 'package:noor/content/packs/catalog.dart';
import 'package:noor/content/packs/pack_document.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';
import 'package:noor/progress/reward_progress.dart';
import 'package:noor/progress/reward_store.dart';
import 'package:noor/review/review_history.dart';
import 'package:noor/review/review_selection.dart';
import 'package:noor/review/review_store.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';
import 'package:noor/storage/noor_database.dart';

import 'progress_test_support.dart';

const _lessons = {'I03', 'W05', 'W06', 'W08', 'S11', 'P10'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IntegratedCatalog catalog;
  setUpAll(() async {
    catalog = (await loadBundledCatalog(rootBundle))!;
  });

  test('signed-bundle entry point activates only approved starter records', () {
    expect(catalog.packs, hasLength(4));
    expect(catalog.records, hasLength(112));
    expect(
      catalog.recordsOf(RecordKind.lesson).map((record) => record.id).toSet(),
      _lessons,
    );
    expect(catalog.recordsOf(RecordKind.knowledge), hasLength(18));
    expect(catalog.recordsOf(RecordKind.variant), hasLength(65));
    for (final kind in [
      RecordKind.memorization,
      RecordKind.treasure,
      RecordKind.asset,
    ]) {
      expect(catalog.recordsOf(kind), isEmpty);
    }
    final manifest = jsonDecode(
      File('assets/curriculum/approvals.json').readAsStringSync(),
    ) as Map;
    expect(
      manifest['approvalRequestSha256'],
      '8fee836f366522ee8393efe3530af1f157c2e738c6ea589085f925c5b9cfcf41',
    );
    expect(
      (manifest['approvals'] as List).map((row) => row['reviewer']).toSet(),
      {'Project owner'},
    );
    expect(catalog.lifecycle('W05.K2').humanApproved, true);
  });

  testWidgets(
    'pack patch preserves lesson identities and shows release notes',
    (tester) async {
      final updated = catalog.packs['starter.iman']!;
      expect(updated.version.toString(), '0.1.2');
      final previousPacks = [
        for (final pack in catalog.packs.values)
          if (pack.id == updated.id)
            PackDocument.decode(
              jsonEncode({
                'schema': PackDocument.schema,
                'packId': pack.id,
                'version': '0.1.1',
                'channel': pack.channel.name,
                'records': [
                  for (final record in pack.records.values) record.data,
                ],
              }),
            )
          else
            pack,
      ];
      final ledger = ApprovalLedger.decodeTrusted(
        File('assets/curriculum/approvals.json').readAsStringSync(),
      );
      const ingestor = CatalogIngestor();
      final previous = ingestor.activate(previousPacks, approvals: ledger);
      final patched = ingestor.activate(
        [updated],
        approvals: ledger,
        previous: previous,
      );
      final original = previous.toCurriculum();
      final current = patched.toCurriculum();
      expect(current.version, isNot(original.version));
      for (final world in WorldId.values) {
        for (final unit in original.unitsFor(world)) {
          for (final lesson in unit.lessons) {
            expect(
              current.lesson(world, lesson.id)?.contentRevision,
              lesson.contentRevision,
            );
          }
        }
      }

      final router = createNoorRouter(catalog: catalog, enablePreview: false);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(child: NoorApp(router: router)));
      await tester.pumpAndSettle();
      expect(find.text('ما الجديد؟'), findsOneWidget);
      expect(find.text(catalog.releaseNotes.single), findsOneWidget);
    },
  );

  testWidgets(
    'approved lessons play all mechanics, resume and drive learning tools',
    (tester) async {
      final progress = MemoryProgressStore();
      final rounds = _ApprovedRounds(progress);
      final review = _ApprovedReview(rounds);
      final curriculum = catalog.toCurriculum();
      final exercised = <Object>{};
      final effects = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(PlatformSpeech.channel, (call) async {
        if (call.method == 'effect') effects.add(call.arguments as String);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(PlatformSpeech.channel, null),
      );

      Future<void> launch(String location) async {
        final router = createNoorRouter(
          catalog: catalog,
          enablePreview: false,
          initialLocation: location,
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(router),
            overrides: [
              settingsProvider.overrideWith(_EnabledAudioSettings.new),
              progressStoreProvider.overrideWithValue(progress),
              gameStoreProvider.overrideWithValue(rounds),
              rewardsProvider(ProgressScope.approved)
                  .overrideWith((_) => rounds.rewards()),
              reviewStoreFor(ProgressScope.approved).overrideWithValue(review),
            ],
            child: NoorApp(router: router),
          ),
        );
        await tester.pumpAndSettle();
      }

      for (final id in ['W05', 'W06']) {
        final lesson = curriculum.lesson(WorldId.ibadah, id)!;
        final path = '/worlds/ibadah/lessons/$id';
        await launch(path);
        for (var step = 1; step < lesson.steps.length; step++) {
          await _tap(tester, 'التالي');
        }
        await _tap(tester, 'إلى التحدّيات');
        for (final (index, definition) in lesson.challenges.indexed) {
          switch (definition) {
            case ScoredQuestion question:
              exercised.add(question.kind);
              await _tap(
                tester,
                question.options
                    .singleWhere(
                      (option) => option.id == question.correctOptionId,
                    )
                    .label,
              );
            case Flashcard card:
              exercised.add(Flashcard);
              await _tap(tester, 'اكشف الإجابة');
              expect(find.text(card.answer), findsWidgets);
              await _tap(tester, 'تذكّرت');
            case Arrangement arrangement:
              exercised.add(arrangement.kind);
              for (final (position, answer)
                  in arrangement.correctOrder.indexed) {
                if (arrangement.kind == ArrangementKind.matching) {
                  await _tap(tester, arrangement.targets[position].label);
                }
                await _tap(
                  tester,
                  arrangement.items
                      .singleWhere((item) => item.id == answer)
                      .label,
                );
              }
              await _tap(tester, 'تحقّق');
            default:
              fail('Unexpected starter mechanic');
          }
          if (index == 0 && id == 'W05') {
            await launch('$path/play');
            expect(find.textContaining('إجابة صحيحة'), findsWidgets);
          }
          await _tap(
            tester,
            index == lesson.challenges.length - 1 ? 'النتيجة' : 'التالي',
          );
        }
        expect(find.text('أكملتَ التحدّيات!'), findsOneWidget);
        expect(find.textContaining('مجموع نقاط الخبرة'), findsOneWidget);
        expect(progress.approved.records[id]?.completed, true);
      }
      expect(exercised, {
        QuestionKind.multipleChoice,
        QuestionKind.trueFalse,
        Flashcard,
        ArrangementKind.matching,
        ArrangementKind.ordering,
      });
      expect(effects, containsAll(['tap', 'correct', 'complete']));
      expect(rounds.rewards().xp, 20);
      expect(progress.value.records, isEmpty);

      for (final mode in ReviewMode.values) {
        await launch('/review/${mode.name}');
        expect(find.textContaining('النشاط'), findsOneWidget);
        expect(find.textContaining('مجموع نقاط الخبرة'), findsNothing);
        expect(review.opened.last, mode);
      }

      await launch('/parent');
      expect(find.text('وضع الوالدين'), findsOneWidget);
      await _tap(tester, 'عالم العبادة');
      await _tap(
        tester,
        curriculum.lesson(WorldId.ibadah, 'W05')!.title,
        first: true,
      );
      await _tap(tester, 'مراجع الدرس');
      expect(find.byType(SelectableText), findsWidgets);
      expect(find.text('مراجع المسودة في انتظار التحقّق.'), findsNothing);

      await launch('/worlds/ibadah/lessons/W14');
      expect(find.text('عالم العبادة'), findsOneWidget);
      expect(find.text('إلى التحدّيات'), findsNothing);
      await launch('/preview/challenges/shapes-choice');
      expect(find.text('اختر عالمًا'), findsOneWidget);
    },
  );
}

Future<void> _tap(
  WidgetTester tester,
  String label, {
  bool first = false,
}) async {
  final matches = find.text(label);
  final target = first ? matches.first : matches.last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

class _EnabledAudioSettings extends SettingsController {
  @override
  Future<SettingsState> build() async =>
      (preferences: const AudioPreferences(), saving: false);
}

class _ApprovedRounds implements GameStore {
  _ApprovedRounds(this.progress);
  final MemoryProgressStore progress;
  final _snapshots = <String, String>{};

  @override
  Future<GameSession> open(
    ProgressScope scope,
    String lessonId,
    GameSession draft, {
    String? replayOf,
  }) async {
    expect(scope, ProgressScope.approved);
    final saved = _snapshots[lessonId];
    return saved == null ? draft : GameSession.restore(saved, draft.plan);
  }

  @override
  Future<void> save(
    ProgressScope scope,
    WorldId world,
    String lessonId,
    GameSession session,
  ) async {
    expect(scope, ProgressScope.approved);
    _snapshots[lessonId] = session.encode();
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

  RewardProgress rewards() {
    final history = RewardHistory();
    _snapshots.forEach(history.include);
    return history.summarize();
  }
}

class _ApprovedReview extends ReviewStore {
  _ApprovedReview(this.rounds)
    : super(NoorDatabase(), scope: ProgressScope.approved);
  final _ApprovedRounds rounds;
  final opened = <ReviewMode>[];

  @override
  Future<ReviewHistory> history() async {
    final history = ReviewHistory();
    rounds._snapshots.forEach(
      (lesson, snapshot) =>
          history.include(lesson, snapshot, DateTime(2026, 11, 27)),
    );
    return history;
  }

  @override
  Future<List<int>> intervals() async => spacingDays;

  @override
  Future<ReviewRound?> open(
    ReviewMode mode,
    List<ReviewCandidate> candidates,
    ReviewHistory history,
    List<int> intervals,
    DateTime now, {
    String? replayOf,
  }) async {
    opened.add(mode);
    final choices = selectReview(candidates, history, intervals, now);
    return (
      key: '@review/fixture',
      session: GameSession.start(mode.name, reviewPlan(choices), Random(2)),
    );
  }
}
