import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/progress/progress_store.dart';

import 'progress_test_support.dart';

void main() {
  test('preview IDs are stable, unique and resolve in the owning world', () {
    final catalog = loadCurriculum();
    final ids = <String>{};
    expect(catalog.version, 'preview-1');
    for (final world in WorldId.values) {
      expect(WorldId.fromId(world.id), world);
      final unit = catalog.unitsFor(world).single;
      expect(ids.add(unit.id), isTrue);
      for (final lesson in unit.lessons) {
        expect(ids.add(lesson.id), isTrue);
        expect(catalog.lesson(world, lesson.id), same(lesson));
        if (lesson.prerequisiteId case final prerequisite?) {
          expect(catalog.lesson(world, prerequisite), isNotNull);
        }
      }
    }
    expect(catalog.lesson(WorldId.ibadah, 'iman-colors'), isNull);
  });

  test('path status uses completion, prerequisites and current selection', () {
    final lessons = loadCurriculum().unitsFor(WorldId.iman).single.lessons;
    expect(
      lessons.map(
        (lesson) =>
            lesson.state(completed: {'iman-first'}, currentId: 'iman-colors'),
      ),
      LessonState.values,
    );
    expect(
      lessons.last.state(completed: {'iman-first', 'iman-colors'}),
      LessonState.available,
    );
  });

  testWidgets('four home worlds open the matching path on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _start(tester);
    for (final world in WorldId.values) {
      final tile = find.text(world.title);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.text(world.title), findsOneWidget);
      expect(find.text(previewLabel), findsOneWidget);
      expect(find.text('درب الاكتشاف'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('accessible path labels, locked stop and lesson navigation', (
    tester,
  ) async {
    await _start(tester, location: '/worlds/iman');
    for (final (title, state) in [
      ('أولى الخطوات', LessonState.completed),
      ('ألوانٌ حولنا', LessonState.current),
      ('لعبة الأشكال', LessonState.available),
      ('نهاية الدرب', LessonState.locked),
    ]) {
      final tile = find.bySemanticsLabel('$title، ${state.label}');
      expect(tile, findsOneWidget);
      expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.text('نهاية الدرب'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('درب الاكتشاف'), findsOneWidget);
    await tester.tap(find.text('ألوانٌ حولنا'));
    await tester.pumpAndSettle();
    expect(find.text('درب الاكتشاف'), findsNothing);
    expect(find.text('ألوانٌ حولنا'), findsOneWidget);
  });

  for (final path in [
    '/worlds/iman/lessons/iman-end',
    '/worlds/iman/lessons/ibadah-colors',
  ]) {
    testWidgets('invalid or locked lesson links recover from $path', (
      tester,
    ) async {
      await _start(tester, location: path);
      expect(find.text('درب الاكتشاف'), findsOneWidget);
    });
  }

  testWidgets('unknown world routes return to the map', (tester) async {
    await _start(tester, location: '/worlds/unknown');
    expect(find.text('اختر عالمًا'), findsOneWidget);
  });

  testWidgets(
    'public world shells reject developer fixtures and direct lesson routes',
    (tester) async {
      await _start(
        tester,
        location: '/worlds/iman/lessons/iman-colors',
        enablePreview: false,
      );
      expect(find.text('عالم الإيمان'), findsOneWidget);
      expect(find.text('الدروس قيد الإعداد.'), findsOneWidget);
      expect(find.text(previewLabel), findsNothing);
      expect(find.text('ألوانٌ حولنا'), findsNothing);
    },
  );
}

Future<void> _start(
  WidgetTester tester, {
  String? location,
  bool enablePreview = true,
}) async {
  final router = createNoorRouter(
    initialLocation: location,
    enablePreview: enablePreview,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(MemoryProgressStore()),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
}
