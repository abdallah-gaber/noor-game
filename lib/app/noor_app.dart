import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../challenges/challenge_preview.dart';
import '../challenges/debug_catalog.dart';
import '../challenges/game_screen.dart';
import '../content/curriculum.dart';
import '../content/packs/catalog.dart';
import '../design_system/noor_theme.dart';
import '../home/home_screen.dart';
import '../home/preview_screen.dart';
import '../lesson/lesson_screen.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import '../settings/settings_screen.dart';
import '../worlds/world_screen.dart';

GoRouter createNoorRouter({
  String? initialLocation,
  bool enablePreview = true,
  IntegratedCatalog? catalog,
}) {
  final showPreview = kDebugMode && enablePreview;
  final curriculum =
      catalog?.toCurriculum() ?? loadCurriculum(enablePreview: enablePreview);

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
                redirect: (context, state) async {
                  final world = WorldId.fromId(state.pathParameters['worldId']);
                  if (world == null) return '/';
                  final path = '/worlds/${world.id}';
                  final lesson = curriculum.lesson(
                    world,
                    state.pathParameters['lessonId'],
                  );
                  if (lesson == null || lesson.steps.isEmpty) return path;

                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  try {
                    final progress = await container.read(
                      progressProvider(curriculum.progressScope).future,
                    );
                    return lesson.state(
                              completed: progress.completedIn(curriculum),
                            ) ==
                            LessonState.locked
                        ? path
                        : null;
                  } catch (_) {
                    return path;
                  }
                },
                builder: (context, state) {
                  final world = WorldId.fromId(
                    state.pathParameters['worldId'],
                  )!;
                  final lesson = curriculum.lesson(
                    world,
                    state.pathParameters['lessonId'],
                  )!;
                  return LessonScreen(
                    key: ValueKey(lesson.id),
                    world: world,
                    lesson: lesson,
                    curriculum: curriculum,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'play',
                    redirect: (context, state) {
                      final world = WorldId.fromId(
                        state.pathParameters['worldId'],
                      );
                      final lessonId = state.pathParameters['lessonId'];
                      if (world != null &&
                          curriculum
                                  .lesson(world, lessonId)
                                  ?.challenges
                                  .isNotEmpty ==
                              true) {
                        return null;
                      }
                      return '/worlds/${state.pathParameters['worldId']}/lessons/$lessonId';
                    },
                    builder: (context, state) {
                      final world = WorldId.fromId(
                        state.pathParameters['worldId'],
                      )!;
                      final lesson = curriculum.lesson(
                        world,
                        state.pathParameters['lessonId'],
                      )!;
                      return GameScreen(
                        key: ValueKey(lesson.id),
                        world: world,
                        lesson: lesson,
                        curriculum: curriculum,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'preview',
            redirect: (context, state) => showPreview ? null : '/',
            builder: (context, state) => const PreviewScreen(),
            routes: [
              GoRoute(
                path: 'challenges/:id',
                redirect: (context, state) =>
                    challengePreviewIds.contains(state.pathParameters['id'])
                    ? null
                    : '/preview',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ChallengePreview(key: ValueKey(id), id: id);
                },
              ),
            ],
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
