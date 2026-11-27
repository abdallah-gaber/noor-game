import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/pilot_effects.dart';

import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import 'arrangement.dart';
import 'arrangement_view.dart';
import 'challenge_definition.dart';
import 'flashcard.dart';
import 'flashcard_view.dart';
import 'question_view.dart';
import 'scored_question.dart';

class ChallengePreview extends ConsumerStatefulWidget {
  const ChallengePreview({
    super.key,
    required this.definition,
    this.isPilot = false,
  });

  final ChallengeDefinition definition;
  final bool isPilot;

  @override
  ConsumerState<ChallengePreview> createState() => _ChallengePreviewState();
}

class _ChallengePreviewState extends ConsumerState<ChallengePreview> {
  ChallengeDefinition get _definition => widget.definition;
  late final _order = (_definition as ScoredQuestion).presentationOrder(
    Random(),
  );
  late final _arrangementOptions = (_definition as Arrangement)
      .presentationOrder(Random());
  List<String>? _arranged;
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
          Text(widget.isPilot ? draftPilotLabel : previewLabel),
          if (widget.isPilot)
            const Text('تدريب سريع لا يُسجَّل في تقدّم الدرس.'),
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
            final Arrangement question => ArrangementView(
              question: question,
              options: _arrangementOptions,
              answer: _arranged,
              enablePilotEffects: widget.isPilot,
              onAnswer: (answer) {
                if (_arranged != null) return;
                setState(() => _arranged = answer);
                if (widget.isPilot) {
                  ref
                      .read(pilotEffectsProvider)
                      .play(
                        question.evaluate(answer) == true
                            ? PilotEffect.correct
                            : PilotEffect.retry,
                      );
                }
              },
            ),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    ),
  );
}
