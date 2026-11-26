import 'package:flutter/material.dart';

import '../audio/speech_control.dart';
import 'arrangement.dart';
import 'question_view.dart';
import 'scored_question.dart';

class ArrangementView extends StatefulWidget {
  const ArrangementView({
    super.key,
    required this.question,
    required this.options,
    required this.onAnswer,
    this.answer,
    this.enabled = true,
  });

  final Arrangement question;
  final List<AnswerOption> options;
  final List<String>? answer;
  final bool enabled;
  final ValueChanged<List<String>> onAnswer;

  @override
  State<ArrangementView> createState() => _ArrangementViewState();
}

class _ArrangementViewState extends State<ArrangementView> {
  final _pairs = <String, String>{};
  final _sequence = <String>[];
  String? _target;

  bool get _matching => widget.question.kind == ArrangementKind.matching;
  bool get _editable => widget.enabled && widget.answer == null;

  void _select(String id) {
    if (_matching && _target == null) return;
    setState(() {
      if (_matching) {
        _pairs.removeWhere((key, value) => value == id);
        _pairs[_target!] = id;
        _target = null;
      } else if (!_sequence.remove(id)) {
        _sequence.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final answer = widget.answer;
    final feedback = answer == null ? null : question.evaluate(answer);
    final arranged = _matching
        ? [for (final target in question.targets) ?_pairs[target.id]]
        : _sequence;
    final labels = {
      for (final option in widget.options) option.id: option.label,
    };
    final instruction = _matching
        ? 'اختر عنصرًا ثم اختر ما يناسبه.'
        : 'اضغط على العناصر بالترتيب. اضغط مجددًا لإزالة عنصر.';
    final passage = [
      instruction,
      question.prompt,
      ...question.targets.map((item) => item.label),
      ...widget.options.map((item) => item.label),
      if (feedback != null) question.explanation,
    ].join(' ');

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
        const SizedBox(height: 12),
        if (_matching) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (index, target) in question.targets.indexed)
                _button(
                  target.label,
                  note:
                      labels[answer == null
                          ? _pairs[target.id]
                          : answer[index]],
                  selected: _target == target.id,
                  onTap: _editable
                      ? () => setState(() => _target = target.id)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final candidate in widget.options)
              _button(
                candidate.label,
                note: !_matching && (answer ?? _sequence).contains(candidate.id)
                    ? '${(answer ?? _sequence).indexOf(candidate.id) + 1}'
                    : null,
                selected:
                    (_matching ? (answer ?? arranged) : (answer ?? _sequence))
                        .contains(candidate.id),
                onTap: _editable && (!_matching || _target != null)
                    ? () => _select(candidate.id)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (feedback != null)
          AnswerFeedback(correct: feedback, explanation: question.explanation)
        else
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _editable && arranged.length == question.items.length
                    ? () => widget.onAnswer(List.of(arranged))
                    : null,
                child: const Text('تحقّق'),
              ),
              TextButton(
                onPressed: _editable && (arranged.isNotEmpty || _target != null)
                    ? () => setState(() {
                        _pairs.clear();
                        _sequence.clear();
                        _target = null;
                      })
                    : null,
                child: const Text('ابدأ من جديد'),
              ),
            ],
          ),
        SpeechControl(text: passage),
      ],
    );
  }

  Widget _button(
    String label, {
    String? note,
    required bool selected,
    required VoidCallback? onTap,
  }) => Semantics(
    selected: selected,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(minimumSize: const Size(56, 52)),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, textAlign: TextAlign.center),
          if (note != null) Text(note),
        ],
      ),
    ),
  );
}
