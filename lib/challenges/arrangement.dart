import 'dart:math';

import 'challenge_definition.dart';
import 'scored_question.dart';

enum ArrangementKind { matching, ordering }

class Arrangement implements ChallengeDefinition {
  Arrangement._({
    required this.identity,
    required this.kind,
    required this.prompt,
    required this.explanation,
    required this.items,
    required this.targets,
    required this.correctOrder,
  });

  final ChallengeIdentity identity;
  final ArrangementKind kind;
  @override
  final String prompt;
  final String explanation;

  /// Right-hand candidates for matching, or the items to order.
  final List<AnswerOption> items;
  final List<AnswerOption> targets;

  /// Matching answers follow the canonical target order.
  final List<String> correctOrder;

  @override
  String get id => identity.id;
  @override
  List<String> get knowledgeIds => identity.knowledgeIds;
  @override
  bool get isScored => true;

  factory Arrangement.fromJson(Map<String, Object?> json) {
    final identity = ChallengeIdentity.fromJson(json);
    final kind = switch (json['type']) {
      'matching' => ArrangementKind.matching,
      'ordering' => ArrangementKind.ordering,
      _ => throw const FormatException('Unsupported arrangement'),
    };
    final targets = <AnswerOption>[];
    final items = <AnswerOption>[];
    final solution = <String>[];
    if (kind == ArrangementKind.matching) {
      for (final entry in _entries(json['pairs'], 4)) {
        if (entry is! Map<String, Object?>) {
          throw const FormatException('Expected pair');
        }
        targets.add(AnswerOption.fromJson(entry['left']));
        items.add(AnswerOption.fromJson(entry['right']));
      }
      solution.addAll(items.map((item) => item.id));
    } else {
      items.addAll(_entries(json['items'], 5).map(AnswerOption.fromJson));
      solution.addAll(_entries(json['correctOrder'], 5).map(challengeId));
    }
    validateOptions(targets);
    validateOptions(items);
    if (!_permutation(solution, items)) {
      throw const FormatException('Expected every answer ID once');
    }
    return Arrangement._(
      identity: identity,
      kind: kind,
      prompt: challengeText(json['prompt']),
      explanation: challengeText(json['explanation']),
      items: List.unmodifiable(items),
      targets: List.unmodifiable(targets),
      correctOrder: List.unmodifiable(solution),
    );
  }

  static List<Object?> _entries(Object? value, int maximum) {
    if (value is! List<Object?> || value.length < 2 || value.length > maximum) {
      throw FormatException('Expected two to $maximum items');
    }
    return value;
  }

  static bool _permutation(List<String> order, List<AnswerOption> items) =>
      order.length == items.length &&
      order.toSet().length == items.length &&
      items.every((item) => order.contains(item.id));

  bool? evaluate(List<String> answer) {
    if (!_permutation(answer, items)) return null;
    return answer.indexed.every((entry) => entry.$2 == correctOrder[entry.$1]);
  }

  List<AnswerOption> presentationOrder(Random random) =>
      List.unmodifiable([...items]..shuffle(random));

  Map<String, Object> toJson() => {
    'schema': 1,
    'type': kind.name,
    'id': id,
    'knowledgeIds': knowledgeIds,
    'prompt': prompt,
    'explanation': explanation,
    if (kind == ArrangementKind.matching)
      'pairs': [
        for (final (index, target) in targets.indexed)
          {'left': target.toJson(), 'right': items[index].toJson()},
      ]
    else ...{
      'items': items.map((item) => item.toJson()).toList(),
      'correctOrder': correctOrder,
    },
  };
}
