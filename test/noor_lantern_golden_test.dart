import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/home/noor_lantern.dart';

void main() {
  testWidgets('Noor has six consistent and distinct expressions', (
    tester,
  ) async {
    const gallery = ValueKey('lantern-gallery');
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: gallery,
          child: ColoredBox(
            color: const Color(0xFFFFFBF1),
            child: SizedBox(
              width: 528,
              height: 352,
              child: Wrap(
                textDirection: TextDirection.rtl,
                children: [
                  for (final mood in NoorMood.values) NoorLantern(mood: mood),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (final mood in NoorMood.values) {
      expect(find.bySemanticsLabel(mood.label), findsOneWidget);
    }
    await expectLater(
      find.byKey(gallery),
      matchesGoldenFile('goldens/noor-expressions.png'),
    );
  });

  testWidgets('an inactive lantern never starts its entry reaction', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TickerMode(
        enabled: false,
        child: Center(
          child: NoorReaction(
            mood: NoorMood.celebrating,
            size: 120,
            playOnEntry: true,
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel(NoorMood.celebrating.label), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
