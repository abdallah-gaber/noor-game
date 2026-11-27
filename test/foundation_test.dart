import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/design_system/noor_layout.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';

const _settingsLink = 'الإعدادات';
const _greeting = 'أهلًا يا نور!';
const _speech = 'القراءة الصوتية';
const _effects = 'المؤثّرات الصوتية';

void main() {
  test('breakpoints follow the 600 and 840 logical-pixel boundaries', () {
    expect(NoorWidth.of(599), NoorWidth.compact);
    expect(NoorWidth.of(600), NoorWidth.medium);
    expect(NoorWidth.of(839), NoorWidth.medium);
    expect(NoorWidth.of(840), NoorWidth.expanded);
  });

  for (final (size, layout) in [
    (const Size(390, 844), NoorWidth.compact),
    (const Size(600, 960), NoorWidth.medium),
    (const Size(800, 1280), NoorWidth.medium),
    (const Size(1024, 768), NoorWidth.expanded),
  ]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('${size.width}×${size.height} at scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _start(tester);

        final expectedColumns = layout == NoorWidth.compact ? 1 : 2;
        expect(
          find.byKey(ValueKey('world-columns-$expectedColumns')),
          findsOneWidget,
        );
        final greeting = find.widgetWithText(FilledButton, _greeting);
        final settings = find.byTooltip(_settingsLink);
        final context = tester.element(greeting);
        expect(Directionality.of(context), TextDirection.rtl);
        expect(Localizations.localeOf(context), const Locale('ar'));
        expect(
          MediaQuery.textScalerOf(context).scale(10),
          closeTo(10 * scale, 0.01),
        );

        _expectTouchTarget(tester, greeting);
        _expectTouchTarget(tester, settings);
        await tester.ensureVisible(settings);
        await tester.tap(settings);
        await tester.pumpAndSettle();

        final speech = find.widgetWithText(SwitchListTile, _speech);
        final effects = find.widgetWithText(SwitchListTile, _effects);
        _expectTouchTarget(tester, speech);
        _expectTouchTarget(tester, effects);
        await tester.ensureVisible(effects);
        expect(effects.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(greeting, findsOneWidget);
      });
    }
  }

  testWidgets('horizontal safe insets and accessible Android targets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(848, 480);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(left: 24, right: 16);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _start(tester);

    final settings = find.byTooltip(_settingsLink);
    expect(find.byKey(const ValueKey('world-columns-2')), findsOneWidget);
    final bounds = tester.getRect(settings);
    expect(bounds.left, greaterThanOrEqualTo(24));
    expect(bounds.right, lessThanOrEqualTo(832));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.ensureVisible(settings);
    await tester.tap(settings);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  for (final reduceMotion in [false, true]) {
    testWidgets('Noor greets with reduce motion = $reduceMotion', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduceMotion);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _start(tester);

      final resting = find.bySemanticsLabel('نور يبتسم');
      final happy = find.bySemanticsLabel('نور سعيد');
      final origin = tester.getCenter(resting);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.tap(find.text(_greeting));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      if (reduceMotion) {
        expect(tester.getCenter(happy), origin);
        expect(tester.binding.transientCallbackCount, 0);
      } else {
        expect(tester.getCenter(happy).dy, lessThan(origin.dy));
      }
      await tester.pumpAndSettle();
      expect(tester.getCenter(happy), origin);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  testWidgets('settings defaults, commit, failed save and retry', (
    tester,
  ) async {
    final store = _MemorySettingsStore();
    await _start(tester, store: store, location: '/settings');
    final speech = find.widgetWithText(SwitchListTile, _speech);
    final effects = find.widgetWithText(SwitchListTile, _effects);

    bool value(Finder finder) => tester.widget<SwitchListTile>(finder).value;
    expect(value(speech), isFalse);
    expect(value(effects), isTrue);

    final pendingSave = store.pendingSave = Completer<void>();
    await tester.tap(speech);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(effects).onChanged, isNull);
    expect(value(speech), isFalse);
    pendingSave.complete();
    await tester.pumpAndSettle();
    expect(value(speech), isTrue);
    expect(value(effects), isTrue);

    store.failSave = true;
    await tester.tap(effects);
    await tester.pumpAndSettle();
    expect(find.text('تعذّر حفظ الإعدادات. حاول مرة أخرى.'), findsOneWidget);
    expect(value(effects), isTrue);

    store.failSave = false;
    await tester.tap(effects);
    await tester.pumpAndSettle();
    expect(store.saved.speech, isTrue);
    expect(store.saved.effects, isFalse);
    expect(value(effects), isFalse);
    await _start(tester, store: store, location: '/settings');
    expect(value(effects), isFalse);
  });

  testWidgets('a failed load can be retried from settings', (tester) async {
    final store = _MemorySettingsStore()..failLoad = true;
    await _start(tester, location: '/settings', store: store);

    expect(find.text('تعذّر فتح الإعدادات.'), findsOneWidget);
    store.failLoad = false;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SwitchListTile, _speech), findsOneWidget);
  });

  testWidgets('debug preview is labeled and supports going back', (
    tester,
  ) async {
    await _start(tester);
    final preview = find.text('معاينة المطوّر');
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.textContaining('محتوى تجريبي للمطوّر فقط'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(_greeting), findsOneWidget);
  });

  for (final location in ['/preview', '/unrecognized']) {
    testWidgets('public routing redirects $location to home', (tester) async {
      await _start(tester, location: location, enablePreview: false);
      expect(find.text(_greeting), findsOneWidget);
      expect(find.textContaining('المطوّر'), findsNothing);
    });
  }
}

Future<void> _start(
  WidgetTester tester, {
  _MemorySettingsStore? store,
  String? location,
  bool enablePreview = true,
}) async {
  final router = createNoorRouter(
    initialLocation: location,
    enablePreview: enablePreview,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(
          store ?? _MemorySettingsStore(),
        ),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectTouchTarget(WidgetTester tester, Finder finder) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
}

class _MemorySettingsStore implements SettingsStore {
  AudioPreferences saved = const AudioPreferences();
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? pendingSave;

  @override
  Future<AudioPreferences> load() async {
    if (failLoad) throw StateError('Read failed');
    return saved;
  }

  @override
  Future<void> save(AudioPreferences preferences) async {
    if (failSave) throw StateError('Write failed');
    await pendingSave?.future;
    saved = preferences;
  }
}
