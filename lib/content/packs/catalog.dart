import '../../challenges/arrangement.dart';
import '../../challenges/challenge_definition.dart';
import '../../challenges/flashcard.dart';
import '../../challenges/game_session.dart';
import '../../challenges/scored_question.dart';
import '../curriculum.dart';
import 'pack_document.dart';

enum SourceCategory { quran, hadith, scholarship, other }

enum AssetMedia { illustration, narration }

enum RightsBasis { publicDomain, licensed, permission, original }

enum PathPriority { prayerReadiness, standard }

enum VariantDifficulty { recognition, recall, application }

typedef RecordLifecycle = ({
  bool draft,
  bool sourceVerified,
  bool humanApproved,
  bool validated,
  bool integrated,
});

class ValidatedCatalog {
  ValidatedCatalog._(this.packs, this.records, this.variants);

  final Map<String, PackDocument> packs;
  final Map<String, PackRecord> records;
  final Map<String, ChallengeDefinition> variants;

  RecordLifecycle lifecycle(String id, ApprovalLedger ledger) {
    final record = records[id]!;
    return (
      draft: record.review == AuthoringReview.draft,
      sourceVerified: record.review == AuthoringReview.sourceVerified,
      humanApproved: ledger.approves(record),
      validated: true,
      integrated: false,
    );
  }

  String lessonRevision(PackRecord lesson) => canonicalDigest([
    lesson.identifier('revision'),
    for (final knowledge in lesson.ids('knowledgeIds'))
      [knowledge, records[knowledge]!.identifier('revision')],
    for (final variant in lesson.ids('variantIds'))
      [
        variant,
        records[variant]!.identifier('revision'),
        challengeGradingKey(variants[variant]!),
      ],
  ]);
}

class IntegratedCatalog {
  IntegratedCatalog._(this._checked);

  final ValidatedCatalog _checked;

  Map<String, PackDocument> get packs => _checked.packs;
  Map<String, PackRecord> get records => _checked.records;

  Iterable<PackRecord> recordsOf(RecordKind kind) =>
      records.values.where((record) => record.kind == kind);

  List<PackRecord> get paths => List.unmodifiable(
    recordsOf(RecordKind.path).toList()..sort((left, right) {
      final a = enumValue(
        PathPriority.values,
        left.data['priority'],
        'path priority',
      );
      final b = enumValue(
        PathPriority.values,
        right.data['priority'],
        'path priority',
      );
      final priority = a.index.compareTo(b.index);
      return priority == 0 ? left.id.compareTo(right.id) : priority;
    }),
  );

  RecordLifecycle lifecycle(String id) {
    if (!records.containsKey(id)) throw ArgumentError.value(id, 'id');
    return (
      draft: false,
      sourceVerified: true,
      humanApproved: true,
      validated: true,
      integrated: true,
    );
  }

  Curriculum toCurriculum() {
    final worlds = <WorldId, List<LearningUnit>>{};
    final lessonsByUnit = <String, List<LearningLesson>>{};
    for (final record in recordsOf(RecordKind.lesson)) {
      final revision = _checked.lessonRevision(record);
      final lesson = LearningLesson(
        id: record.id,
        title: record.text('title'),
        contentRevision: revision,
        prerequisiteIds: record.ids('prerequisiteIds'),
        steps: List<LessonStep>.unmodifiable(
          record.ids('knowledgeIds').map((id) {
            final knowledge = records[id]!;
            return LessonStep(
              knowledge.text('title'),
              knowledge.text('text'),
              LessonPicture.trail,
            );
          }),
        ),
        challenges: List<ChallengeDefinition>.unmodifiable(
          record.ids('variantIds').map((id) => _checked.variants[id]!),
        ),
      );
      lessonsByUnit
          .putIfAbsent(record.identifier('unitId'), () => [])
          .add(lesson);
    }
    for (final unit in recordsOf(RecordKind.unit)) {
      final world = WorldId.fromId(unit.identifier('worldId'))!;
      final lessons = lessonsByUnit[unit.id];
      if (lessons == null) continue;
      worlds
          .putIfAbsent(world, () => [])
          .add(
            LearningUnit(
              id: unit.id,
              world: world,
              title: unit.text('title'),
              lessons: List.unmodifiable(lessons),
            ),
          );
    }
    return Curriculum(
      version: canonicalDigest({
        for (final pack in packs.values) pack.id: pack.version.toString(),
      }),
      units: Map.unmodifiable({
        for (final entry in worlds.entries)
          entry.key: List<LearningUnit>.unmodifiable(entry.value),
      }),
    );
  }
}

class CatalogIngestor {
  const CatalogIngestor();

  ValidatedCatalog validate(Iterable<PackDocument> packs) {
    final byPack = <String, PackDocument>{};
    final records = <String, PackRecord>{};
    final variants = <String, ChallengeDefinition>{};
    for (final pack in packs) {
      if (byPack.containsKey(pack.id)) {
        throw FormatException('Duplicate pack ${pack.id}');
      }
      byPack[pack.id] = pack;
      for (final record in pack.records.values) {
        if (records.containsKey(record.id)) {
          throw FormatException('Duplicate record ${record.id}');
        }
        records[record.id] = record;
      }
    }
    final validator = _GraphValidator(records, variants);
    for (final record in records.values) {
      validator.validate(record);
    }
    validator.validatePrerequisites();
    return ValidatedCatalog._(
      Map.unmodifiable(byPack),
      Map.unmodifiable(records),
      Map.unmodifiable(variants),
    );
  }

  IntegratedCatalog activate(
    Iterable<PackDocument> incoming, {
    required ApprovalLedger approvals,
    Map<String, String> assetDigests = const {},
    IntegratedCatalog? previous,
  }) {
    final incomingList = List<PackDocument>.of(incoming);
    final next = <String, PackDocument>{...?previous?.packs};
    final touched = <String>{};
    for (final pack in incomingList) {
      if (!touched.add(pack.id)) {
        throw FormatException('Duplicate update ${pack.id}');
      }
      final old = next[pack.id];
      if (old != null) {
        final order = pack.version.compareTo(old.version);
        if (order < 0 || (order == 0 && pack.digest != old.digest)) {
          throw FormatException('Pack ${pack.id} needs a new version');
        }
      }
      next[pack.id] = pack;
    }
    final checked = validate(next.values);
    for (final pack in checked.packs.values) {
      if (pack.channel != PackChannel.production) {
        throw FormatException('Pack ${pack.id} is not production');
      }
      for (final record in pack.records.values) {
        if (record.review != AuthoringReview.sourceVerified ||
            !approvals.approves(record)) {
          throw FormatException(
            'Missing verified record approval for ${record.id}',
          );
        }
        if (record.kind == RecordKind.asset &&
            assetDigests[record.text('path')] != record.data['sha256']) {
          throw FormatException('Missing or changed local asset ${record.id}');
        }
      }
    }
    if (previous != null) _validateUpdate(previous._checked, checked);
    return IntegratedCatalog._(checked);
  }

  void _validateUpdate(ValidatedCatalog previous, ValidatedCatalog next) {
    for (final old in previous.records.values) {
      final record = next.records[old.id];
      if (record == null) continue;
      if (record.kind != old.kind || record.packId != old.packId) {
        throw FormatException('Changed identity for ${record.id}');
      }
      switch (record.kind) {
        case RecordKind.unit:
          if (record.data['worldId'] != old.data['worldId']) {
            throw FormatException('Changed world for ${record.id}');
          }
        case RecordKind.lesson:
          final oldWorld =
              previous.records[old.identifier('unitId')]!.data['worldId'];
          final newWorld =
              next.records[record.identifier('unitId')]!.data['worldId'];
          if (oldWorld != newWorld) {
            throw FormatException('Changed lesson world for ${record.id}');
          }
          if (old.data['revision'] == record.data['revision'] &&
              _lessonLayout(old) != _lessonLayout(record)) {
            throw FormatException(
              'New lesson revision required for ${record.id}',
            );
          }
        case RecordKind.variant:
          final before = challengeGradingKey(previous.variants[record.id]!);
          final after = challengeGradingKey(next.variants[record.id]!);
          if (old.data['revision'] == record.data['revision'] &&
              before != after) {
            throw FormatException(
              'New variant revision required for ${record.id}',
            );
          }
        default:
          break;
      }
    }
  }
}

String _lessonLayout(PackRecord record) => canonicalDigest([
  record.ids('knowledgeIds'),
  record.ids('variantIds'),
  record.ids('prerequisiteIds'),
]);

class _GraphValidator {
  _GraphValidator(this.records, this.variants);
  final Map<String, PackRecord> records;
  final Map<String, ChallengeDefinition> variants;
  final _paths = <String>{};

  void validate(PackRecord record) {
    switch (record.kind) {
      case RecordKind.source:
        record.text('title');
        record.text('locator');
        final source = enumValue(
          SourceCategory.values,
          record.data['category'],
          'source category',
        );
        if (source == SourceCategory.hadith) record.text('authenticity');
        if (record.data.containsKey('url')) {
          final url = Uri.tryParse(record.text('url'));
          if (url == null ||
              url.scheme != 'https' ||
              url.host.isEmpty ||
              url.userInfo.isNotEmpty) {
            throw FormatException('Invalid source URL for ${record.id}');
          }
        }
      case RecordKind.asset:
        enumValue(AssetMedia.values, record.data['media'], 'asset media');
        final path = record.text('path');
        final pieces = path.split('/');
        if (!path.startsWith('assets/curriculum/media/') ||
            pieces.any(
              (piece) =>
                  piece == '.' ||
                  piece == '..' ||
                  !RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(piece),
            ) ||
            !_paths.add(path)) {
          throw FormatException(
            'Unsafe or duplicate asset path for ${record.id}',
          );
        }
        sha256Value(record.data['sha256']);
        _rights(record);
      case RecordKind.unit:
        record.text('title');
        if (WorldId.fromId(record.identifier('worldId')) == null) {
          throw FormatException('Unknown world for ${record.id}');
        }
      case RecordKind.knowledge:
        record.identifier('revision');
        _textRecord(record);
      case RecordKind.variant:
        _variant(record);
      case RecordKind.lesson:
        _lesson(record);
      case RecordKind.memorization:
        _textRecord(record);
        _rights(record);
      case RecordKind.treasure:
        _textRecord(record);
        _refs(record, 'knowledgeIds', RecordKind.knowledge, required: true);
      case RecordKind.path:
        record.text('title');
        enumValue(
          PathPriority.values,
          record.data['priority'],
          'path priority',
        );
        final lessons = _refs(
          record,
          'lessonIds',
          RecordKind.lesson,
          required: true,
        );
        final order = {
          for (final (index, lesson) in lessons.indexed) lesson.id: index,
        };
        for (final lesson in lessons) {
          for (final id in lesson.ids('prerequisiteIds')) {
            if (order[id] == null || order[id]! >= order[lesson.id]!) {
              throw FormatException(
                'Path ${record.id} needs prerequisite $id earlier',
              );
            }
          }
        }
      case RecordKind.release:
        record.text('title');
        record.text('whatsNew');
        final published = record.text('releasedAt');
        if (!published.endsWith('Z') || DateTime.tryParse(published) == null) {
          throw FormatException('Invalid release date for ${record.id}');
        }
    }
  }

  void _textRecord(PackRecord record) {
    record.text('title');
    record.text('text');
    _refs(record, 'sourceRefs', RecordKind.source, required: true);
    _media(record, 'illustrationRef', AssetMedia.illustration);
    _media(record, 'audioRef', AssetMedia.narration);
  }

  void _rights(PackRecord record) {
    final rights = objectMap(record.data['rights'], 'rights');
    enumValue(RightsBasis.values, rights['basis'], 'rights basis');
    challengeText(rights['evidence']);
  }

  void _variant(PackRecord record) {
    record.identifier('revision');
    enumValue(
      VariantDifficulty.values,
      record.data['difficulty'],
      'difficulty',
    );
    _refs(record, 'sourceRefs', RecordKind.source, required: true);
    _refs(record, 'knowledgeIds', RecordKind.knowledge, required: true);
    _media(record, 'illustrationRef', AssetMedia.illustration);
    _media(record, 'audioRef', AssetMedia.narration);
    final input = objectMap(record.data['definition'], 'definition');
    if (input.keys.any({'schema', 'id', 'knowledgeIds'}.contains)) {
      throw FormatException('Nested identity in ${record.id}');
    }
    final json = {
      ...input,
      'schema': 1,
      'id': record.id,
      'knowledgeIds': record.ids('knowledgeIds'),
    };
    final definition = switch (input['type']) {
      'multipleChoice' || 'trueFalse' => ScoredQuestion.fromJson(json),
      'matching' || 'ordering' => Arrangement.fromJson(json),
      'flashcard' => Flashcard.fromJson(json),
      _ => throw FormatException('Unsupported mechanic for ${record.id}'),
    };
    final options = switch (definition) {
      ScoredQuestion question => question.options,
      Arrangement arrangement => [...arrangement.items, ...arrangement.targets],
      _ => const <AnswerOption>[],
    };
    for (final option in options) {
      if (option.illustration case final id?) {
        _requireAsset(record, id, AssetMedia.illustration);
      }
    }
    variants[record.id] = definition;
  }

  void _lesson(PackRecord record) {
    record.text('title');
    record.identifier('revision');
    _ref(record, record.identifier('unitId'), RecordKind.unit);
    _refs(record, 'prerequisiteIds', RecordKind.lesson);
    final knowledge = _refs(
      record,
      'knowledgeIds',
      RecordKind.knowledge,
      required: true,
    ).map((item) => item.id).toSet();
    for (final variant in _refs(record, 'variantIds', RecordKind.variant)) {
      if (!knowledge.containsAll(variant.ids('knowledgeIds'))) {
        throw FormatException(
          'Variant ${variant.id} refers to knowledge outside ${record.id}',
        );
      }
    }
  }

  void validatePrerequisites() {
    final visiting = <String>{};
    final visited = <String>{};

    void visit(PackRecord record) {
      if (visited.contains(record.id)) return;
      if (!visiting.add(record.id)) {
        throw FormatException('Cyclic prerequisite at ${record.id}');
      }
      for (final id in record.ids('prerequisiteIds')) {
        visit(records[id]!);
      }
      visiting.remove(record.id);
      visited.add(record.id);
    }

    for (final record in records.values.where(
      (item) => item.kind == RecordKind.lesson,
    )) {
      visit(record);
    }
  }

  List<PackRecord> _refs(
    PackRecord owner,
    String field,
    RecordKind kind, {
    bool required = false,
  }) {
    final refs = owner.ids(field);
    if (required && refs.isEmpty) {
      throw FormatException('Missing $field for ${owner.id}');
    }
    return [for (final id in refs) _ref(owner, id, kind)];
  }

  PackRecord _ref(PackRecord owner, String id, RecordKind kind) {
    final found = records[id];
    if (found == null || found.kind != kind) {
      throw FormatException('Invalid ${kind.name} $id in ${owner.id}');
    }
    return found;
  }

  void _media(PackRecord record, String field, AssetMedia media) {
    if (record.optionalId(field) case final id?) {
      _requireAsset(record, id, media);
    }
  }

  void _requireAsset(PackRecord owner, String id, AssetMedia media) {
    if (_ref(owner, id, RecordKind.asset).data['media'] != media.name) {
      throw FormatException('Wrong asset media $id in ${owner.id}');
    }
  }
}
