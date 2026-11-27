import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/challenges/arrangement.dart';
import 'package:noor/challenges/game_session.dart';
import 'package:noor/challenges/scored_question.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/content/packs/bundled_catalog.dart';
import 'package:noor/content/packs/catalog.dart';
import 'package:noor/content/packs/pack_document.dart';
import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';

import 'progress_test_support.dart';

const _ingestor = CatalogIngestor();
const _prefix = 'docs/curriculum/examples';
const _circle = 'assets/curriculum/media/circle.svg';
const _learn = 'example.lesson.shapes';
const _follow = 'example.lesson.follow';
const _choice = 'example.variant.choice';

void main() {
  test('synthetic drafts validate structurally and cover all types without approval', () {
    final packs = _examples();
    final validated = _ingestor.validate(packs);
    final empty = ApprovalLedger.decodeTrusted(
      File('$_prefix/approvals.example.json').readAsStringSync(),
    );
    expect(
      validated.records.values.map((record) => record.kind).toSet(),
      RecordKind.values.toSet(),
    );
    expect(
      validated.variants.values.where((variant) => variant.isScored),
      hasLength(4),
    );
    expect(validated.variants[_choice]?.knowledgeIds, [
      'example.knowledge.shapes',
    ]);
    expect(validated.lifecycle(_learn, empty), (
      draft: true,
      sourceVerified: false,
      humanApproved: false,
      validated: true,
      integrated: false,
    ));
    expect(
      () => _ingestor.activate(
        packs,
        approvals: _ledger(packs),
        assetDigests: _digests(),
      ),
      throwsFormatException,
    );
  });

  test(
    'exact trusted record approvals and local media are required independently',
    () {
      final packs = _examples(production: true);
      final validated = _ingestor.validate(packs);
      final all = _ledger(packs);
      expect(validated.lifecycle(_learn, all), (
        draft: false,
        sourceVerified: true,
        humanApproved: true,
        validated: true,
        integrated: false,
      ));
      for (final omit in [
        _learn,
        'example.source.math',
        'example.treasure.shapes',
        'example.release.geometry',
      ]) {
        expect(
          () => _ingestor.activate(
            packs,
            approvals: _ledger(packs, omit: omit),
            assetDigests: _digests(),
          ),
          throwsFormatException,
        );
      }
      expect(
        () => _ingestor.activate(packs, approvals: all),
        throwsFormatException,
      );
      expect(
        () => _ingestor.activate(
          packs,
          approvals: all,
          assetDigests: {_circle: 'bad'},
        ),
        throwsFormatException,
      );
      final catalog = _ingestor.activate(
        packs,
        approvals: all,
        assetDigests: _digests(),
      );
      expect(catalog.lifecycle(_learn).integrated, isTrue);
      expect(catalog.paths.map((path) => path.id), [
        'example.path.demo',
        'example.path.standard',
      ]);
      expect(
        catalog.recordsOf(RecordKind.memorization).single.id,
        'example.memorization.shapes',
      );
      final lesson = catalog.toCurriculum().lesson(WorldId.iman, _learn)!;
      expect(lesson.challenges, hasLength(5));
      expect(lesson.challenges.whereType<Arrangement>(), hasLength(2));
    },
  );

  test(
    'rejects duplicate IDs, malformed variants, missing references and cycles',
    () {
      final base = _load('geometry');
      final follow = _load('follow-up');
      final records = base['records'] as List;
      expect(
        () => _decode({
          ...base,
          'records': [...records, records.first],
        }),
        throwsFormatException,
      );
      expect(() => _decode({...base, 'schema': 2}), throwsFormatException);
      expect(
        () => _decode({...base, 'version': '1.0-beta'}),
        throwsFormatException,
      );
      final sameId = _decode({...base, 'packId': 'duplicate.scope'});
      expect(
        () => _ingestor.validate([_decode(base), sameId]),
        throwsFormatException,
      );
      final changes = [
        _change('geometry', 'example.knowledge.shapes', {
          'sourceRefs': ['missing.source'],
        }),
        _change('geometry', 'example.knowledge.shapes', {
          'sourceRefs': ['example.asset.circle'],
        }),
        _change('geometry', _learn, {
          'prerequisiteIds': [_follow],
        }),
        _change('geometry', 'example.asset.circle', {
          'path': 'assets/curriculum/media/../file.png',
        }),
        _change('geometry', _choice, {
          'definition': {
            'type': 'multipleChoice',
            'prompt': 'سؤال',
            'explanation': 'شرح',
            'correctOptionId': 'one',
            'options': [
              {'id': 'one', 'label': 'شكل واحد'},
              {'id': 'two', 'label': ' شكل  واحد '},
            ],
          },
        }),
      ];
      for (final candidate in changes) {
        expect(
          () => _ingestor.validate([candidate, _decode(follow)]),
          throwsFormatException,
        );
      }
      expect(() => _ingestor.validate([_decode(base)]), returnsNormally);
      expect(
        () => _ingestor.validate([
          _decode(base),
          _change('follow-up', 'example.path.demo', {
            'lessonIds': [_follow, _learn],
          }),
        ]),
        throwsFormatException,
      );
      expect(
        () => _change('geometry', _choice, {'approvalHash': 'self-approved'}),
        throwsFormatException,
      );
    },
  );

  test('compatible independent versions retain resume, attempts and earned completion', () {
    final original = _examples(production: true);
    final first = _ingestor.activate(
      original,
      approvals: _ledger(original),
      assetDigests: _digests(),
    );
    final edited = _change(
      'geometry',
      _choice,
      {
        'definition': {
          ..._definition(original.first, _choice),
          'prompt': 'أيُّ شكل له ثلاث زوايا؟',
        },
      },
      production: true,
      version: '1.0.1',
    );
    final updatedPacks = [edited, original.last];
    final next = _ingestor.activate(
      [edited],
      approvals: _ledger(updatedPacks),
      assetDigests: _digests(),
      previous: first,
    );
    final oldCurriculum = first.toCurriculum();
    final newCurriculum = next.toCurriculum();
    final oldLesson = oldCurriculum.lesson(WorldId.iman, _learn)!;
    final newLesson = newCurriculum.lesson(WorldId.iman, _learn)!;
    expect(next.packs['example.follow-up']!.version.toString(), '2.1.0');
    expect(oldCurriculum.version, isNot(newCurriculum.version));
    expect(newLesson.contentRevision, oldLesson.contentRevision);
    final progress = LessonProgress(
      world: WorldId.iman,
      lessonId: _learn,
      contentVersion: oldCurriculum.lessonVersion(oldLesson),
      stepIndex: 0,
      completed: true,
      updatedAt: 1,
    );
    expect(
      JourneyProgress({_learn: progress}).completedIn(newCurriculum),
      contains(_learn),
    );
    final resumedPosition = LessonProgress(
      world: WorldId.iman,
      lessonId: _learn,
      contentVersion: oldCurriculum.lessonVersion(oldLesson),
      stepIndex: 1,
      completed: false,
      updatedAt: 1,
    );
    expect(
      resumedPosition.resumeIndex(
        newCurriculum.lessonVersion(newLesson),
        newLesson.steps.length,
      ),
      1,
    );
    GamePlan plan(LearningLesson lesson) => GamePlan(
      lesson.contentRevision!,
      lesson.challenges,
      compatibleDefinitionDigest: lesson.contentRevision,
    );
    final before = GameSession.start(
      'saved',
      plan(oldLesson),
      Random(2),
    ).submit(['triangle'])!;
    final restored = GameSession.restore(before.encode(), plan(newLesson));
    expect(plan(newLesson).compatibility, plan(oldLesson).compatibility);
    expect(restored.optionOrder, before.optionOrder);
    expect(restored.feedback?.correct, isTrue);
    expect(
      () => _ingestor.activate(
        [edited],
        approvals: _ledger(original),
        assetDigests: _digests(),
        previous: first,
      ),
      throwsFormatException,
    );
    expect(
      () => _ingestor.activate(
        original,
        approvals: _ledger(original),
        assetDigests: _digests(),
        previous: next,
      ),
      throwsFormatException,
    );
    final changedAnswer = _change(
      'geometry',
      _choice,
      {
        'definition': {
          ..._definition(original.first, _choice),
          'correctOptionId': 'circle',
        },
      },
      production: true,
      version: '1.0.1',
    );
    expect(
      () => _ingestor.activate(
        [changedAnswer],
        approvals: _ledger([changedAnswer, original.last]),
        assetDigests: _digests(),
        previous: first,
      ),
      throwsFormatException,
    );
    final revised = _change(
      'geometry',
      _choice,
      {
        'revision': 'r2',
        'definition': {
          ..._definition(original.first, _choice),
          'correctOptionId': 'circle',
        },
      },
      production: true,
      version: '1.0.1',
    );
    final incompatible = _ingestor.activate(
      [revised],
      approvals: _ledger([revised, original.last]),
      assetDigests: _digests(),
      previous: first,
    );
    final changedCurriculum = incompatible.toCurriculum();
    final changedLesson = changedCurriculum.lesson(WorldId.iman, _learn)!;
    expect(
      plan(changedLesson).compatibility,
      isNot(plan(oldLesson).compatibility),
    );
    expect(
      resumedPosition.resumeIndex(
        changedCurriculum.lessonVersion(changedLesson),
        changedLesson.steps.length,
      ),
      0,
    );
    expect(
      (oldLesson.challenges.first as ScoredQuestion).correctOptionId,
      'triangle',
    );
  });

  test('bundle accepts the independently approved pack batch and fails closed on changes', () async {
    expect(await loadBundledCatalog(_MemoryBundle({})), isNull);
    final packs = _examples(production: true);
    final trusted = _ledgerJson(packs);
    final files = {
      'assets/curriculum/index.json': jsonEncode({
        'schema': 1,
        'packIds': packs.map((p) => p.id).toList(),
      }).codeUnits,
      'assets/curriculum/approvals.json': utf8.encode(trusted),
      for (final name in ['geometry', 'follow-up'])
        'assets/curriculum/packs/${_production(_load(name))['packId']}.json':
            utf8.encode(jsonEncode(_production(_load(name)))),
      _circle: File('$_prefix/circle.svg').readAsBytesSync(),
    };
    expect(await loadBundledCatalog(_MemoryBundle(files)), isNotNull);
    expect(
      await loadBundledCatalog(
        _MemoryBundle({
          ...files,
          _circle: [0, 1, 2],
        }),
      ),
      isNull,
    );
    expect(
      await loadBundledCatalog(
        _MemoryBundle({...files}..remove('assets/curriculum/approvals.json')),
      ),
      isNull,
    );
  });

  testWidgets(
    'public deep links enforce cross-world prerequisites and production scope',
    (tester) async {
      final progress = MemoryProgressStore();
      final packs = _examples(production: true);
      final catalog = _ingestor.activate(
        packs,
        approvals: _ledger(packs),
        assetDigests: _digests(),
      );
      Future<void> launch() async {
        final router = createNoorRouter(
          initialLocation: '/worlds/ibadah/lessons/$_follow',
          enablePreview: false,
          catalog: catalog,
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(router),
            overrides: [progressStoreProvider.overrideWithValue(progress)],
            child: NoorApp(router: router),
          ),
        );
        await tester.pumpAndSettle();
      }

      await launch();
      expect(find.text('أكمل تجربة الأشكال'), findsOneWidget);
      expect(find.text('الأشكال'), findsNothing);
      expect(find.bySemanticsLabel('أكمل تجربة الأشكال، مغلق'), findsOneWidget);
      await progress.save(
        ProgressScope.approved,
        const LessonProgress(
          world: WorldId.iman,
          lessonId: _learn,
          contentVersion: 'prior',
          stepIndex: 0,
          completed: true,
          updatedAt: 1,
        ),
      );
      await launch();
      expect(find.text('الأشكال'), findsOneWidget);
      expect(find.text(previewLabel), findsNothing);
      expect(progress.value.records, isEmpty);
    },
  );
}

class _MemoryBundle extends CachingAssetBundle {
  _MemoryBundle(this.files);
  final Map<String, List<int>> files;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final path in files.keys)
          path: [
            {'asset': path},
          ],
      })!;
    }
    return ByteData.sublistView(Uint8List.fromList(files[key]!));
  }
}

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('$_prefix/$name.pack.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _production(Map<String, dynamic> original) => {
  ...original,
  'channel': 'production',
  'records': [
    for (final record in original['records'] as List)
      {...record as Map<String, dynamic>, 'reviewStatus': 'sourceVerified'},
  ],
};

PackDocument _decode(Map<String, dynamic> input) =>
    PackDocument.decode(jsonEncode(input));

List<PackDocument> _examples({bool production = false}) => [
  for (final name in ['geometry', 'follow-up'])
    _decode(production ? _production(_load(name)) : _load(name)),
];

PackDocument _change(
  String file,
  String id,
  Map<String, Object?> changes, {
  bool production = false,
  String? version,
}) {
  final source = production ? _production(_load(file)) : _load(file);
  return _decode({
    ...source,
    'version': ?version,
    'records': [
      for (final item in source['records'] as List)
        {...item as Map<String, dynamic>, if (item['id'] == id) ...changes},
    ],
  });
}

Map<String, Object?> _definition(PackDocument pack, String id) =>
    objectMap(pack.records[id]!.data['definition'], 'definition');

Map<String, String> _digests() => {
  _circle: sha256
      .convert(File('$_prefix/circle.svg').readAsBytesSync())
      .toString(),
};

ApprovalLedger _ledger(List<PackDocument> packs, {String? omit}) =>
    ApprovalLedger.decodeTrusted(_ledgerJson(packs, omit: omit));

String _ledgerJson(List<PackDocument> packs, {String? omit}) => jsonEncode({
  'schema': 1,
  'approvals': [
    for (final pack in packs)
      for (final record in pack.records.values)
        if (omit != record.id)
          {
            'packId': pack.id,
            'recordId': record.id,
            'digest': record.digest,
            'reviewer': 'Simulated verifier in test only',
            'reviewedAt': '2026-11-27T00:00:00Z',
          },
  ],
});
