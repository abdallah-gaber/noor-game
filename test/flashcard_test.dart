import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/app/noor_app.dart';
import 'package:noor/audio/speech_service.dart';
import 'package:noor/challenges/flashcard.dart';
import 'package:noor/settings/settings_controller.dart';
import 'package:noor/settings/settings_store.dart';

void main() {
  test('flashcards have stable knowledge links and no scored answer', () {
    final card = Flashcard.fromJson(const {
      'schema': 1,
      'id': 'card-1',
      'type': 'flashcard',
      'knowledgeIds': ['geometry.circle'],
      'prompt': 'شكل مستدير',
      'answer': 'دائرة',
    });
    expect(card.isScored, isFalse);
    expect(Flashcard.fromJson(card.toJson()).knowledgeIds, ['geometry.circle']);
    expect(
      () => Flashcard.fromJson({...card.toJson(), 'correctOptionId': 'x'}),
      throwsFormatException,
    );
  });

  testWidgets(
    'flashcard conceals the answer, stops speech on reveal and records unscored recall',
    (tester) async {
      final speech = await _open(tester, 'shapes-flashcard');
      expect(find.text('دائرة.'), findsNothing);
      await tester.tap(find.text('استمع'));
      await tester.pump();
      expect(speech.text, contains('فكّر في الإجابة'));
      expect(speech.text, isNot(contains('دائرة.')));
      await tester.tap(find.text('اكشف الإجابة'));
      await tester.pumpAndSettle();
      expect(speech.stops, 1);
      expect(find.text('دائرة.'), findsOneWidget);
      await tester.tap(find.text('استمع'));
      await tester.pump();
      expect(speech.text, contains('دائرة.'));
      await tester.tap(find.text('أريد المراجعة'));
      await tester.pumpAndSettle();
      expect(speech.stops, 2);
      expect(find.text('يمكنك المراجعة لاحقًا.'), findsOneWidget);
    },
  );

  testWidgets(
    'choice sequentially reads instructions, prompt and choices, then explanation',
    (tester) async {
      final speech = await _open(tester, 'shapes-choice');
      await tester.tap(find.text('استمع'));
      await tester.pump();
      for (final word in [
        'اختر إجابة واحدة',
        'أيّ شكل',
        'دائرة',
        'مثلّث',
        'مربّع',
      ]) {
        expect(speech.text, contains(word));
      }
      await tester.tap(find.text('مثلّث'));
      await tester.pumpAndSettle();
      expect(speech.stops, 1);
      await tester.tap(find.text('استمع'));
      await tester.pump();
      expect(speech.text, contains('المثلّث له ثلاث زوايا.'));
    },
  );
}

Future<_Speech> _open(WidgetTester tester, String id) async {
  final speech = _Speech();
  final router = createNoorRouter(initialLocation: '/preview/challenges/$id');
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(_Settings()),
        speechServiceProvider.overrideWithValue(speech),
      ],
      child: NoorApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
  return speech;
}

class _Settings implements SettingsStore {
  @override
  Future<AudioPreferences> load() async => const AudioPreferences(speech: true);
  @override
  Future<void> save(AudioPreferences preferences) async {}
}

class _Speech implements SpeechService {
  String? text;
  int stops = 0;
  Completer<bool>? pending;
  @override
  Future<bool> read(String text) {
    expect(pending, isNull);
    this.text = text;
    return (pending = Completer<bool>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    pending?.complete(false);
    pending = null;
  }
}
