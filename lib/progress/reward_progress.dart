import 'dart:convert';
import 'dart:math';

typedef KnowledgePractice = ({
  int scored,
  int firstCorrect,
  int eventuallyCorrect,
});
typedef _VariantPractice = ({bool firstCorrect, bool eventuallyCorrect});

class RewardProgress {
  const RewardProgress({
    this.starsByLesson = const {},
    this.knowledge = const {},
  });

  final Map<String, int> starsByLesson;
  final Map<String, KnowledgePractice> knowledge;

  int get xp => starsByLesson.length * 10;
  int get stars => starsByLesson.values.fold(0, (sum, stars) => sum + stars);
}

/// Reads completed game snapshots in insertion order, independent of the
/// currently installed lesson revisions and answer definitions.
class RewardHistory {
  final _stars = <String, int>{};
  final _knowledge = <String, Map<String, _VariantPractice>>{};

  void include(String lessonId, String payload) {
    final snapshot = jsonDecode(payload) as Map<String, dynamic>;
    final attempts = (snapshot['attempts'] as List)
        .cast<Map<String, dynamic>>();
    final required = (snapshot['orders'] as Map).length;
    final first = attempts.take(required);
    final retrySources = snapshot['retryUntilCorrect'] == true
        ? attempts
        : first;
    final retries = retrySources
        .where((attempt) => attempt['correct'] == false)
        .length;
    final fullLength = required + retries;
    if (required == 0 ||
        snapshot['cursor'] != fullLength ||
        attempts.length != fullLength) {
      return;
    }

    final scored = first.where((attempt) => attempt['correct'] is bool).length;
    if (scored == 0) return;
    final correct = first.where((attempt) => attempt['correct'] == true).length;
    final stars = correct == scored
        ? 3
        : correct * 2 >= scored
        ? 2
        : 1;
    _stars.update(
      lessonId,
      (previous) => max(previous, stars),
      ifAbsent: () => stars,
    );

    for (final attempt in attempts) {
      final correct = attempt['correct'];
      if (correct is! bool || attempt['assisted'] == true) continue;
      final variantId = attempt['variantId'] as String;
      for (final knowledgeId
          in (attempt['knowledgeIds'] as List).cast<String>()) {
        final variants = _knowledge.putIfAbsent(knowledgeId, () => {});
        variants.update(
          variantId,
          (previous) => (
            firstCorrect: previous.firstCorrect,
            eventuallyCorrect: previous.eventuallyCorrect || correct,
          ),
          ifAbsent: () => (firstCorrect: correct, eventuallyCorrect: correct),
        );
      }
    }
  }

  RewardProgress summarize() => RewardProgress(
    starsByLesson: Map.unmodifiable(_stars),
    knowledge: Map.unmodifiable({
      for (final entry in _knowledge.entries)
        entry.key: (
          scored: entry.value.length,
          firstCorrect: entry.value.values
              .where((variant) => variant.firstCorrect)
              .length,
          eventuallyCorrect: entry.value.values
              .where((variant) => variant.eventuallyCorrect)
              .length,
        ),
    }),
  );
}
