abstract interface class ChallengeDefinition {
  String get id;
  List<String> get knowledgeIds;
  String get prompt;
  bool get isScored;
}

class ChallengeIdentity {
  ChallengeIdentity.fromJson(Map<String, Object?> json)
    : id = challengeId(json['id']),
      knowledgeIds = _knowledgeIds(json['knowledgeIds']) {
    if (json['schema'] != 1 || json['schema'] is! int) {
      throw const FormatException('Unsupported challenge schema');
    }
  }

  final String id;
  final List<String> knowledgeIds;

  static List<String> _knowledgeIds(Object? input) {
    if (input is! List || input.isEmpty) {
      throw const FormatException('Expected linked knowledge IDs');
    }
    final ids = List<String>.unmodifiable(input.map(challengeId));
    if (ids.toSet().length != ids.length) {
      throw const FormatException('Duplicate knowledge ID');
    }
    return ids;
  }
}

String challengeText(Object? value) {
  if (value is! String || visibleLabel(value).isEmpty) {
    throw const FormatException('Expected non-empty text');
  }
  return value.trim();
}

String challengeId(Object? value) {
  final id = challengeText(value);
  if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(id)) {
    throw const FormatException('Invalid stable identifier');
  }
  return id;
}

String visibleLabel(String label) => label
    .replaceAll(RegExp(r'[\u061c\u200b-\u200f\u202a-\u202e\u2060-\u2069]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
