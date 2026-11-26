import 'package:flutter/material.dart';

import '../audio/speech_control.dart';
import '../design_system/noor_theme.dart';
import '../home/noor_lantern.dart';
import 'scored_question.dart';

class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.options,
    required this.selectedId,
    required this.onAnswer,
  });

  final ScoredQuestion question;
  final List<AnswerOption> options;
  final String? selectedId;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final selected = selectedId;
    final correct = selected == null ? null : question.evaluate(selected);
    final instruction = question.kind == QuestionKind.trueFalse
        ? 'اختر صح أو خطأ'
        : 'اختر إجابة واحدة';
    final passage = [
      instruction,
      question.prompt,
      ...options.map((option) => option.label),
    ].join('. ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(instruction),
        Semantics(
          header: true,
          child: Text(
            question.prompt,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final width = constraints.maxWidth >= 480
                ? (constraints.maxWidth - gap) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final option in options)
                  SizedBox(
                    width: width,
                    child: _AnswerCard(
                      option: option,
                      selected: selected == option.id,
                      enabled: selected == null,
                      onTap: () => onAnswer(option.id),
                    ),
                  ),
              ],
            );
          },
        ),
        if (correct != null)
          AnswerFeedback(correct: correct, explanation: question.explanation),
        SpeechControl(
          text: correct == null
              ? passage
              : '${question.prompt} ${question.explanation}',
        ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AnswerOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (option.illustration) {
      'circle' => Icons.circle_outlined,
      'triangle' => Icons.change_history_rounded,
      'square' => Icons.square_outlined,
      _ => null,
    };
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 60),
          disabledForegroundColor: ink,
          disabledBackgroundColor: selected ? sage : paper,
          foregroundColor: ink,
          backgroundColor: paper,
          side: BorderSide(
            color: selected ? ink : outline,
            width: selected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
            Flexible(child: Text(option.label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

class AnswerFeedback extends StatelessWidget {
  const AnswerFeedback({
    super.key,
    required this.correct,
    required this.explanation,
  });

  final bool correct;
  final String explanation;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          NoorLantern(
            mood: correct ? NoorMood.celebrating : NoorMood.encouraging,
            size: 76,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct
                      ? 'أحسنت! إجابة صحيحة'
                      : 'إجابة غير صحيحة. لنتعلّم معًا.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(explanation),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
