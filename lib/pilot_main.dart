import 'package:flutter/foundation.dart';

import 'content/draft_pilot.dart';
import 'main.dart' as app;

Future<void> main() {
  if (!kDebugMode) return app.main();
  const payload = String.fromEnvironment('NOOR_DRAFT_PILOT');
  if (payload.isEmpty) {
    throw StateError(
      'Run scripts/prepare_draft_pilot.py and pass its defines file.',
    );
  }
  return app.startNoor(draftPilot: decodeDraftPilot(payload));
}
