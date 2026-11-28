import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../adventure/worship_adventure_map.dart';
import '../challenges/debug_catalog.dart';

import '../design_system/noor_layout.dart';
import 'noor_lantern.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, this.showWudu = false});

  final bool showWudu;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NoorAppBar('معاينة المطوّر'),
      body: NoorPage(
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showWudu) ...[
              TextButton.icon(
                onPressed: () => context.push(worshipMapPath),
                icon: const Icon(Icons.map_outlined),
                label: const Text('خريطة عالم العبادة'),
              ),
              TextButton.icon(
                onPressed: () => context.push('/preview/adventure/w06'),
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('معاينة مغامرة الوضوء'),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('/preview/adventure/w06/challenge'),
                icon: const Icon(Icons.extension_outlined),
                label: const Text('معاينة تحدّي الوضوء'),
              ),
            ],
            const Text('محتوى تجريبي للمطوّر فقط: هذه عيّنة لواجهة التطبيق.'),
            Wrap(
              spacing: 8,
              children: [
                for (final (index, label) in [
                  'اختيار من متعدد',
                  'صح أو خطأ',
                  'بطاقة تذكّر',
                  'تطابق',
                  'ترتيب',
                ].indexed)
                  TextButton(
                    onPressed: () => context.push(
                      '/preview/challenges/${challengePreviewIds[index]}',
                    ),
                    child: Text(label),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final mood in NoorMood.values)
                  SizedBox(
                    width: 156,
                    child: Semantics(
                      label: mood.label,
                      excludeSemantics: true,
                      child: Column(
                        children: [
                          NoorLantern(mood: mood, size: 120),
                          Text(mood.label, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
