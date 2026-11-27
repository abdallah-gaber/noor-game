import 'dart:convert';

import '../challenges/arrangement.dart';
import '../challenges/challenge_definition.dart';
import '../challenges/flashcard.dart';
import '../challenges/scored_question.dart';
import 'curriculum.dart';

/// Reads the local debug projection, separate from production pack activation.
Curriculum decodeDraftPilot(String input) {
  final decoded = jsonDecode(input);
  if (decoded is! Map<String, Object?> || decoded['schema'] != 1) {
    throw const FormatException('Unsupported draft pilot schema');
  }
  final worlds = <WorldId, List<LearningUnit>>{};
  for (final record in _records(decoded['lessons'])) {
    final world = WorldId.fromId(record['worldId'] as String?);
    if (world == null || worlds.containsKey(world)) {
      throw const FormatException('Expected one pilot lesson per world');
    }
    final title = challengeText(record['title']);
    final knowledge = _records(record['knowledge']);
    final sources = {
      for (final source in _records(record['sources']))
        challengeText(source['id']): (
          id: challengeText(source['id']),
          title: source['title'] as String? ?? '',
          locator: source['locator'] as String? ?? '',
          url: source['url'] as String?,
        ),
    };
    final variants = _records(record['variants']);
    for (final entry in [...knowledge, ...variants]) {
      final refs = entry['sourceRefs'];
      if (refs is! List || refs.isEmpty || !refs.every(sources.containsKey)) {
        throw const FormatException('Unresolved draft source references');
      }
    }
    final knowledgeIds = knowledge
        .map((entry) => challengeId(entry['id']))
        .toSet();
    final challenges = variants.map(_decodeVariant).toList(growable: false);
    if (knowledge.isEmpty ||
        knowledgeIds.length != knowledge.length ||
        challenges.isEmpty ||
        challenges.map((variant) => variant.id).toSet().length !=
            challenges.length ||
        challenges.any(
          (variant) => !variant.knowledgeIds.every(knowledgeIds.contains),
        )) {
      throw const FormatException('Invalid pilot lesson references');
    }
    worlds[world] = [
      LearningUnit(
        id: challengeId(record['unitId']),
        world: world,
        title: title,
        lessons: [
          LearningLesson(
            id: challengeId(record['id']),
            title: title,
            steps: List.unmodifiable([
              for (final entry in knowledge)
                LessonStep(
                  title,
                  challengeText(entry['textAr']),
                  LessonPicture.trail,
                ),
              if (record.containsKey('activity'))
                LessonStep(
                  'نشاط مع أحد الوالدين',
                  challengeText(record['activity']),
                  LessonPicture.trail,
                ),
            ]),
            challenges: List.unmodifiable(challenges),
            knowledgeLabels: Map.unmodifiable({
              for (final entry in knowledge)
                challengeId(entry['id']): challengeText(entry['textAr']),
            }),
            sources: List.unmodifiable(sources.values),
          ),
        ],
      ),
    ];
  }
  if (worlds.length != WorldId.values.length) {
    throw const FormatException('Expected all four pilot worlds');
  }
  return Curriculum(
    version: 'draft-pilot-1',
    isPreview: true,
    isDraftPilot: true,
    units: Map.unmodifiable(worlds),
  );
}

List<Map<String, Object?>> _records(Object? value) {
  if (value is List && value.every((entry) => entry is Map<String, Object?>)) {
    return value.cast<Map<String, Object?>>();
  }
  throw const FormatException('Expected pilot records');
}

ChallengeDefinition _decodeVariant(Map<String, Object?> record) =>
    switch (record['type']) {
      'multipleChoice' => ScoredQuestion.fromJson(record),
      'trueFalse' => ScoredQuestion.fromDraftTrueFalse(record),
      'flashcard' => Flashcard.fromJson(record),
      'matching' || 'ordering' => Arrangement.fromJson(record),
      _ => throw const FormatException('Unsupported pilot mechanic'),
    };
