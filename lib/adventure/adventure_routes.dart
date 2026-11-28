import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../content/curriculum.dart';
import '../content/packs/catalog.dart';
import 'worship_adventure_map.dart';
import 'wudu_challenge.dart';
import 'wudu_discovery.dart';
import 'wudu_preview.dart';
import 'wudu_treasure.dart';

WuduDiscovery? approvedWudu(IntegratedCatalog catalog, Curriculum curriculum) {
  final lesson = curriculum.lesson(WorldId.ibadah, 'W06');
  return lesson == null ? null : WuduDiscovery.fromApproved(catalog, lesson);
}

GoRouter createAdventurePlaytestRouter({required IntegratedCatalog? catalog}) {
  final discovery = catalog == null
      ? null
      : approvedWudu(catalog, catalog.toCurriculum());
  return GoRouter(
    initialLocation: '/',
    overridePlatformDefaultLocation: true,
    onException: (_, _, router) => router.go('/'),
    routes: [
      if (discovery != null)
        ...wuduAdventureRoutes(discovery, playtest: true)
      else
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SafeArea(
              child: Center(child: Text('مغامرة الوضوء غير متاحة الآن.')),
            ),
          ),
        ),
    ],
  );
}

List<GoRoute> wuduAdventureRoutes(
  WuduDiscovery discovery, {
  required bool playtest,
}) {
  final mapPath = playtest ? '/' : worshipMapPath;
  final discoveryPath = playtest ? '/w06' : '/preview/adventure/w06';
  final challengePath = '$discoveryPath/challenge';
  final treasurePath = playtest ? '/treasures' : worshipTreasuresPath;
  String routePath(String location) =>
      playtest ? location : location.substring('/preview/'.length);

  return [
    GoRoute(
      path: routePath(mapPath),
      builder: (context, _) => WorshipAdventureMap(
        onExit: playtest ? null : () => context.go('/preview'),
        onTreasures: () => context.go(treasurePath),
        onDiscovery: () => context.go(discoveryPath),
        onChallenge: () => context.go(challengePath, extra: true),
      ),
    ),
    GoRoute(
      path: routePath(treasurePath),
      builder: (context, _) => WuduTreasures(
        waterReminder: discovery.waterReminder,
        onExit: () => context.go(mapPath),
      ),
    ),
    GoRoute(
      path: routePath(discoveryPath),
      builder: (context, _) => WuduPreview(
        discovery: discovery,
        onExit: () => context.go(mapPath),
        onChallenge: () => context.go(challengePath, extra: true),
      ),
    ),
    GoRoute(
      path: routePath(challengePath),
      builder: (context, state) => WuduChallenge(
        discovery: discovery,
        onExit: () => context.go(mapPath),
        onTreasure: () => context.go(treasurePath),
        replayCompletedOnEntry: state.extra == true,
      ),
    ),
  ];
}
