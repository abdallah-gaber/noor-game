import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/audio/speech_service.dart';
import 'package:noor/home/noor_lantern.dart';
import 'package:noor/progress/progress_store.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';

import 'progress_test_support.dart';

const _firstText = 'قد ترى لونًا أزرق عندما تنظر إلى السماء.';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('speech is disabled until enabled in local settings', (
    tester,
  ) async {
    final service = _Speech();
    await _start(tester, service, enabled: false);
    expect(find.text(_firstText), findsOneWidget);
    final disabled = find.ancestor(
      of: find.text('القراءة متوقّفة'),
      matching: find.byWidgetPredicate((widget) => widget is TextButton),
    );
    expect(tester.widget<TextButton>(disabled).onPressed, isNull);
    expect(service.reads, isEmpty);
  });

  testWidgets('no offline voice keeps the lesson text and announces fallback', (
    tester,
  ) async {
    final service = _Speech(immediateResult: false);
    await _start(tester, service);
    await _tap(tester, 'استمع');
    expect(service.reads, [_firstText]);
    expect(find.text(_firstText), findsOneWidget);
    expect(find.text('الصوت غير متاح. اقرأ النص هنا.'), findsOneWidget);
  });

  testWidgets('speech stops on tap, next step and leaving the lesson', (
    tester,
  ) async {
    final service = _Speech();
    await _start(tester, service);
    expect(find.bySemanticsLabel(NoorMood.thinking.label), findsOneWidget);
    await _tap(tester, 'استمع');
    expect(find.text('أوقف القراءة'), findsOneWidget);
    await _tap(tester, 'أوقف القراءة');
    expect(service.stops, 1);
    expect(find.text('الصوت غير متاح. اقرأ النص هنا.'), findsNothing);

    await _tap(tester, 'استمع');
    await _tap(tester, 'التالي');
    expect(service.stops, 2);
    expect(find.bySemanticsLabel(NoorMood.encouraging.label), findsOneWidget);
    await _tap(tester, 'استمع');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(service.stops, 3);
  });

  test(
    'missing native speech channel resolves to a graceful fallback',
    () async {
      final messenger = binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(PlatformSpeech.channel, (call) async {
        throw MissingPluginException();
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(PlatformSpeech.channel, null),
      );
      const service = PlatformSpeech();
      expect(await service.read(_firstText), isFalse);
      await service.stop();
    },
  );

  test('native method contract forwards the requested text', () async {
    final messenger = binding.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(PlatformSpeech.channel, (call) async {
      calls.add(call);
      return call.method == 'read' ? true : null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(PlatformSpeech.channel, null),
    );
    const service = PlatformSpeech();
    expect(await service.read(_firstText), isTrue);
    await service.stop();
    expect(calls.map((call) => call.method), ['read', 'stop']);
    expect(calls.first.arguments, _firstText);
  });
}

Future<void> _start(
  WidgetTester tester,
  _Speech speech, {
  bool enabled = true,
}) async {
  final router = createNoorRouter(
    initialLocation: '/worlds/iman/lessons/iman-colors',
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(MemoryProgressStore()),
        settingsStoreProvider.overrideWithValue(_Settings(enabled)),
        speechServiceProvider.overrideWithValue(speech),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _Settings implements SettingsStore {
  _Settings(this.speech);

  final bool speech;

  @override
  Future<AudioPreferences> load() async => AudioPreferences(speech: speech);

  @override
  Future<void> save(AudioPreferences preferences) async {}
}

class _Speech implements SpeechService {
  _Speech({this.immediateResult});

  final bool? immediateResult;
  final reads = <String>[];
  Completer<bool>? _pending;
  int stops = 0;

  @override
  Future<bool> read(String text) async {
    reads.add(text);
    if (immediateResult case final result?) return result;
    return (_pending = Completer<bool>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    _pending?.complete(false);
    _pending = null;
  }
}
