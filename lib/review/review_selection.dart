import 'dart:math';

import '../challenges/arrangement.dart';
import '../challenges/challenge_definition.dart';
import '../challenges/game_session.dart';
import '../challenges/scored_question.dart';
import '../content/curriculum.dart';
import '../progress/lesson_progress.dart';
import 'review_history.dart';

const spacingDays = [1, 3, 7, 14];

enum ReviewMode { adaptive, daily }

String dailyReviewKey(DateTime date) =>
    '${reviewHistoryPrefix}daily/${date.year}-${date.month}-${date.day}';

typedef ReviewCandidate = ({String lessonId, ChallengeDefinition challenge});

List<ReviewCandidate> reviewCandidates(
  Curriculum curriculum,
  JourneyProgress progress,
) {
  final completed = progress.completedIn(curriculum);
  return [
    for (final world in curriculum.units.values)
      for (final unit in world)
        for (final lesson in unit.lessons)
          if (lesson.state(completed: completed) != LessonState.locked)
            for (final challenge in lesson.challenges)
              (lessonId: lesson.id, challenge: challenge),
  ];
}

DateTime? nextPractice(PracticeResult? result, List<int> intervals) {
  final last = result?.lastPracticed;
  if (last == null) return null;
  final index = (result!.consecutiveCorrect - 1).clamp(0, intervals.length - 1);
  return DateTime(last.year, last.month, last.day + intervals[index]);
}

int reviewPriority(PracticeResult? result, DateTime now, List<int> intervals) {
  if (result == null) return 2;
  final due = nextPractice(result, intervals);
  if (result.recentCorrect * 2 < result.recentScored) return 0;
  if (due == null || !due.isAfter(now)) return 1;
  return 3;
}

List<ChallengeDefinition> selectReview(
  List<ReviewCandidate> pool,
  ReviewHistory history,
  List<int> intervals,
  DateTime now, {
  int maximum = 5,
}) {
  final ranked = [
    for (final (:challenge, lessonId: _) in pool)
      (
        item: challenge,
        prompt: visibleLabel(challenge.prompt),
        type: switch (challenge) {
          ScoredQuestion question => question.kind,
          Arrangement arrangement => arrangement.kind,
          _ => challenge.runtimeType,
        },
        priority: history.missed(challenge.id)
            ? -1
            : challenge.knowledgeIds
                  .map(
                    (id) =>
                        reviewPriority(history.knowledge(id), now, intervals),
                  )
                  .reduce(min),
      ),
  ];
  final chosen = <ChallengeDefinition>[];
  final prompts = <String>{};
  final ids = <String>{};
  final types = <Object>{};
  while (chosen.length < maximum && ranked.isNotEmpty) {
    ranked.sort((a, b) {
      final aRank = a.priority * 2 + (types.contains(a.type) ? 1 : 0);
      final bRank = b.priority * 2 + (types.contains(b.type) ? 1 : 0);
      final priority = aRank.compareTo(bRank);
      if (priority != 0) return priority;
      final recent = history
          .variantRecency(a.item.id)
          .compareTo(history.variantRecency(b.item.id));
      return recent != 0 ? recent : a.item.id.compareTo(b.item.id);
    });
    final picked = ranked.removeAt(0);
    if (!ids.add(picked.item.id) || !prompts.add(picked.prompt)) continue;
    types.add(picked.type);
    chosen.add(picked.item);
  }
  return chosen;
}

GamePlan reviewPlan(List<ChallengeDefinition> items) => GamePlan(
  'review-v1',
  items,
  compatibleDefinitionDigest: reviewGradingKey(items),
);
