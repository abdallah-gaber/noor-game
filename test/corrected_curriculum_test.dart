import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor/challenges/scored_question.dart';
import 'package:noor/content/packs/catalog.dart';
import 'package:noor/content/packs/pack_document.dart';

void main() {
  final path = Platform.environment['NOOR_CORRECTED_REVIEW_BUNDLE'];
  test('validate corrected local variant definitions through Dart pack v1', () {
    final bundle =
        jsonDecode(File(path!).readAsStringSync()) as Map<String, Object?>;
    final variants = bundle['variantDefinitions'] as Map<String, Object?>;
    final knowledgeIds = <String>{};
    final variantRecords = <Map<String, Object?>>[];
    for (final entry in variants.entries) {
      final draft = entry.value as Map<String, Object?>;
      final ids = (draft['knowledgeIds'] as List).cast<String>();
      knowledgeIds.addAll(ids);
      final definition = Map<String, Object?>.of(draft)
        ..remove('schema')
        ..remove('id')
        ..remove('knowledgeIds')
        ..remove('sourceRefs')
        ..remove('sourceRefsByKnowledge');
      if (definition['type'] == 'trueFalse') {
        // Exercise the authored labels and IDs before using v1's fixed boolean
        // presentation in this probe. The corrected draft keeps its own IDs.
        final authored = ScoredQuestion.fromDraftTrueFalse(draft);
        final answer = authored.options.singleWhere(
          (item) => item.id == authored.correctOptionId,
        );
        definition
          ..remove('options')
          ..['correctOptionId'] = answer.label == 'صحيح' ? 'true' : 'false';
      }
      variantRecords.add({
        'id': entry.key,
        'kind': 'variant',
        'reviewStatus': 'draft',
        'revision': 'probe',
        'difficulty': 'recognition',
        'knowledgeIds': ids,
        'sourceRefs': ['probe.source'],
        'definition': definition,
      });
    }
    // The Python handoff checks the actual scoped reference graph. This
    // synthetic source and text exercise the v1 mechanics only.
    final pack = PackDocument.decode(
      jsonEncode({
        'schema': 1,
        'packId': 'probe.corrected-draft',
        'version': '0.0.1',
        'channel': 'draft',
        'records': [
          {
            'id': 'probe.source',
            'kind': 'source',
            'reviewStatus': 'draft',
            'title': 'Test placeholder',
            'locator': 'Test placeholder',
            'category': 'other',
          },
          for (final id in knowledgeIds)
            {
              'id': id,
              'kind': 'knowledge',
              'reviewStatus': 'draft',
              'title': 'Test placeholder',
              'text': 'Test placeholder',
              'revision': 'probe',
              'sourceRefs': ['probe.source'],
            },
          ...variantRecords,
        ],
      }),
    );
    const ingestor = CatalogIngestor();
    final validated = ingestor.validate([pack]);
    expect(validated.variants.keys, unorderedEquals(variants.keys));
    expect(validated.variants, hasLength(636));
    expect(
      () => ingestor.activate(
        [pack],
        approvals: ApprovalLedger.decodeTrusted('{"schema":1,"approvals":[]}'),
      ),
      throwsFormatException,
    );
  }, skip: path == null ? 'Private CONTENT-008 bundle is local only.' : false);
}
