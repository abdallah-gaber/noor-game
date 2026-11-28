import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/adventure/wudu_courtyard.dart';
import 'package:noor/adventure/wudu_preview.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/audio/speech_service.dart';
import 'package:noor/content/packs/bundled_catalog.dart';
import 'package:noor/content/packs/catalog.dart';
import 'package:noor/home/noor_lantern.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';

const _route = '/preview/adventure/w06';
final _scene = find.byType(WuduPreview);
final _drop = find.bySemanticsLabel('قطرة الماء');
final _palms = find.bySemanticsLabel('الكفّان');
final _replay = find.text('العب مجددًا');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IntegratedCatalog catalog;

  setUpAll(() async {
    catalog = (await loadBundledCatalog(rootBundle))!;
  });

  testWidgets('landscape drop outside retries, then palms splash and replay', (
    tester,
  ) async {
    _viewport(tester, const Size(1024, 640));
    final effects = <String>[];
    _recordAudio(tester, effects);
    await _start(tester, catalog: catalog);

    final drop = tester.getCenter(_drop);
    final palms = tester.getCenter(_palms);
    await tester.dragFrom(drop, const Offset(0, 135));
    await tester.pumpAndSettle();
    expect(_drop, findsOneWidget);
    expect(_replay, findsNothing);

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
    expect(find.text('رائع!'), findsOneWidget);
    expect(effects, ['retry', 'complete']);

    await tester.tap(_replay);
    await tester.pumpAndSettle();
    expect(_drop, findsOneWidget);
    expect(_palmsArt(tester).washed, isFalse);
    expect(_replay, findsNothing);
  });

  testWidgets('portrait tap alternative works at 2× text with reduced motion', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final effects = <String>[];
    _recordAudio(tester, effects);

    await _start(tester, catalog: catalog, effects: false);
    for (final target in [_drop, _palms]) {
      expect(tester.getSize(target).shortestSide, greaterThanOrEqualTo(48));
      expect(
        tester
            .getSemantics(target)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    }
    await tester.tap(_drop);
    await tester.pumpAndSettle();
    expect(find.text('المس الكفّين'), findsOneWidget);
    await tester.tap(_palms);
    await tester.pumpAndSettle();
    expect(_palmsArt(tester).washed, isTrue);
    expect(_palmsArt(tester).splash, 0);
    expect(_replay.hitTestable(), findsOneWidget);
    expect(effects, isEmpty);
    expect(tester.takeException(), isNull);
  });

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
}

PalmsPainter _palmsArt(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<PalmsPainter>()
    .single;

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

Future<void> _start(
  WidgetTester tester, {
  required IntegratedCatalog? catalog,
  bool enablePreview = true,
  bool effects = true,
  String location = _route,
}) async {
  final router = createNoorRouter(
    initialLocation: location,
    enablePreview: enablePreview,
    catalog: catalog,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(_AudioSettings(effects)),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
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
