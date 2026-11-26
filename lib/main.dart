import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/noor_app.dart';

void main() {
  runApp(ProviderScope(child: NoorApp(router: createNoorRouter())));
}
