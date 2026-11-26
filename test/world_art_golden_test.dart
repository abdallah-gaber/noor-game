import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/content/curriculum.dart';
import 'package:noor/worlds/world_art.dart';

void main() {
  testWidgets('the four painted environments keep their distinct silhouettes', (
    tester,
  ) async {
    const gallery = ValueKey('world-art');
    await tester.pumpWidget(
      const Center(
        child: RepaintBoundary(
          key: gallery,
          child: SizedBox(
            width: 720,
            height: 280,
            child: Column(
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    SizedBox(
                      width: 360,
                      height: 140,
                      child: WorldArt(WorldId.iman),
                    ),
                    SizedBox(
                      width: 360,
                      height: 140,
                      child: WorldArt(WorldId.ibadah),
                    ),
                  ],
                ),
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    SizedBox(
                      width: 360,
                      height: 140,
                      child: WorldArt(WorldId.seerah),
                    ),
                    SizedBox(
                      width: 360,
                      height: 140,
                      child: WorldArt(WorldId.exemplars),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(gallery),
      matchesGoldenFile('goldens/world-environments.png'),
    );
  });
}
