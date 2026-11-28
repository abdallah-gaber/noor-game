import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'arrangement.dart';
import 'challenge_definition.dart';
import 'flashcard.dart';
import 'scored_question.dart';

class GamePlan {
  GamePlan(
    this.contentVersion,
    List<ChallengeDefinition> definitions, {
    this.compatibleDefinitionDigest,
    this.allowAssistedRetries = false,
  }) : definitions = Map.unmodifiable({
         for (final item in definitions) item.id: item,
       }) {
    if (definitions.isEmpty || this.definitions.length != definitions.length) {
      throw const FormatException('Expected unique challenge variant IDs');
    }
    if (allowAssistedRetries &&
        (definitions.length != 1 ||
            definitions.single is! Arrangement ||
            (definitions.single as Arrangement).kind !=
                ArrangementKind.ordering)) {
      throw const FormatException(
        'Assisted retry requires one ordering activity',
      );
    }
  }

  final String contentVersion;
  final String? compatibleDefinitionDigest;
  final bool allowAssistedRetries;
  final Map<String, ChallengeDefinition> definitions;

  late final String compatibility = allowAssistedRetries
      ? jsonEncode([
          3,
          contentVersion,
          (definitions.values.single as Arrangement).toJson(),
        ])
      : compatibleDefinitionDigest != null
      ? jsonEncode([2, contentVersion, compatibleDefinitionDigest])
      : jsonEncode([
          1,
          contentVersion,
          for (final item in definitions.values)
            switch (item) {
              ScoredQuestion question => question.toJson(),
              Arrangement question => question.toJson(),
              Flashcard card => card.toJson(),
              _ => throw const FormatException('Unsupported challenge'),
            },
        ]);
}

class GameAttempt {
  GameAttempt(
    ChallengeDefinition definition,
    List<String> answer,
    this.correct,
    this.review, {
    this.assisted = false,
  }) : variantId = definition.id,
       knowledgeIds = definition.knowledgeIds,
       answer = List.unmodifiable(answer);

  final String variantId;
  final List<String> knowledgeIds;
  final List<String> answer;
  final bool? correct;
  final bool review;
  final bool assisted;

  Map<String, Object?> toJson() => {
    'variantId': variantId,
    'knowledgeIds': knowledgeIds,
    'answer': answer,
    'correct': correct,
    'review': review,
    if (assisted) 'assisted': true,
  };
}

typedef GameScore = ({int scored, int firstCorrect, int eventuallyCorrect});

class GameSession {
  GameSession._(
    this.id,
    this.plan,
    this.optionOrder,
    this.attempts,
    this.cursor,
    this.revision,
  );

  factory GameSession.start(String id, GamePlan plan, Random random) =>
      GameSession._(
        id,
        plan,
        Map.unmodifiable({
          for (final item in plan.definitions.values)
            item.id: List<String>.unmodifiable(
              _shuffledIds(item, plan, random),
            ),
        }),
        const [],
        0,
        0,
      );

  final String id;
  final GamePlan plan;
  final Map<String, List<String>> optionOrder;
  final List<GameAttempt> attempts;
  final int cursor;
  final int revision;

  late final List<String> queue = List.unmodifiable([
    ...plan.definitions.keys,
    if (plan.allowAssistedRetries)
      for (final attempt in attempts)
        if (attempt.correct == false) attempt.variantId,
    if (!plan.allowAssistedRetries &&
        attempts.length >= plan.definitions.length)
      for (final attempt in attempts.take(plan.definitions.length))
        if (attempt.correct == false) attempt.variantId,
  ]);

  bool get finished => cursor == queue.length;

  /// Prior to assistance the player gets two full, unprompted submissions.
  bool get usesAssistance =>
      plan.allowAssistedRetries && !finished && cursor >= 2;

  List<String>? get assistedOrder {
    final definition = current;
    return usesAssistance && definition is Arrangement
        ? definition.correctOrder
        : null;
  }

  ChallengeDefinition? get current =>
      finished ? null : plan.definitions[queue[cursor]];
  GameAttempt? get feedback =>
      cursor < attempts.length ? attempts[cursor] : null;

  GameScore get score {
    final first = attempts.take(plan.definitions.length);
    return (
      scored: first.where((attempt) => attempt.correct != null).length,
      firstCorrect: first.where((attempt) => attempt.correct == true).length,
      eventuallyCorrect: attempts
          .where((attempt) => attempt.correct == true && !attempt.assisted)
          .map((attempt) => attempt.variantId)
          .toSet()
          .length,
    );
  }

  double? get firstAttemptAccuracy {
    final currentScore = score;
    return currentScore.scored == 0
        ? null
        : currentScore.firstCorrect / currentScore.scored;
  }

  List<AnswerOption> optionsFor(ChallengeDefinition item) {
    final options = {for (final option in _options(item)) option.id: option};
    return [for (final id in optionOrder[item.id]!) options[id]!];
  }

  GameSession? submit(List<String> answer) {
    final item = current;
    if (item == null || feedback != null) return null;
    final bool? correct;
    switch (item) {
      case ScoredQuestion question:
        correct = answer.length == 1 ? question.evaluate(answer.single) : null;
        if (correct == null) return null;
      case Arrangement arrangement:
        correct = arrangement.evaluate(answer);
        if (correct == null) return null;
      case Flashcard _:
        if (answer.length != 1 ||
            !Recall.values.any((value) => value.name == answer.single)) {
          return null;
        }
        correct = null;
      default:
        return null;
    }
    final attempt = GameAttempt(
      item,
      answer,
      correct,
      cursor >= plan.definitions.length,
      assisted: usesAssistance,
    );
    return GameSession._(
      id,
      plan,
      optionOrder,
      List.unmodifiable([...attempts, attempt]),
      cursor,
      revision + 1,
    );
  }

  GameSession? advance() => feedback == null
      ? null
      : GameSession._(
          id,
          plan,
          optionOrder,
          attempts,
          cursor + 1,
          revision + 1,
        );

  String encode() => jsonEncode({
    'id': id,
    'orders': optionOrder,
    'attempts': attempts.map((attempt) => attempt.toJson()).toList(),
    'cursor': cursor,
    'revision': revision,
    if (plan.allowAssistedRetries) 'retryUntilCorrect': true,
  });

  static GameSession restore(String payload, GamePlan plan) {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final orders = <String, List<String>>{};
    final stored = data['orders'] as Map<String, dynamic>;
    if (stored.length != plan.definitions.length) {
      throw const FormatException('Invalid saved order');
    }
    for (final item in plan.definitions.values) {
      final order = List<String>.unmodifiable(stored[item.id] as List);
      final choices = _options(item).map((option) => option.id).toSet();
      if (order.length != choices.length ||
          !order.toSet().containsAll(choices)) {
        throw const FormatException('Invalid saved choices');
      }
      orders[item.id] = order;
    }
    var session = GameSession._(
      data['id'] as String,
      plan,
      Map.unmodifiable(orders),
      const [],
      0,
      0,
    );
    for (final raw in data['attempts'] as List) {
      if (session.feedback != null) session = session.advance()!;
      final next = session.current?.id == raw['variantId']
          ? session.submit(List<String>.from(raw['answer'] as List))
          : null;
      if (next == null) throw const FormatException('Invalid saved attempt');
      session = next;
    }
    if (data['cursor'] == session.cursor + 1 && session.feedback != null) {
      session = session.advance()!;
    }
    if (data['cursor'] != session.cursor ||
        data['revision'] != session.revision) {
      throw const FormatException('Invalid session revision');
    }
    return session;
  }

  static List<String> _shuffledIds(
    ChallengeDefinition item,
    GamePlan plan,
    Random random,
  ) {
    final ids = _options(item, random).map((option) => option.id).toList();
    if (plan.allowAssistedRetries &&
        item is Arrangement &&
        ids.indexed.every((entry) => item.correctOrder[entry.$1] == entry.$2)) {
      ids.add(ids.removeAt(0));
    }
    return ids;
  }

  static List<AnswerOption> _options(
    ChallengeDefinition item, [
    Random? random,
  ]) => switch (item) {
    ScoredQuestion question =>
      random == null ? question.options : question.presentationOrder(random),
    Arrangement arrangement =>
      random == null
          ? arrangement.items
          : arrangement.presentationOrder(random),
    _ => const [],
  };
}

String challengeGradingKey(ChallengeDefinition definition) {
  final knowledge = definition.knowledgeIds.toList()..sort();
  final fields = switch (definition) {
    ScoredQuestion question => [
      question.kind.name,
      question.correctOptionId,
      question.options.map((option) => option.id).toList()..sort(),
    ],
    Arrangement question => [
      question.kind.name,
      question.correctOrder,
      question.targets.map((option) => option.id).toList(),
      question.items.map((option) => option.id).toList()..sort(),
    ],
    Flashcard _ => ['flashcard'],
    _ => throw const FormatException('Unsupported mechanic'),
  };
  return sha256
      .convert(utf8.encode(jsonEncode([knowledge, fields])))
      .toString();
}

String reviewGradingKey(List<ChallengeDefinition> items) => jsonEncode([
  for (final item in items) [item.id, challengeGradingKey(item)],
]);
