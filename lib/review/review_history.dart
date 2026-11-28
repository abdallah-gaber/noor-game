import 'dart:collection';
import 'dart:convert';

const reviewHistoryPrefix = '@review/';

typedef PracticeResult = ({
  int scored,
  int firstCorrect,
  int recentScored,
  int recentCorrect,
  int eventuallyCorrect,
  int consecutiveCorrect,
  DateTime? lastPracticed,
});

typedef PracticeActivity = ({
  String lessonId,
  bool review,
  DateTime? practicedAt,
});

class ReviewHistory {
  final _knowledge = <String, _KnowledgeHistory>{};
  final _latestByLesson = <String, PracticeActivity>{};
  final _latestVariant = <String, bool>{};
  final _lastSeen = <String, int>{};
  var _ordinal = 0;

  int variantRecency(String id) => _lastSeen[id] ?? 0;

  bool missed(String variantId) => _latestVariant[variantId] == false;

  PracticeResult? knowledge(String id) => _knowledge[id]?.result;

  Iterable<PracticeActivity> get recent =>
      _latestByLesson.values.toList().reversed;

  void include(String key, String payload, DateTime? practicedAt) {
    final round = jsonDecode(payload) as Map<String, dynamic>;
    final attempts = (round['attempts'] as List).cast<Map<String, dynamic>>();
    if (attempts.isEmpty) return;
    _latestByLesson.remove(key);
    _latestByLesson[key] = (
      lessonId: key,
      review: key.startsWith(reviewHistoryPrefix),
      practicedAt: practicedAt,
    );
    for (final attempt in attempts) {
      final variant = attempt['variantId'] as String;
      final firstPass = attempt['review'] == false;
      if (firstPass) _lastSeen[variant] = ++_ordinal;
      final correct = attempt['correct'];
      if (correct is! bool || attempt['assisted'] == true) continue;
      if (firstPass) _latestVariant[variant] = correct;
      for (final id in (attempt['knowledgeIds'] as List).cast<String>()) {
        _knowledge
            .putIfAbsent(id, _KnowledgeHistory.new)
            .include(variant, correct, firstPass, practicedAt);
      }
    }
  }
}

class _KnowledgeHistory {
  final first = <String, bool>{};
  final eventual = <String>{};
  final recent = Queue<bool>();
  int consecutive = 0;
  DateTime? last;

  void include(
    String variant,
    bool correct,
    bool firstPass,
    DateTime? practicedAt,
  ) {
    if (correct) eventual.add(variant);
    if (!firstPass) return;
    first.putIfAbsent(variant, () => correct);
    recent.add(correct);
    if (recent.length > 5) recent.removeFirst();
    if (!correct) {
      consecutive = 0;
    } else if (practicedAt != null &&
        (last == null || !_sameDay(last!, practicedAt))) {
      consecutive++;
    }
    if (practicedAt != null) last = practicedAt;
  }

  PracticeResult get result => (
    scored: first.length,
    firstCorrect: first.values.where((correct) => correct).length,
    recentScored: recent.length,
    recentCorrect: recent.where((correct) => correct).length,
    eventuallyCorrect: eventual.length,
    consecutiveCorrect: consecutive,
    lastPracticed: last,
  );
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
