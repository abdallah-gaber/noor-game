import 'package:flutter/material.dart';

import '../audio/speech_control.dart';
import 'flashcard.dart';

class FlashcardView extends StatelessWidget {
  const FlashcardView({
    super.key,
    required this.card,
    required this.revealed,
    required this.onReveal,
    required this.onRecall,
    this.recall,
  });

  final Flashcard card;
  final bool revealed;
  final Recall? recall;
  final VoidCallback onReveal;
  final ValueChanged<Recall> onRecall;

  @override
  Widget build(BuildContext context) {
    const instruction = 'فكّر في الإجابة، ثم اكشفها.';
    final result = switch (recall) {
      Recall.remembered => 'أحسنت!',
      Recall.practice => 'يمكنك المراجعة لاحقًا.',
      Recall.skipped => 'أكملتَ البطاقة.',
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(instruction),
        Semantics(
          header: true,
          child: Text(
            card.prompt,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 16),
        if (!revealed)
          FilledButton(onPressed: onReveal, child: const Text('اكشف الإجابة'))
        else ...[
          Semantics(
            liveRegion: true,
            child: Text(
              card.answer,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (result == null)
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => onRecall(Recall.remembered),
                  child: const Text('تذكّرت'),
                ),
                TextButton(
                  onPressed: () => onRecall(Recall.practice),
                  child: const Text('أريد المراجعة'),
                ),
                TextButton(
                  onPressed: () => onRecall(Recall.skipped),
                  child: const Text('متابعة'),
                ),
              ],
            )
          else
            Semantics(liveRegion: true, child: Text(result)),
        ],
        SpeechControl(
          text: revealed
              ? '${card.prompt} ${card.answer}${result == null ? '' : ' $result'}'
              : '$instruction ${card.prompt}',
        ),
      ],
    );
  }
}
