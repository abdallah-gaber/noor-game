import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../challenges/challenge_definition.dart';
import 'catalog.dart';
import 'pack_document.dart';

const _base = 'assets/curriculum';
const _index = '$_base/index.json';
const _approvals = '$_base/approvals.json';

/// The index and approval ledger come from the signed app bundle, outside packs.
Future<IntegratedCatalog?> loadBundledCatalog(AssetBundle bundle) async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final assets = manifest.listAssets().toSet();
    if (!assets.contains(_index)) return null;

    final index = objectMap(
      jsonDecode(await bundle.loadString(_index)),
      'bundle index',
    );
    checkSchema(index);
    final packIds = idList(index['packIds'], 'pack IDs');
    if (packIds.isEmpty || !assets.contains(_approvals)) {
      throw const FormatException('Incomplete curriculum bundle');
    }
    final approvals = ApprovalLedger.decodeTrusted(
      await bundle.loadString(_approvals),
    );
    final packs = <PackDocument>[];
    for (final id in packIds) {
      final path = '$_base/packs/$id.json';
      if (!assets.contains(path)) {
        throw const FormatException('Missing bundled pack');
      }
      final pack = PackDocument.decode(await bundle.loadString(path));
      if (pack.id != id) {
        throw const FormatException('Pack ID does not match bundle index');
      }
      packs.add(pack);
    }

    const ingestor = CatalogIngestor();
    final validated = ingestor.validate(packs);
    final digests = <String, String>{};
    for (final record in validated.records.values.where(
      (item) => item.kind == RecordKind.asset,
    )) {
      final path = record.text('path');
      if (!assets.contains(path)) {
        throw const FormatException('Missing bundled media');
      }
      final bytes = await bundle.load(path);
      digests[path] = sha256
          .convert(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          )
          .toString();
    }
    final releaseNotes = [
      for (final value in objectList(
        index['releaseNotes'] ?? const [],
        'release notes',
      ))
        _releaseNote(objectMap(value, 'release note')),
    ];
    return ingestor.activate(
      packs,
      releaseNotes: releaseNotes,
      approvals: approvals,
      assetDigests: digests,
    );
  } on FormatException {
    debugPrint('Noor curriculum bundle failed validation.');
    return null;
  } on FlutterError {
    debugPrint('Noor curriculum bundle could not be read.');
    return null;
  }
}

PackReleaseNote _releaseNote(Map<String, Object?> data) => (
  packId: challengeId(data['packId']),
  version: challengeText(data['version']),
  whatsNew: challengeText(data['whatsNew']),
);
