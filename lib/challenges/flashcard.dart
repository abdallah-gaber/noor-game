import 'challenge_definition.dart';

class Flashcard implements ChallengeDefinition {
  Flashcard.fromJson(Map<String, Object?> json)
    : identity = ChallengeIdentity.fromJson(json),
      prompt = challengeText(json['prompt']),
      answer = challengeText(json['answer']) {
    if (json['type'] != 'flashcard' || json.containsKey('correctOptionId')) {
      throw const FormatException('Expected an unscored flashcard');
    }
  }

  final ChallengeIdentity identity;
  @override
  String get id => identity.id;
  @override
  List<String> get knowledgeIds => identity.knowledgeIds;
  @override
  final String prompt;
  final String answer;
  @override
  bool get isScored => false;

  Map<String, Object> toJson() => {
    'schema': 1,
    'type': 'flashcard',
    'id': id,
    'knowledgeIds': knowledgeIds,
    'prompt': prompt,
    'answer': answer,
  };
}

enum Recall { remembered, practice, skipped }
