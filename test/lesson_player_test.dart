import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/home/noor_lantern.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';

import 'progress_test_support.dart';

const _lessonPath = '/worlds/iman/lessons/iman-colors';

void main() {
  test('a new curriculum version resets the step and preserves completion', () {
    const saved = LessonProgress(
      world: WorldId.iman,
      lessonId: 'iman-colors',
      contentVersion: 'preview-1',
      stepIndex: 2,
      completed: true,
      updatedAt: 42,
    );
    const progress = JourneyProgress({'iman-colors': saved});
    final current = loadCurriculum();
    const newer = Curriculum(version: 'preview-2');

    expect(saved.resumeIndex(current.version, 3), 2);
    expect(saved.resumeIndex(current.version, 2), 1);
    expect(saved.resumeIndex(newer.version, 3), 0);
    expect(progress.completedFor(newer, WorldId.iman), {'iman-colors'});
    expect(
      progress.currentFor(current, current.unitsFor(WorldId.iman).single),
      'iman-shapes',
    );
  });

  testWidgets(
    'lesson steps, restart, completion and replay use saved progress',
    (tester) async {
      final store = MemoryProgressStore();
      await _start(tester, store, _lessonPath);
      expect(find.text('لونُ السماء'), findsOneWidget);
      await _tap(tester, 'التالي');
      expect(find.text('لِنبحث عن لون'), findsOneWidget);
      await _tap(tester, 'السابق');
      expect(find.text('لونُ السماء'), findsOneWidget);
      await _tap(tester, 'التالي');

      await _start(tester, store, _lessonPath);
      expect(find.text('لِنبحث عن لون'), findsOneWidget);
      await _tap(tester, 'التالي');
      expect(find.text('ألوانٌ أخرى'), findsOneWidget);
      await _tap(tester, 'أنهِ الدرس');
      expect(find.text('أحسنت!'), findsOneWidget);
      expect(find.bySemanticsLabel(NoorMood.celebrating.label), findsOneWidget);
      await _tap(tester, 'إلى الدرب');
      expect(find.bySemanticsLabel('ألوانٌ حولنا، مكتمل'), findsOneWidget);
      expect(find.bySemanticsLabel('نهاية الدرب، متاح'), findsOneWidget);

      await _tap(tester, 'ألوانٌ حولنا');
      expect(find.text('لونُ السماء'), findsOneWidget);
      await _tap(tester, 'التالي');
      expect(store.value.records['iman-colors']?.completed, isTrue);
      expect(store.value.records['iman-colors']?.stepIndex, 1);
    },
  );

  testWidgets(
    'failed lesson saves stay on the current step and can be retried',
    (tester) async {
      final store = MemoryProgressStore()..failSave = true;
      await _start(tester, store, _lessonPath);
      await _tap(tester, 'التالي');
      expect(find.text('تعذّر حفظ الدرس. حاول مرة أخرى.'), findsOneWidget);
      expect(find.text('لونُ السماء'), findsOneWidget);
      store.failSave = false;
      await _tap(tester, 'التالي');
      expect(find.text('لِنبحث عن لون'), findsOneWidget);
    },
  );
}

Future<void> _start(
  WidgetTester tester,
  MemoryProgressStore store,
  String location,
) async {
  final router = createNoorRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey(router),
      overrides: [progressStoreProvider.overrideWithValue(store)],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
