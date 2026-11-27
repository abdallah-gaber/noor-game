import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/challenges/challenge_definition.dart';
import 'package:noor/challenges/debug_catalog.dart';
import 'package:noor/challenges/scored_question.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(800, 1280),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('all mechanics fit ${size.width}×${size.height} at $scale×', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final router = createNoorRouter(initialLocation: '/preview');
        addTearDown(router.dispose);
        await tester.pumpWidget(ProviderScope(child: NoorApp(router: router)));
        await tester.pumpAndSettle();
        for (final (id, label) in [
          ('shapes-choice', 'اختيار من متعدد'),
          ('shapes-true-false', 'صح أو خطأ'),
          ('shapes-flashcard', 'بطاقة تذكّر'),
          ('shapes-matching', 'تطابق'),
          ('steps-ordering', 'ترتيب'),
        ]) {
          final link = find.text(label);
          await tester.ensureVisible(link);
          await tester.tap(link);
          await tester.pumpAndSettle();
          final prompt = find.text(debugChallenges[id]!.prompt);
          expect(prompt, findsOneWidget);
          final context = tester.element(prompt);
          expect(Directionality.of(context), TextDirection.rtl);
          expect(
            MediaQuery.textScalerOf(context).scale(10),
            closeTo(10 * scale, 0.01),
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
      });
    }
  }

  test('answers with duplicate visible text fail validation even with distinct IDs', () {
    expect(visibleLabel(' خَيار  واحد '), visibleLabel('خَيار واحد\u200f'));
    expect(
      () => validateOptions(const [
        AnswerOption('first', 'خَيار واحد'),
        AnswerOption('second', ' خَيار  واحد\u200f '),
      ]),
      throwsFormatException,
    );
  });
}
