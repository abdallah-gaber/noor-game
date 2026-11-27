import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../challenges/challenge_definition.dart';

enum PackChannel { draft, fixture, production }

enum RecordKind {
  source,
  asset,
  unit,
  knowledge,
  variant,
  lesson,
  memorization,
  treasure,
  path,
  release,
}

enum AuthoringReview { draft, sourceVerified }

class PackVersion implements Comparable<PackVersion> {
  PackVersion.parse(String text) : numbers = _parse(text);
  final List<int> numbers;

  static List<int> _parse(String text) {
    if (!RegExp(
      r'^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$',
    ).hasMatch(text)) {
      throw const FormatException('Expected major.minor.patch pack version');
    }
    return List.unmodifiable(text.split('.').map(int.parse));
  }

  @override
  int compareTo(PackVersion other) {
    for (var i = 0; i < numbers.length; i++) {
      final cmp = numbers[i].compareTo(other.numbers[i]);
      if (cmp != 0) return cmp;
    }
    return 0;
  }

  @override
  String toString() => numbers.join('.');
}

class PackRecord {
  PackRecord._(this.packId, this.id, this.kind, this.review, this.data);

  final String packId;
  final String id;
  final RecordKind kind;
  final AuthoringReview review;
  final Map<String, Object?> data;

  late final String digest = canonicalDigest({
    'packId': packId,
    'record': data,
  });

  String text(String field) => challengeText(data[field]);
  String identifier(String field) => challengeId(data[field]);
  List<String> ids(String field) => idList(data[field], '$id.$field');
  String? optionalId(String field) =>
      data.containsKey(field) ? identifier(field) : null;
}

class PackDocument {
  PackDocument._(
    this.id,
    this.version,
    this.channel,
    this.records,
    this.digest,
  );

  static const schema = 1;
  final String id;
  final PackVersion version;
  final PackChannel channel;
  final Map<String, PackRecord> records;
  final String digest;

  factory PackDocument.decode(String source) {
    final map = objectMap(jsonDecode(source), 'pack');
    checkSchema(map);
    final id = challengeId(map['packId']);
    final version = PackVersion.parse(challengeText(map['version']));
    final channel = enumValue(PackChannel.values, map['channel'], 'channel');
    final records = <String, PackRecord>{};
    for (final input in objectList(map['records'], 'records')) {
      final entry = objectMap(_freeze(input), 'record');
      final recordId = challengeId(entry['id']);
      if (records.containsKey(recordId)) {
        throw FormatException('Duplicate record ID $recordId');
      }
      final kind = enumValue(RecordKind.values, entry['kind'], 'kind');
      final review = enumValue(
        AuthoringReview.values,
        entry['reviewStatus'],
        'reviewStatus',
      );
      for (final prohibited in [
        'approvalHash',
        'approved',
        'reviewer',
        'validated',
        'integrated',
      ]) {
        if (entry.containsKey(prohibited)) {
          throw FormatException('Untrusted lifecycle field $prohibited');
        }
      }
      records[recordId] = PackRecord._(id, recordId, kind, review, entry);
    }
    if (records.isEmpty) {
      throw const FormatException('Expected at least one record');
    }
    return PackDocument._(
      id,
      version,
      channel,
      Map.unmodifiable(records),
      canonicalDigest(map),
    );
  }
}

class ApprovalLedger {
  ApprovalLedger._(this._entries);

  factory ApprovalLedger.decodeTrusted(String source) {
    final ledger = objectMap(jsonDecode(source), 'approval ledger');
    checkSchema(ledger);
    final entries = <String, String>{};
    for (final item in objectList(ledger['approvals'], 'approvals')) {
      final entry = objectMap(item, 'approval');
      final key =
          '${challengeId(entry['packId'])}/${challengeId(entry['recordId'])}';
      if (entries.containsKey(key)) {
        throw FormatException('Duplicate approval $key');
      }
      challengeText(entry['reviewer']);
      final reviewed = challengeText(entry['reviewedAt']);
      if (!reviewed.endsWith('Z') || DateTime.tryParse(reviewed) == null) {
        throw const FormatException('Expected UTC review timestamp');
      }
      entries[key] = sha256Value(entry['digest']);
    }
    return ApprovalLedger._(Map.unmodifiable(entries));
  }

  final Map<String, String> _entries;

  bool approves(PackRecord record) =>
      _entries['${record.packId}/${record.id}'] == record.digest;
}

String sha256Value(Object? value) {
  if (value is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw const FormatException('Expected lowercase SHA-256 digest');
  }
  return value;
}

void checkSchema(Map<String, Object?> object) {
  if (object['schema'] is! int || object['schema'] != PackDocument.schema) {
    throw const FormatException('Unsupported curriculum schema');
  }
}

Map<String, Object?> objectMap(Object? input, String field) {
  if (input is! Map<String, Object?>) {
    throw FormatException('Expected object for $field');
  }
  return input;
}

List<Object?> objectList(Object? input, String field) {
  if (input is! List<Object?>) {
    throw FormatException('Expected array for $field');
  }
  return input;
}

List<String> idList(Object? input, String field) {
  final result = List<String>.unmodifiable(
    objectList(input, field).map(challengeId),
  );
  if (result.toSet().length != result.length) {
    throw FormatException('Duplicate ID in $field');
  }
  return result;
}

T enumValue<T extends Enum>(List<T> options, Object? input, String field) {
  for (final option in options) {
    if (option.name == input) return option;
  }
  throw FormatException('Invalid $field');
}

String canonicalDigest(Object? data) =>
    sha256.convert(utf8.encode(jsonEncode(_sorted(data)))).toString();

Object? _sorted(Object? data) {
  if (data is Map<String, Object?>) {
    return {
      for (final key in data.keys.toList()..sort()) key: _sorted(data[key]),
    };
  }
  if (data is List<Object?>) return data.map(_sorted).toList();
  return data;
}

Object? _freeze(Object? input) {
  if (input is Map<String, Object?>) {
    return Map<String, Object?>.unmodifiable(
      input.map((key, value) => MapEntry(key, _freeze(value))),
    );
  }
  if (input is List<Object?>) {
    return List<Object?>.unmodifiable(input.map(_freeze));
  }
  return input;
}
