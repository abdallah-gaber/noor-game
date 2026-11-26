import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor/challenges/scored_question.dart';

const _choice = <String, Object?>{
  'schema': 1,
  'type': 'multipleChoice',
  'id': 'shapes',
  'knowledgeIds': ['geometry.triangle'],
  'prompt': 'اختر المثلث.',
  'explanation': 'للمثلث ثلاث زوايا.',
  'correctOptionId': 'triangle',
  'options': [
    {'id': 'triangle', 'label': 'مثلث', 'illustration': 'triangle'},
    {'id': 'square', 'label': 'مربع'},
    {'id': 'circle', 'label': 'دائرة'},
  ],
};

void main() {
  test('choice round-trips and evaluates the same IDs in shuffled orders', () {
    final question = ScoredQuestion.fromJson(_choice);
    final restored = ScoredQuestion.fromJson(
      jsonDecode(jsonEncode(question.toJson())) as Map<String, Object?>,
    );
    expect(restored.toJson(), _choice);
    expect(restored.evaluate('unknown'), isNull);
    final orders = <String>{};
    for (var seed = 0; seed < 12; seed++) {
      final choices = restored.presentationOrder(Random(seed));
      orders.add(choices.map((choice) => choice.id).join(','));
      expect(
        choices
            .where((option) => restored.evaluate(option.id) == true)
            .single
            .id,
        'triangle',
      );
      expect(restored.evaluate('square'), isFalse);
    }
    expect(orders.length, greaterThan(1));
  });

  test('true and false use fixed Arabic labels and stable IDs', () {
    final input = Map<String, Object?>.from(_choice)..remove('options');
    input['type'] = 'trueFalse';
    for (final correct in ['true', 'false']) {
      final question = ScoredQuestion.fromJson({
        ...input,
        'correctOptionId': correct,
      });
      expect(question.toJson()['type'], 'trueFalse');
      expect(
        question.presentationOrder(Random(3)).map((option) => option.label),
        ['صح', 'خطأ'],
      );
      expect(question.evaluate('true'), correct == 'true');
      expect(question.evaluate('false'), correct == 'false');
    }
    expect(
      () => ScoredQuestion.fromJson({
        ...input,
        'correctOptionId': 'true',
        'options': [],
      }),
      throwsFormatException,
    );
  });

  test('rejects unsupported and inconsistent definitions', () {
    for (final changes in <Map<String, Object?>>[
      {'schema': 2},
      {
        'knowledgeIds': ['geometry.triangle', 'geometry.triangle'],
      },
      {'knowledgeIds': []},
      {
        'options': [
          {'id': 'triangle', 'label': 'الشكل  الأول'},
          {'id': 'square', 'label': 'الشكل الأول'},
        ],
      },

      {'type': 'matching'},
      {'prompt': ' '},
      {'explanation': ''},
      {'correctOptionId': 'missing'},
      {
        'options': [
          {'id': 'triangle', 'label': 'أ'},
        ],
      },
      {
        'options': List.filled(5, {'id': 'triangle', 'label': 'أ'}),
      },
      {
        'options': [
          42,
          {'id': 'triangle', 'label': 'أ'},
        ],
      },
      {
        'options': [
          {'id': 'triangle', 'label': 'أ'},
          {'id': 'triangle', 'label': 'ب'},
        ],
      },
      {
        'options': [
          {'id': 'triangle', 'label': 'أ', 'illustration': '../secret'},
          {'id': 'square', 'label': 'ب'},
        ],
      },
    ]) {
      expect(
        () => ScoredQuestion.fromJson({..._choice, ...changes}),
        throwsFormatException,
        reason: '$changes',
      );
    }
  });
}
