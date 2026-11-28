import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../adventure/wudu_challenge.dart';
import '../adventure/wudu_discovery.dart';
import '../adventure/wudu_preview.dart';
import '../challenges/arrangement.dart';
import '../challenges/challenge_preview.dart';
import '../challenges/debug_catalog.dart';
import '../challenges/game_screen.dart';
import '../content/curriculum.dart';
import '../content/packs/catalog.dart';
import '../design_system/noor_theme.dart';
import '../home/adult_review_screen.dart';
import '../home/home_screen.dart';
import '../home/preview_screen.dart';
import '../lesson/lesson_screen.dart';
import '../parent/parent_screen.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import '../review/review_screen.dart';
import '../review/review_selection.dart';
import '../settings/settings_screen.dart';
import '../worlds/world_screen.dart';

GoRouter createNoorRouter({
  String? initialLocation,
  bool enablePreview = true,
  IntegratedCatalog? catalog,
  Curriculum? draftPilot,
}) {
  final showPreview = kDebugMode && enablePreview;
  final pilot =
      showPreview &&
          draftPilot != null &&
          draftPilot.isPreview &&
          draftPilot.isDraftPilot
      ? draftPilot
      : null;
  final curriculum =
      pilot ??
      catalog?.toCurriculum() ??
      loadCurriculum(enablePreview: enablePreview);
  final hasLearningTools =
      catalog != null || (showPreview && curriculum.isPreview);
  final wuduLesson = showPreview && pilot == null
      ? curriculum.lesson(WorldId.ibadah, 'W06')
      : null;
  final wudu = catalog != null && wuduLesson != null
      ? WuduDiscovery.fromApproved(catalog, wuduLesson)
      : null;
  var adultConfirmed = false;

  Arrangement? pilotActivity(GoRouterState state) {
    final world = WorldId.fromId(state.pathParameters['worldId']);
    if (pilot == null || world == null) return null;
    return pilot
        .lesson(world, state.pathParameters['lessonId'])
        ?.challenges
        .whereType<Arrangement>()
        .where((activity) => activity.id == state.pathParameters['variantId'])
        .firstOrNull;
  }

  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      if (pilot == null) return null;
      if (state.uri.path == '/adult-review') {
        adultConfirmed = false;
        return null;
      }
      return adultConfirmed ? null : '/adult-review';
    },
    onException: (context, state, router) => router.go('/'),
    routes: [
      if (pilot != null)
        GoRoute(
          path: '/adult-review',
          builder: (context, state) => AdultReviewScreen(
            onConfirm: () {
              adultConfirmed = true;
              context.go('/');
            },
          ),
        ),
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(
          showPreview: showPreview && pilot == null,
          pilotWorlds: pilot?.units.keys,
          showLearningTools: hasLearningTools,
          releaseNotes: pilot == null
              ? catalog?.releaseNotes ?? const []
              : const [],
        ),
        routes: [
          if (hasLearningTools)
            GoRoute(
              path: 'review',
              builder: (_, _) => ReviewScreen(curriculum: curriculum),
              routes: [
                for (final mode in ReviewMode.values)
                  GoRoute(
                    path: mode.name,
                    builder: (_, _) => GameScreen.review(
                      key: ValueKey(mode),
                      curriculum: curriculum,
                      mode: mode,
                    ),
                  ),
              ],
            ),
          if (hasLearningTools)
            GoRoute(
              path: 'parent',
              builder: (_, _) => ParentScreen(curriculum: curriculum),
            ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => SettingsScreen(isPilot: pilot != null),
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
                  if (pilot != null)
                    GoRoute(
                      path: 'practice/:variantId',
                      redirect: (_, state) => pilotActivity(state) != null
                          ? null
                          : '/worlds/${state.pathParameters['worldId']}/lessons/${state.pathParameters['lessonId']}',
                      builder: (_, state) => ChallengePreview(
                        key: ValueKey(state.pathParameters['variantId']),
                        definition: pilotActivity(state)!,
                        isPilot: true,
                      ),
                    ),
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
            redirect: (context, state) =>
                showPreview && pilot == null ? null : '/',
            builder: (context, state) => PreviewScreen(showWudu: wudu != null),
            routes: [
              if (wudu != null)
                GoRoute(
                  path: 'adventure/w06',
                  builder: (context, state) => WuduPreview(
                    discovery: wudu,
                    onExit: () => context.go('/preview'),
                    onChallenge: () =>
                        context.go('/preview/adventure/w06/challenge'),
                  ),
                ),
              if (wudu != null)
                GoRoute(
                  path: 'adventure/w06/challenge',
                  builder: (context, state) => WuduChallenge(
                    discovery: wudu,
                    onExit: () => context.go('/preview'),
                  ),
                ),
              GoRoute(
                path: 'challenges/:id',
                redirect: (context, state) =>
                    challengePreviewIds.contains(state.pathParameters['id'])
                    ? null
                    : '/preview',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ChallengePreview(
                    key: ValueKey(id),
                    definition: debugChallenges[id]!,
                  );
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
