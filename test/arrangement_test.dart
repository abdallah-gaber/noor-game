import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/challenges/arrangement.dart';
import 'package:noor/challenges/debug_catalog.dart';

void main() {
  test(
    'matching serializes pairs, rejects ambiguity and evaluates target order',
    () {
      final challenge = debugChallenges['shapes-matching']! as Arrangement;
      expect(
        Arrangement.fromJson(challenge.toJson()).evaluate(['three', 'four']),
        isTrue,
      );
      expect(challenge.evaluate(['four', 'three']), isFalse);
      expect(challenge.evaluate(['four', 'four']), isNull);
      final pair = {
        'left': {'id': 'a', 'label': 'أ'},
        'right': {'id': 'b', 'label': 'ب'},
      };
      expect(
        () => Arrangement.fromJson({
          ...challenge.toJson(),
          'pairs': [pair, pair],
        }),
        throwsFormatException,
      );
    },
  );

  test('ordering rejects missing or duplicate positions and evaluates a permutation', () {
    final challenge = debugChallenges['steps-ordering']! as Arrangement;
    expect(challenge.evaluate(['one', 'two', 'three']), isTrue);
    expect(challenge.evaluate(['two', 'one', 'three']), isFalse);
    expect(challenge.evaluate(['two', 'one']), isNull);
    expect(
      () => Arrangement.fromJson({
        ...challenge.toJson(),
        'correctOrder': ['one', 'two', 'two'],
      }),
      throwsFormatException,
    );
  });

  testWidgets('matching permits reassignment then evaluates a complete match', (
    tester,
  ) async {
    await _start(tester, 'shapes-matching');
    await _tap(tester, 'مثلّث');
    await _tap(tester, 'أربع زوايا');
    final submit = find.widgetWithText(FilledButton, 'تحقّق');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await _tap(tester, 'مثلّث');
    await _tap(tester, 'ثلاث زوايا');
    await _tap(tester, 'مربّع');
    await _tap(tester, 'أربع زوايا');
    await _tap(tester, 'تحقّق');
    expect(find.text('أحسنت! إجابة صحيحة'), findsOneWidget);
  });

  testWidgets(
    'ordering is tappable at large text and supports removal and reset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _start(tester, 'steps-ordering');
      await _tap(tester, 'ثلاثة');
      await _tap(tester, 'ثلاثة');
      await _tap(tester, 'اثنان');
      await _tap(tester, 'ابدأ من جديد');
      await _tap(tester, 'واحد');
      await _tap(tester, 'اثنان');
      await _tap(tester, 'ثلاثة');
      await _tap(tester, 'تحقّق');
      expect(find.text('أحسنت! إجابة صحيحة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _start(WidgetTester tester, String id) async {
  final router = createNoorRouter(initialLocation: '/preview/challenges/$id');
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(child: NoorApp(router: router)));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String title) async {
  final finder = find.text(title).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
