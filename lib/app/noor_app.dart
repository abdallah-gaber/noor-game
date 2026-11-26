import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import '../design_system/noor_theme.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../worlds/world_screen.dart';

GoRouter createNoorRouter({
  String? initialLocation,
  bool enablePreview = true,
}) {
  final showPreview = kDebugMode && enablePreview;
  final curriculum = loadCurriculum(enablePreview: enablePreview);

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
            path: 'worlds/:worldId',
            redirect: (context, state) =>
                WorldId.fromId(state.pathParameters['worldId']) == null
                ? '/'
                : null,
            builder: (context, state) => WorldScreen(
              world: WorldId.fromId(state.pathParameters['worldId'])!,
              curriculum: curriculum,
            ),
            routes: [
              GoRoute(
                path: 'lessons/:lessonId',
                redirect: (context, state) {
                  final world = WorldId.fromId(state.pathParameters['worldId']);
                  if (world == null) return '/';
                  final lesson = curriculum.lesson(
                    world,
                    state.pathParameters['lessonId'],
                  );
                  final lessonState = lesson?.state(
                    completed: {'${world.id}-first'},
                  );
                  return lessonState == null ||
                          lessonState == LessonState.locked
                      ? '/worlds/${world.id}'
                      : null;
                },
                builder: (context, state) {
                  final world = WorldId.fromId(
                    state.pathParameters['worldId'],
                  )!;
                  final lesson = curriculum.lesson(
                    world,
                    state.pathParameters['lessonId'],
                  )!;
                  return Scaffold(
                    appBar: NoorAppBar(lesson.title),
                    body: const NoorPage(child: Text(previewLabel)),
                  );
                },
              ),
            ],
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
