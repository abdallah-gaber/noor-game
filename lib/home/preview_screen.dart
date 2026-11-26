import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../challenges/debug_catalog.dart';

import '../design_system/noor_layout.dart';
import 'noor_lantern.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NoorAppBar('معاينة المطوّر'),
      body: NoorPage(
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
