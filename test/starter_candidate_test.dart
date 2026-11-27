import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor/content/packs/catalog.dart';
import 'package:noor/content/packs/pack_document.dart';

void main() {
  final folder = Platform.environment['NOOR_STARTER_CANDIDATE'];
  test('validate draft candidates and both exact v1 digest domains', () {
    final requestText = File('$folder/approval-request.json')
        .readAsStringSync();
    final request = jsonDecode(requestText) as Map<String, dynamic>;
    final packs = [
      for (final entry in request['candidatePacks'] as List)
        PackDocument.decode(
          File('$folder/${entry['packId']}.json').readAsStringSync(),
        ),
    ];
    final byId = {for (final pack in packs) pack.id: pack};
    const ingestor = CatalogIngestor();
    final checked = ingestor.validate(packs);
    expect(checked.variants, hasLength(65));
    expect(
      checked.records.values.where(
        (record) => record.kind == RecordKind.lesson,
      ),
      hasLength(6),
    );
    expect(
      checked.records.values.where(
        (record) => record.kind == RecordKind.knowledge,
      ),
      hasLength(18),
    );
    expect(checked.records, hasLength(112));
    for (final entry in request['candidatePacks'] as List) {
      expect(byId[entry['packId']]!.digest, entry['candidateDigest']);
    }
    for (final entry in request['recordRequests'] as List) {
      final pack = byId[entry['packId']]!;
      final record = pack.records[entry['recordId']]!;
      expect(record.review, AuthoringReview.draft);
      expect(record.digest, entry['candidateDigest']);
      expect(
        canonicalDigest({
          'packId': pack.id,
          'record': {...record.data, 'reviewStatus': 'sourceVerified'},
        }),
        entry['conditionalApprovalDigest'],
      );
    }
    expect(
      () => ApprovalLedger.decodeTrusted(requestText),
      throwsFormatException,
    );
    expect(
      () => ingestor.activate(
        packs,
        approvals: ApprovalLedger.decodeTrusted('{"schema":1,"approvals":[]}'),
      ),
      throwsFormatException,
    );
  }, skip: folder == null ? 'Private starter candidate is local only.' : false);
}
