import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/adventure/wudu_courtyard.dart';
import 'package:noor/adventure/wudu_preview.dart';
import 'package:noor/adventure/wudu_discovery.dart';
import 'package:noor/adventure/wudu_discovery_art.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/audio/speech_service.dart';
import 'package:noor/challenges/game_store.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/content/packs/bundled_catalog.dart';
import 'package:noor/content/packs/catalog.dart';
import 'package:noor/home/noor_lantern.dart';
import 'package:noor/progress/progress_store.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';

const _route = '/preview/adventure/w06';
final _scene = find.byType(WuduPreview);
final _drop = find.bySemanticsLabel('قطرة الماء');
final _palms = find.bySemanticsLabel('الكفّان');
final _replay = find.byTooltip('أعد الاكتشاف');

final _challenge = find.widgetWithText(FilledButton, 'جرّب التحدّي');
final _next = find.widgetWithText(FilledButton, 'هيا نكمل');
Finder _object(WuduObject object) => find.bySemanticsLabel(object.label);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IntegratedCatalog catalog;

  setUpAll(() async {
    catalog = (await loadBundledCatalog(rootBundle))!;
  });

  test(
    'discovery binds approved order, labels, and qualified water feedback',
    () {
      final lesson = catalog.toCurriculum().lesson(WorldId.ibadah, 'W06')!;
      final discovery = WuduDiscovery.fromApproved(catalog, lesson)!;
      expect(discovery.stops.map((stop) => stop.action), [
        WuduAction.drop,
        WuduAction.touch,
        WuduAction.touch,
        WuduAction.touch,
        WuduAction.wipe,
        WuduAction.touch,
        WuduAction.closeTap,
      ]);
      final knowledge = catalog.records['W06.K3']!.text('text');
      expect(discovery.stops[5].feedback, contains(knowledge.split('،').first));
      expect(discovery.stops.last.feedback, knowledge.split('. ').last);
      expect(
        WuduDiscovery.fromApproved(
          catalog,
          const LearningLesson(
            id: 'W06',
            title: 'Incomplete lesson',
            steps: [],
          ),
        ),
        isNull,
      );
    },
  );

  testWidgets(
    'a miss cues the palms, a valid drag splashes and opens one stop',
    (tester) async {
      _viewport(tester, const Size(1024, 640));
      final effects = <String>[];
      _recordAudio(tester, effects);
      await _start(tester, catalog: catalog);

      final drop = tester.getCenter(_drop);
      final palms = tester.getCenter(_palms);
      await tester.tap(_palms);
      await tester.pumpAndSettle();
      expect(_next, findsNothing);
      await tester.dragFrom(drop, const Offset(0, 135));
      await tester.pumpAndSettle();
      expect(find.text('اسحب القطرة إلى الكفّين'), findsOneWidget);
      expect(_drop, findsOneWidget);
      expect(_next, findsNothing);

      final gesture = await tester.startGesture(drop);
      await gesture.moveBy(const Offset(28, 0));
      await tester.pump();
      await gesture.moveTo(palms);
      await tester.pump();
      expect(_palmsArt(tester).active, isTrue);
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(_palmsArt(tester).splash, inExclusiveRange(0, 1));
      expect(_palmsArt(tester).washed, isTrue);
      expect(find.bySemanticsLabel(NoorMood.celebrating.label), findsOneWidget);
      expect(find.text('غسل الكفين'), findsOneWidget);
      expect(effects, ['retry', 'retry', 'correct']);

      final next = tester.getCenter(_next);
      await tester.tapAt(next);
      await tester.tapAt(next);
      await tester.pumpAndSettle();
      expect(_object(WuduObject.mouth), findsOneWidget);
      expect(_next, findsNothing);
      expect(_object(WuduObject.face), findsNothing);
    },
  );

  testWidgets(
    'landscape wiping needs a sweep and recovers from short movement',
    (tester) async {
      _viewport(tester, const Size(1024, 640));
      await _start(tester, catalog: catalog);
      await _reachHead(tester);
      final head = _object(WuduObject.head);
      final center = tester.getCenter(head);
      await tester.dragFrom(center, const Offset(24, 0));
      await tester.pumpAndSettle();
      expect(
        find.text('مرّر إصبعك من جانب إلى آخر، أو المس الرأس'),
        findsOneWidget,
      );
      expect(_next, findsNothing);

      final gesture = await tester.startGesture(center + const Offset(55, 0));
      await gesture.moveBy(const Offset(-23, 0));
      await gesture.moveBy(const Offset(-73, 0));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.text('مسح الرأس'), findsOneWidget);
      expect(_art(tester, WuduObject.head).done, isTrue);
      expect(_art(tester, WuduObject.head).phase, inExclusiveRange(0, 1));
      expect(_next, findsOneWidget);
    },
  );

  testWidgets(
    'portrait 2× tap path completes all stops without motion or storage',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final effects = <String>[];
      _recordAudio(tester, effects);
      final accessedStores = <String>[];

      await _start(
        tester,
        catalog: catalog,
        effects: false,
        accessedStores: accessedStores,
      );
      await _tapTarget(tester, _drop);
      await _tapTarget(tester, _palms);
      expect(_palmsArt(tester).splash, 0);
      await _tapTarget(tester, _next);

      final nose = _object(WuduObject.nose);
      await _tapTarget(tester, nose);
      expect(find.text('الاستنشاق · المس الفم'), findsOneWidget);
      await tester.tapAt(tester.getCenter(nose));
      await tester.pumpAndSettle();
      expect(_next, findsNothing);
      expect(_art(tester, WuduObject.mouth).highlighted, isTrue);
      await _tapTarget(tester, _object(WuduObject.mouth));
      expect(find.text('المضمضة والاستنشاق'), findsOneWidget);
      await _tapTarget(tester, _next);

      await _complete(tester, [WuduObject.face]);
      await _complete(tester, [WuduObject.leftArm, WuduObject.rightArm]);
      await _tapTarget(tester, _object(WuduObject.head));
      expect(_art(tester, WuduObject.head).phase, 0);
      expect(_art(tester, WuduObject.head).done, isTrue);
      await _tapTarget(tester, _next);
      await _complete(tester, [WuduObject.rightFoot, WuduObject.leftFoot]);
      expect(_courtyard(tester).flowing, isTrue);
      expect(_replay, findsNothing);
      expect(_challenge, findsNothing);

      await _tapTarget(tester, _object(WuduObject.tap));
      expect(_challenge, findsOneWidget);
      expect(_courtyard(tester).flowing, isFalse);
      expect(
        find.text(catalog.records['W06.K3']!.text('text').split('. ').last),
        findsOneWidget,
      );
      await _tapTarget(tester, _replay);
      expect(_drop, findsOneWidget);
      expect(_next, findsNothing);
      expect(effects, isEmpty);
      expect(accessedStores, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('developer menu opens the approved prototype and exit returns', (
    tester,
  ) async {
    await _start(tester, catalog: catalog, location: '/preview');
    final link = find.text('معاينة مغامرة الوضوء');
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(_scene, findsOneWidget);

    await tester.tap(find.byTooltip('العودة إلى المعاينة'));
    await tester.pumpAndSettle();
    expect(_scene, findsNothing);
    expect(link, findsOneWidget);
  });

  testWidgets('disabled preview and unavailable catalog reject direct access', (
    tester,
  ) async {
    for (final (approved, enabled) in [(catalog, false), (null, true)]) {
      await _start(tester, catalog: approved, enablePreview: enabled);
      expect(_scene, findsNothing);
      expect(find.text('أهلًا يا نور!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('draft pilot keeps its adult gate and excludes W06 discovery', (
    tester,
  ) async {
    final router = await _start(
      tester,
      catalog: catalog,
      draftPilot: const Curriculum(
        version: 'test',
        isPreview: true,
        isDraftPilot: true,
      ),
    );
    final confirm = find.text('أنا بالغ وأريد مراجعة المسودات');
    expect(confirm, findsOneWidget);
    expect(_scene, findsNothing);

    await tester.tap(confirm);
    await tester.pumpAndSettle();
    router.go(_route);
    await tester.pumpAndSettle();
    expect(_scene, findsNothing);
    expect(find.text('أهلًا يا نور!'), findsOneWidget);
  });
}

Future<void> _reachHead(WidgetTester tester) async {
  await _tapTarget(tester, _drop);
  await _tapTarget(tester, _palms);
  await _tapTarget(tester, _next);
  await _complete(tester, [WuduObject.mouth, WuduObject.nose]);
  await _complete(tester, [WuduObject.face]);
  await _complete(tester, [WuduObject.rightArm, WuduObject.leftArm]);
}

Future<void> _complete(WidgetTester tester, List<WuduObject> objects) async {
  for (final object in objects) {
    expect(_next, findsNothing);
    await _tapTarget(tester, _object(object));
  }
  await _tapTarget(tester, _next);
}

Future<void> _tapTarget(WidgetTester tester, Finder target) async {
  expect(tester.getSize(target).shortestSide, greaterThanOrEqualTo(48));
  expect(
    tester
        .getSemantics(target)
        .getSemanticsData()
        .hasAction(SemanticsAction.tap),
    isTrue,
  );
  await tester.tap(target);
  await tester.pumpAndSettle();
}

T _painter<T extends CustomPainter>(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((widget) => widget.painter)
    .whereType<T>()
    .single;

CourtyardPainter _courtyard(WidgetTester tester) =>
    _painter<CourtyardPainter>(tester);

DiscoveryObjectPainter _art(WidgetTester tester, WuduObject object) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((widget) => widget.painter)
    .whereType<DiscoveryObjectPainter>()
    .singleWhere((painter) => painter.object == object);

PalmsPainter _palmsArt(WidgetTester tester) => _painter<PalmsPainter>(tester);

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _recordAudio(WidgetTester tester, List<String> effects) {
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(PlatformSpeech.channel, (call) async {
    expect(call.method, 'effect');
    effects.add(call.arguments as String);
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(PlatformSpeech.channel, null),
  );
}

Future<GoRouter> _start(
  WidgetTester tester, {
  required IntegratedCatalog? catalog,
  bool enablePreview = true,
  bool effects = true,
  String location = _route,
  List<String>? accessedStores,
  Curriculum? draftPilot,
}) async {
  final router = createNoorRouter(
    initialLocation: location,
    enablePreview: enablePreview,
    catalog: catalog,
    draftPilot: draftPilot,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (accessedStores != null) ...[
          progressStoreProvider.overrideWith((ref) {
            accessedStores.add('progress');
            throw StateError('Discovery accessed progress');
          }),
          gameStoreProvider.overrideWith((ref) {
            accessedStores.add('assessment');
            throw StateError('Discovery accessed assessment');
          }),
        ],
        settingsStoreProvider.overrideWithValue(_AudioSettings(effects)),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _AudioSettings implements SettingsStore {
  const _AudioSettings(this.effects);

  final bool effects;

  @override
  Future<AudioPreferences> load() async =>
      AudioPreferences(speech: true, effects: effects);

  @override
  Future<void> save(AudioPreferences preferences) async {}
}
