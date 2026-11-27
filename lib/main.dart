import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/noor_app.dart';
import 'content/packs/bundled_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalog = await loadBundledCatalog(rootBundle);
  runApp(
    ProviderScope(
      child: NoorApp(router: createNoorRouter(catalog: catalog)),
    ),
  );
}
