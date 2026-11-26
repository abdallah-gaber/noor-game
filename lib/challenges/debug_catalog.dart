import 'arrangement.dart';
import 'challenge_definition.dart';
import 'flashcard.dart';
import 'scored_question.dart';

const challengePreviewIds = [
  'shapes-choice',
  'shapes-true-false',
  'shapes-flashcard',
  'shapes-matching',
  'steps-ordering',
];

final debugChallenges = <String, ChallengeDefinition>{
  challengePreviewIds[0]: ScoredQuestion.fromJson({
    'schema': 1,
    'id': challengePreviewIds[0],
    'type': 'multipleChoice',
    'knowledgeIds': ['preview.geometry.triangle'],
    'prompt': 'أيّ شكل له ثلاث زوايا؟',
    'explanation': 'المثلّث له ثلاث زوايا.',
    'correctOptionId': 'triangle',
    'options': [
      {'id': 'circle', 'label': 'دائرة', 'illustration': 'circle'},
      {'id': 'triangle', 'label': 'مثلّث', 'illustration': 'triangle'},
      {'id': 'square', 'label': 'مربّع', 'illustration': 'square'},
    ],
  }),
  challengePreviewIds[1]: ScoredQuestion.fromJson({
    'schema': 1,
    'id': challengePreviewIds[1],
    'type': 'trueFalse',
    'knowledgeIds': ['preview.geometry.square'],
    'prompt': 'للمربّع أربع زوايا.',
    'explanation': 'نعم، للمربّع أربع زوايا.',
    'correctOptionId': 'true',
  }),
  challengePreviewIds[2]: Flashcard.fromJson({
    'schema': 1,
    'type': 'flashcard',
    'id': challengePreviewIds[2],
    'knowledgeIds': ['preview.geometry.circle'],
    'prompt': 'ما اسم الشكل المستدير؟',
    'answer': 'دائرة.',
  }),
  challengePreviewIds[3]: Arrangement.fromJson({
    'schema': 1,
    'type': 'matching',
    'id': challengePreviewIds[3],
    'knowledgeIds': ['preview.geometry.shapes'],
    'prompt': 'صِل الشكل بعدد زواياه.',
    'explanation': 'للمثلّث ثلاث زوايا، وللمربّع أربع زوايا.',
    'pairs': [
      {
        'left': {'id': 'triangle', 'label': 'مثلّث'},
        'right': {'id': 'three', 'label': 'ثلاث زوايا'},
      },
      {
        'left': {'id': 'square', 'label': 'مربّع'},
        'right': {'id': 'four', 'label': 'أربع زوايا'},
      },
    ],
  }),
  challengePreviewIds[4]: Arrangement.fromJson({
    'schema': 1,
    'type': 'ordering',
    'id': challengePreviewIds[4],
    'knowledgeIds': ['preview.counting'],
    'prompt': 'رتّب الأعداد من الأصغر إلى الأكبر.',
    'explanation': 'الترتيب هو: واحد، اثنان، ثلاثة.',
    'items': [
      {'id': 'one', 'label': 'واحد'},
      {'id': 'two', 'label': 'اثنان'},
      {'id': 'three', 'label': 'ثلاثة'},
    ],
    'correctOrder': ['one', 'two', 'three'],
  }),
};
