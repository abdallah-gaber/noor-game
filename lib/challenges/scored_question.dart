import 'dart:math';

import 'challenge_definition.dart';

enum QuestionKind { multipleChoice, trueFalse }

class AnswerOption {
  const AnswerOption(this.id, this.label, {this.illustration});

  factory AnswerOption.fromJson(Object? input) {
    if (input is! Map<String, Object?>) {
      throw const FormatException('Expected an option object');
    }
    return AnswerOption(
      challengeId(input['id']),
      challengeText(input['label']),
      illustration: input.containsKey('illustration')
          ? challengeId(input['illustration'])
          : null,
    );
  }

  final String id;
  final String label;
  final String? illustration;

  Map<String, Object> toJson() => {
    'id': id,
    'label': label,
    'illustration': ?illustration,
  };
}

class ScoredQuestion implements ChallengeDefinition {
  ScoredQuestion._({
    required this.identity,
    required this.kind,
    required this.prompt,
    required this.explanation,
    required this.options,
    required this.correctOptionId,
  });

  static const schema = 1;
  static const _booleanOptions = [
    AnswerOption('true', 'صح'),
    AnswerOption('false', 'خطأ'),
  ];

  final ChallengeIdentity identity;
  @override
  String get id => identity.id;
  @override
  List<String> get knowledgeIds => identity.knowledgeIds;
  @override
  bool get isScored => true;

  final QuestionKind kind;
  @override
  final String prompt;
  final String explanation;
  final List<AnswerOption> options;
  final String correctOptionId;

  factory ScoredQuestion.fromJson(Map<String, Object?> json) {
    final identity = ChallengeIdentity.fromJson(json);
    final kind = switch (json['type']) {
      'multipleChoice' => QuestionKind.multipleChoice,
      'trueFalse' => QuestionKind.trueFalse,
      _ => throw const FormatException('Unsupported question type'),
    };
    final List<AnswerOption> options;
    if (kind == QuestionKind.trueFalse) {
      if (json.containsKey('options')) {
        throw const FormatException('True/false uses the fixed options');
      }
      options = _booleanOptions;
    } else {
      final entries = json['options'];
      if (entries is! List || entries.length < 2 || entries.length > 4) {
        throw const FormatException('Expected two to four choices');
      }
      options = List.unmodifiable(entries.map(AnswerOption.fromJson));
    }
    validateOptions(options);
    final correctId = challengeId(json['correctOptionId']);
    if (!options.any((option) => option.id == correctId)) {
      throw const FormatException('Invalid correct answer');
    }
    return ScoredQuestion._(
      identity: identity,
      kind: kind,
      prompt: challengeText(json['prompt']),
      explanation: challengeText(json['explanation']),
      options: options,
      correctOptionId: correctId,
    );
  }

  Map<String, Object> toJson() => {
    'schema': schema,
    'id': id,
    'knowledgeIds': knowledgeIds,
    'type': kind.name,
    'prompt': prompt,
    'explanation': explanation,
    'correctOptionId': correctOptionId,
    if (kind == QuestionKind.multipleChoice)
      'options': [for (final option in options) option.toJson()],
  };

  List<AnswerOption> presentationOrder(Random random) =>
      kind == QuestionKind.trueFalse
      ? options
      : List.unmodifiable([...options]..shuffle(random));

  bool? evaluate(String optionId) {
    if (!options.any((option) => option.id == optionId)) return null;
    return optionId == correctOptionId;
  }
}

void validateOptions(List<AnswerOption> options) {
  if (options.map((option) => option.id).toSet().length != options.length) {
    throw const FormatException('Duplicate option ID');
  }
  if (options.map((option) => visibleLabel(option.label)).toSet().length !=
      options.length) {
    throw const FormatException('Duplicate visible answer label');
  }
}
