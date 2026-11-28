import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adventure/adventure_routes.dart';
import 'app/noor_app.dart';
import 'content/packs/bundled_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('NOOR_ADVENTURE_PLAYTEST');
  final catalog =
      enabled && kReleaseMode && defaultTargetPlatform == TargetPlatform.android
      ? await loadBundledCatalog(rootBundle)
      : null;
  runApp(
    ProviderScope(
      child: NoorApp(
        title: 'نور — المغامرة',
        router: createAdventurePlaytestRouter(catalog: catalog),
      ),
    ),
  );
}
