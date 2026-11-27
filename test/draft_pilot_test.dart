import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/challenges/scored_question.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/content/draft_pilot.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';

import 'progress_test_support.dart';

void main() {
  const localPayload = String.fromEnvironment('NOOR_DRAFT_PILOT');
  if (localPayload.isNotEmpty) {
    test(
      'the local pilot decodes with the selected lessons and all mechanics',
      () {
        final pilot = decodeDraftPilot(localPayload);
        final lessons = pilot.units.values.map(
          (units) => units.single.lessons.single,
        );
        expect(lessons.map((lesson) => lesson.id), [
          'W06',
          'I03',
          'S11',
          'P01',
        ]);
        expect(lessons.map((lesson) => lesson.challenges.length), [4, 4, 4, 3]);
        expect(lessons.first.steps, hasLength(4));
        expect(
          lessons.first.challenges.map((variant) => variant.id),
          contains('W06.E01'),
        );
        expect(
          lessons.elementAt(2).challenges.map((variant) => variant.id),
          contains('S11.E01'),
        );
      },
    );
  }

  test('projection retains authored identities, labels, and source checks', () {
    final pilot = decodeDraftPilot(_document());
    expect(pilot.progressScope, ProgressScope.preview);
    expect(pilot.units.keys, WorldId.values.reversed);
    final lesson = pilot.lesson(WorldId.ibadah, 'ibadah.example')!;
    final question = lesson.challenges.single as ScoredQuestion;
    expect(question.kind, QuestionKind.trueFalse);
    expect(question.id, 'ibadah.variant');
    expect(question.knowledgeIds, ['ibadah.fact']);
    expect(question.correctOptionId, 'example-yes');
    expect(question.options.first.label, 'صحيح');
    expect(question.evaluate('example-yes'), isTrue);
    expect(
      () => ScoredQuestion.fromJson(question.toJson()),
      throwsFormatException,
    );
    expect(
      () => decodeDraftPilot(_document(source: 'missing')),
      throwsFormatException,
    );
  });

  testWidgets(
    'a deep link requires adult entry and writes only preview progress',
    (tester) async {
      final progress = MemoryProgressStore();
      const lesson = '/worlds/ibadah/lessons/ibadah.example';
      final router = createNoorRouter(
        initialLocation: lesson,
        draftPilot: decodeDraftPilot(_document()),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [progressStoreProvider.overrideWithValue(progress)],
          child: NoorApp(router: router),
        ),
      );
      const confirm = 'أنا بالغ وأريد مراجعة المسودات';
      await tester.pumpAndSettle();
      expect(find.text(confirm), findsOneWidget);
      expect(find.text('Example reading'), findsNothing);

      router.go('$lesson/play');
      await tester.pumpAndSettle();
      expect(find.text(confirm), findsOneWidget);

      await tester.tap(find.text(confirm));
      await tester.pumpAndSettle();
      router.go(lesson);
      await tester.pumpAndSettle();
      expect(find.text(draftPilotLabel), findsOneWidget);
      expect(find.text('Example reading'), findsOneWidget);
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('Example activity'), findsOneWidget);
      expect(find.text('إلى التحدّيات'), findsOneWidget);
      expect(progress.value.records['ibadah.example']?.stepIndex, 1);
      expect(progress.approved.records, isEmpty);

      router.go('/adult-review');
      await tester.pumpAndSettle();
      router.go(lesson);
      await tester.pumpAndSettle();
      expect(find.text(confirm), findsOneWidget);
      expect(find.text('Example reading'), findsNothing);
    },
  );

  testWidgets('child routing ignores a supplied pilot', (tester) async {
    final router = createNoorRouter(
      initialLocation: '/worlds/ibadah/lessons/ibadah.example',
      enablePreview: false,
      draftPilot: decodeDraftPilot(_document()),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(child: NoorApp(router: router)));
    await tester.pumpAndSettle();
    expect(find.text('الدروس قيد الإعداد.'), findsOneWidget);
    expect(find.text(draftPilotLabel), findsNothing);
    expect(find.text('Example reading'), findsNothing);
  });
}

String _document({String source = 'example-source'}) => jsonEncode({
  'schema': 1,
  'lessons': [
    for (final world in WorldId.values.reversed)
      {
        'worldId': world.id,
        'id': '${world.id}.example',
        'unitId': '${world.id}.unit',
        'title': 'Example lesson',
        'knowledge': [
          {
            'id': '${world.id}.fact',
            'textAr': 'Example reading',
            'sourceRefs': [source],
          },
        ],
        'sources': [
          {'id': 'example-source'},
        ],
        'variants': [
          {
            'schema': 1,
            'id': '${world.id}.variant',
            'type': 'trueFalse',
            'knowledgeIds': ['${world.id}.fact'],
            'prompt': 'Example question',
            'explanation': 'Example explanation',
            'options': [
              {'id': 'example-yes', 'label': 'صحيح'},
              {'id': 'example-no', 'label': 'خطأ'},
            ],
            'correctOptionId': 'example-yes',
            'sourceRefs': [source],
          },
        ],
        'activity': 'Example activity',
      },
  ],
});
