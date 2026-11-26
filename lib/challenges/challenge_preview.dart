import 'dart:math';

import 'package:flutter/material.dart';

import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import 'challenge_definition.dart';
import 'flashcard.dart';
import 'flashcard_view.dart';
import 'question_view.dart';
import 'scored_question.dart';

const challengePreviewIds = [
  'shapes-choice',
  'shapes-true-false',
  'shapes-flashcard',
];

final debugChallenges = <String, ChallengeDefinition>{
  challengePreviewIds[0]: ScoredQuestion.fromJson({
    'schema': 1,
    'id': challengePreviewIds[0],
    'type': 'multipleChoice',
    'knowledgeIds': ['preview.geometry.triangle'],
    'prompt': 'أيّ شكل له ثلاث زوايا؟',
    'explanation': 'المثلّث له ثلاث زوايا.',
    'correctOptionId': 'triangle',
    'options': [
      {'id': 'circle', 'label': 'دائرة', 'illustration': 'circle'},
      {'id': 'triangle', 'label': 'مثلّث', 'illustration': 'triangle'},
      {'id': 'square', 'label': 'مربّع', 'illustration': 'square'},
    ],
  }),
  challengePreviewIds[1]: ScoredQuestion.fromJson({
    'schema': 1,
    'id': challengePreviewIds[1],
    'type': 'trueFalse',
    'knowledgeIds': ['preview.geometry.square'],
    'prompt': 'للمربّع أربع زوايا.',
    'explanation': 'نعم، للمربّع أربع زوايا.',
    'correctOptionId': 'true',
  }),
  challengePreviewIds[2]: Flashcard.fromJson({
    'schema': 1,
    'type': 'flashcard',
    'id': challengePreviewIds[2],
    'knowledgeIds': ['preview.geometry.circle'],
    'prompt': 'ما اسم الشكل المستدير؟',
    'answer': 'دائرة.',
  }),
};

class ChallengePreview extends StatefulWidget {
  const ChallengePreview({super.key, required this.id});

  final String id;

  @override
  State<ChallengePreview> createState() => _ChallengePreviewState();
}

class _ChallengePreviewState extends State<ChallengePreview> {
  late final _definition = debugChallenges[widget.id]!;
  late final _order = (_definition as ScoredQuestion).presentationOrder(
    Random(),
  );
  String? _selectedId;
  bool _revealed = false;
  Recall? _recall;

  void _answer(String id) {
    if (_selectedId != null ||
        (_definition as ScoredQuestion).evaluate(id) == null) {
      return;
    }
    setState(() => _selectedId = id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const NoorAppBar('تجربة الأسئلة'),
    body: NoorPage(
      maxWidth: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(previewLabel),
          const SizedBox(height: 12),
          switch (_definition) {
            final ScoredQuestion question => QuestionView(
              question: question,
              options: _order,
              selectedId: _selectedId,
              onAnswer: _answer,
            ),
            final Flashcard card => FlashcardView(
              card: card,
              revealed: _revealed,
              recall: _recall,
              onReveal: () => setState(() => _revealed = true),
              onRecall: (recall) => setState(() => _recall ??= recall),
            ),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    ),
  );
}
