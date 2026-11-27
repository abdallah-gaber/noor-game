import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor/challenges/debug_catalog.dart';
import 'package:noor/challenges/game_session.dart';

void main() {
  test(
    'activity order, attempts and feedback restore with one bounded review',
    () {
      final plan = GamePlan('preview-1', debugChallenges.values.toList());
      var round = GameSession.start('first', plan, Random(4));
      expect(round.advance(), isNull);
      round = round.submit(['square'])!;
      expect(round.submit(['triangle']), isNull);
      final oldOrder = round.optionOrder;
      round = GameSession.restore(round.encode(), plan);
      expect(round.feedback?.knowledgeIds, ['preview.geometry.triangle']);
      expect(round.feedback?.correct, isFalse);
      expect(round.optionOrder, oldOrder);
      round = round.advance()!.submit(['true'])!.advance()!;
      round = round.submit(['remembered'])!.advance()!;
      round = round.submit(['three', 'four'])!.advance()!;
      round = round.submit(['one', 'two', 'three'])!.advance()!;
      expect(round.current?.id, 'shapes-choice');
      expect(round.finished, isFalse);
      round = round.submit(['triangle'])!.advance()!;
      expect(round.finished, isTrue);
      expect(round.score, (scored: 4, firstCorrect: 3, eventuallyCorrect: 4));
      expect(GameSession.restore(round.encode(), plan).score, round.score);
      expect(round.advance(), isNull);
      expect(
        GamePlan('preview-2', debugChallenges.values.toList()).compatibility,
        isNot(plan.compatibility),
      );
    },
  );

  test(
    'unscored and persistently incorrect activities complete without penalty',
    () {
      final flash = debugChallenges['shapes-flashcard']!;
      final plan = GamePlan('one', [flash]);
      final finished = GameSession.start(
        'flash',
        plan,
        Random(1),
      ).submit(['skipped'])!.advance()!;
      expect(finished.finished, isTrue);
      expect(finished.firstAttemptAccuracy, isNull);
      expect(finished.score, (
        scored: 0,
        firstCorrect: 0,
        eventuallyCorrect: 0,
      ));
      final choicePlan = GamePlan('one', [debugChallenges['shapes-choice']!]);
      final retry = GameSession.start(
        'retry',
        choicePlan,
        Random(1),
      ).submit(['square'])!.advance()!;
      final repeated = retry.submit(['square'])!.advance()!;
      expect(repeated.finished, isTrue);
      expect(repeated.queue, hasLength(2));
      expect(repeated.score, (
        scored: 1,
        firstCorrect: 0,
        eventuallyCorrect: 0,
      ));
      expect(
        GameSession.restore(repeated.encode(), choicePlan).finished,
        isTrue,
      );
      expect(() => GamePlan('one', [flash, flash]), throwsFormatException);
    },
  );
}
