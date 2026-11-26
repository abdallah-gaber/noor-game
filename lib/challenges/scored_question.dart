import 'dart:math';

enum QuestionKind { multipleChoice, trueFalse }

class AnswerOption {
  const AnswerOption(this.id, this.label, {this.illustration});

  final String id;
  final String label;
  final String? illustration;

  Map<String, Object> toJson() => {
    'id': id,
    'label': label,
    'illustration': ?illustration,
  };
}

class ScoredQuestion {
  ScoredQuestion._({
    required this.id,
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

  final String id;
  final QuestionKind kind;
  final String prompt;
  final String explanation;
  final List<AnswerOption> options;
  final String correctOptionId;

  factory ScoredQuestion.fromJson(Map<String, Object?> json) {
    if (json['schema'] is! int || json['schema'] != schema) {
      throw const FormatException('Unsupported question schema');
    }
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
      options = List.unmodifiable(
        entries.map((entry) {
          if (entry is! Map<String, Object?>) {
            throw const FormatException('Expected an option object');
          }
          return AnswerOption(
            _id(entry['id']),
            _text(entry['label']),
            illustration: entry.containsKey('illustration')
                ? _id(entry['illustration'])
                : null,
          );
        }),
      );
    }
    final ids = options.map((option) => option.id).toSet();
    final correctId = _id(json['correctOptionId']);
    if (ids.length != options.length || !ids.contains(correctId)) {
      throw const FormatException('Duplicate option or invalid correct answer');
    }
    return ScoredQuestion._(
      id: _id(json['id']),
      kind: kind,
      prompt: _text(json['prompt']),
      explanation: _text(json['explanation']),
      options: options,
      correctOptionId: correctId,
    );
  }

  Map<String, Object> toJson() => {
    'schema': schema,
    'id': id,
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

  static String _text(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Expected non-empty text');
    }
    return value.trim();
  }

  static String _id(Object? value) {
    final id = _text(value);
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]*$').hasMatch(id)) {
      throw const FormatException('Invalid stable identifier');
    }
    return id;
  }
}
