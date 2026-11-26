import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/progress/progress_store.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';

import 'progress_test_support.dart';

void main() {
  for (final (viewport, columns) in [
    (const Size(390, 844), 1),
    (const Size(600, 960), 2),
    (const Size(800, 1280), 2),
    (const Size(1024, 768), 2),
  ]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'map, path and player fit ${viewport.width} × ${viewport.height} at $scale',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final router = createNoorRouter();
          addTearDown(router.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                progressStoreProvider.overrideWithValue(MemoryProgressStore()),
                settingsStoreProvider.overrideWithValue(_SpeechDisabled()),
              ],
              child: NoorApp(router: router),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(ValueKey('world-columns-$columns')),
            findsOneWidget,
          );
          final firstWorld = find.text(WorldId.iman.title);
          final secondWorld = find.text(WorldId.ibadah.title);
          if (columns == 2) {
            expect(
              tester.getCenter(firstWorld).dx,
              greaterThan(tester.getCenter(secondWorld).dx),
            );
          } else {
            expect(
              tester.getCenter(firstWorld).dy,
              lessThan(tester.getCenter(secondWorld).dy),
            );
          }
          await _guidelines(tester);
          for (final world in WorldId.values.reversed) {
            final item = find.text(world.title);
            await tester.ensureVisible(item);
            await tester.pumpAndSettle();
            expect(item.hitTestable(), findsOneWidget);
          }

          await _tap(tester, firstWorld);
          expect(find.text('درب الاكتشاف'), findsOneWidget);
          final locked = find.bySemanticsLabel('نهاية الدرب، مغلق');
          final current = find.bySemanticsLabel('ألوانٌ حولنا، درسُكَ الحالي');
          await _guidelines(tester);
          await tester.ensureVisible(locked);
          await tester.pumpAndSettle();
          expect(locked.hitTestable(), findsOneWidget);
          await _tap(tester, current);

          final next = find.widgetWithText(FilledButton, 'التالي');
          final nextContext = tester.element(next);
          expect(Directionality.of(nextContext), TextDirection.rtl);
          expect(
            MediaQuery.textScalerOf(nextContext).scale(10),
            closeTo(10 * scale, 0.01),
          );
          expect(tester.getSize(next).height, greaterThanOrEqualTo(48));
          await _guidelines(tester);
          await _tap(tester, next);
          expect(find.text('لِنبحث عن لون'), findsOneWidget);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          expect(find.text('درب الاكتشاف'), findsOneWidget);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          expect(find.text('اختر عالمًا'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _guidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

class _SpeechDisabled implements SettingsStore {
  @override
  Future<AudioPreferences> load() async => const AudioPreferences();

  @override
  Future<void> save(AudioPreferences preferences) async {}
}
