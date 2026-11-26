import 'dart:math';

import 'package:flutter/material.dart';

import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import 'question_view.dart';
import 'scored_question.dart';

const challengePreviewIds = ['shapes-choice', 'shapes-true-false'];

final _fixtures = {
  challengePreviewIds[0]: ScoredQuestion.fromJson({
    'schema': 1,
    'id': challengePreviewIds[0],
    'type': 'multipleChoice',
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
    'prompt': 'للمربّع أربع زوايا.',
    'explanation': 'نعم، للمربّع أربع زوايا.',
    'correctOptionId': 'true',
  }),
};

class ChallengePreview extends StatefulWidget {
  const ChallengePreview({super.key, required this.id});

  final String id;

  @override
  State<ChallengePreview> createState() => _ChallengePreviewState();
}

class _ChallengePreviewState extends State<ChallengePreview> {
  late final _question = _fixtures[widget.id]!;
  late final _order = _question.presentationOrder(Random());
  String? _selectedId;

  void _answer(String id) {
    if (_selectedId != null || _question.evaluate(id) == null) return;
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
          QuestionView(
            question: _question,
            options: _order,
            selectedId: _selectedId,
            onAnswer: _answer,
          ),
        ],
      ),
    ),
  );
}
