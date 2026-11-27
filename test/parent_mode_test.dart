import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/challenges/debug_catalog.dart';
import 'package:noor/challenges/game_session.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/content/draft_pilot.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';
import 'package:noor/review/review_history.dart';
import 'package:noor/review/review_store.dart';

import 'progress_test_support.dart';

void main() {
  testWidgets(
    'parent reports scoped completion, accuracy and recommendations',
    (tester) async {
      final router = createNoorRouter(initialLocation: '/parent');
      addTearDown(router.dispose);
      final round =
          GameSession.start(
            'saved',
            GamePlan('preview', [
              debugChallenges['shapes-choice']!,
              debugChallenges['shapes-true-false']!,
            ]),
            Random(1),
          ).submit(['square'])!.advance()!.submit(['true'])!.advance()!.submit([
            'triangle',
          ])!.advance()!;
      final history = ReviewHistory()
        ..include('iman-activities', round.encode(), DateTime(2026, 11, 27));
      final progress = MemoryProgressStore(
        const JourneyProgress({
          'iman-activities': LessonProgress(
            world: WorldId.iman,
            lessonId: 'iman-activities',
            contentVersion: 'preview',
            stepIndex: 0,
            completed: true,
            updatedAt: 0,
          ),
        }),
      );
      // Populating the other scope must not change the preview report.
      progress.approved = const JourneyProgress({
        'iman-shapes': LessonProgress(
          world: WorldId.iman,
          lessonId: 'iman-shapes',
          contentVersion: 'approved',
          stepIndex: 0,
          completed: true,
          updatedAt: 0,
        ),
      });
      await _launch(tester, router, progress, history);
      expect(find.text('وضع الوالدين'), findsOneWidget);
      final locale = MaterialLocalizations.of(
        tester.element(find.text('وضع الوالدين')),
      );
      expect(
        find.text(
          '${locale.formatDecimal(1)} من ${locale.formatDecimal(6)} درس مكتمل',
        ),
        findsOneWidget,
      );
      await _tap(tester, 'عالم الإيمان');
      await _tap(tester, 'تحدّيات الأشكال', first: true);
      expect(find.textContaining('أول محاولة:'), findsNWidgets(2));
      expect(find.textContaining('الأداء الأخير:'), findsNWidgets(2));
      expect(find.textContaining('الصحيح في النهاية:'), findsNWidgets(2));
      expect(
        find.text('لا توجد مراجع دينية لهذا الدرس التجريبي.'),
        findsOneWidget,
      );

      await _tap(tester, 'عالم الإيمان');
      expect(find.text('نقاط القوّة'), findsOneWidget);
      expect(find.text('معارف تحتاج إلى مراجعة'), findsOneWidget);
      expect(find.text('النشاط الأخير'), findsOneWidget);
      expect(find.text('المربّع'), findsWidgets);
      expect(find.text('المثلّث'), findsWidgets);
      expect(find.text('فتح المراجعة المخصّصة'), findsOneWidget);
    },
  );

  const localPayload = String.fromEnvironment('NOOR_DRAFT_PILOT');
  if (localPayload.isNotEmpty) {
    testWidgets(
      'adult-gated draft references are selectable on a compact display',
      (tester) async {
        tester.view.physicalSize = const Size(720, 900);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final pilot = decodeDraftPilot(localPayload);
        final router = createNoorRouter(
          initialLocation: '/parent',
          draftPilot: pilot,
        );
        addTearDown(router.dispose);
        await _launch(tester, router, MemoryProgressStore(), ReviewHistory());
        expect(find.text('أنا بالغ وأريد مراجعة المسودات'), findsOneWidget);
        expect(find.text('وضع الوالدين'), findsNothing);
        await _tap(tester, 'أنا بالغ وأريد مراجعة المسودات');
        await _tap(tester, 'وضع الوالدين');
        final world = pilot.units.keys.first;
        final lesson = pilot.unitsFor(world).single.lessons.single;
        await _tap(tester, world.title);
        await _tap(tester, lesson.title, first: true);
        await _tap(tester, 'مراجع الدرس');
        expect(find.text('مراجع المسودة في انتظار التحقّق.'), findsOneWidget);
        final locators = tester
            .widgetList<SelectableText>(find.byType(SelectableText))
            .map((widget) => widget.data)
            .toSet();
        expect(locators, contains(lesson.sources.first.locator));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('public build falls back from Parent Mode', (tester) async {
    final router = createNoorRouter(
      initialLocation: '/parent',
      enablePreview: false,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(child: NoorApp(router: router)));
    await tester.pumpAndSettle();
    expect(find.text('اختر عالمًا'), findsOneWidget);
    expect(find.text('وضع الوالدين'), findsNothing);
  });
}

Future<void> _launch(
  WidgetTester tester,
  GoRouter router,
  MemoryProgressStore progress,
  ReviewHistory history,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(progress),
        reviewHistoryProvider.overrideWith((ref) => history),
        reviewIntervalsProvider.overrideWith((ref) => [1, 3, 7, 14]),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(
  WidgetTester tester,
  String label, {
  bool first = false,
}) async {
  final matches = find.text(label);
  final target = first ? matches.first : matches;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
