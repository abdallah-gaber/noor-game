import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';

import 'progress_test_support.dart';

void main() {
  testWidgets(
    'choice shows correct feedback and ignores a second tap before rebuild',
    (tester) async {
      await _start(tester, '/preview/challenges/shapes-choice');
      final triangle = find.widgetWithText(OutlinedButton, 'مثلّث');
      expect(tester.getSize(triangle).height, greaterThanOrEqualTo(48));
      expect(Directionality.of(tester.element(triangle)), TextDirection.rtl);
      expect(find.text(previewLabel), findsOneWidget);
      await tester.tap(triangle);
      await tester.tap(find.text('مربّع'));
      await tester.pumpAndSettle();
      expect(find.text('أحسنت! إجابة صحيحة'), findsOneWidget);
      expect(find.text('المثلّث له ثلاث زوايا.'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(triangle).onPressed, isNull);
    },
  );

  testWidgets(
    'true/false fits a phone at 2x and explains an incorrect answer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _start(tester, '/preview/challenges/shapes-true-false');
      expect(find.text('صح'), findsOneWidget);
      await tester.tap(find.text('خطأ'));
      await tester.pumpAndSettle();
      final explanation = find.text('نعم، للمربّع أربع زوايا.');
      await tester.ensureVisible(explanation);
      expect(explanation, findsOneWidget);
      expect(find.text('إجابة غير صحيحة. لنتعلّم معًا.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('direct developer challenge route is gated in public mode', (
    tester,
  ) async {
    await _start(tester, '/preview/challenges/shapes-choice', preview: false);
    expect(find.text('اختر عالمًا'), findsOneWidget);
    expect(find.text('أيّ شكل له ثلاث زوايا؟'), findsNothing);
  });

  test(
    'identical preview and approved IDs use separate provider snapshots',
    () async {
      final scope = ProviderContainer(
        overrides: [
          progressStoreProvider.overrideWithValue(MemoryProgressStore()),
        ],
      );
      addTearDown(scope.dispose);
      final preview = loadCurriculum();
      const approved = Curriculum(version: 'approved-1');
      final lesson = preview.lesson(WorldId.iman, 'iman-colors')!;
      final developer = progressProvider(preview.progressScope);
      final public = progressProvider(approved.progressScope);
      await scope.read(developer.future);
      await scope.read(public.future);
      await scope
          .read(developer.notifier)
          .saveStep(
            world: WorldId.iman,
            lesson: lesson,
            contentVersion: preview.version,
            index: 0,
            completed: true,
          );
      expect(
        scope.read(developer).requireValue.completedFor(preview, WorldId.iman),
        contains(lesson.id),
      );
      expect(
        scope.read(public).requireValue.completedFor(approved, WorldId.iman),
        isEmpty,
      );
      await scope
          .read(public.notifier)
          .saveStep(
            world: WorldId.iman,
            lesson: lesson,
            contentVersion: approved.version,
            index: 1,
            completed: false,
          );
      expect(
        scope.read(public).requireValue.completedFor(approved, WorldId.iman),
        isEmpty,
      );
      expect(
        scope.read(developer).requireValue.records[lesson.id]?.contentVersion,
        preview.version,
      );
    },
  );
}

Future<void> _start(
  WidgetTester tester,
  String location, {
  bool preview = true,
}) async {
  final router = createNoorRouter(
    initialLocation: location,
    enablePreview: preview,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(child: NoorApp(router: router)));
  await tester.pumpAndSettle();
}
