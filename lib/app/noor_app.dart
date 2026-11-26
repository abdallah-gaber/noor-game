import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../design_system/noor_layout.dart';
import '../design_system/noor_theme.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

GoRouter createNoorRouter({
  String? initialLocation,
  bool enablePreview = true,
}) {
  final showPreview = kDebugMode && enablePreview;

  return GoRouter(
    initialLocation: initialLocation,
    onException: (context, state, router) => router.go('/'),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(showPreview: showPreview),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'preview',
            redirect: (context, state) => showPreview ? null : '/',
            builder: (context, state) => const Scaffold(
              appBar: NoorAppBar('معاينة المطوّر'),
              body: NoorPage(
                maxWidth: 560,
                child: Text(
                  'محتوى تجريبي للمطوّر فقط: هذه عيّنة لواجهة التطبيق.',
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class NoorApp extends StatelessWidget {
  const NoorApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'نور',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: noorTheme,
      routerConfig: router,
    );
  }
}
