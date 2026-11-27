import 'package:flutter/material.dart';

import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';

class AdultReviewScreen extends StatelessWidget {
  const AdultReviewScreen({super.key, required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const NoorAppBar('مراجعة البالغين'),
    body: NoorPage(
      maxWidth: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draftPilotLabel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'هذه المسودات للمراجعة من قبل البالغين فقط. لا تعرضها للأطفال.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onConfirm,
            child: const Text('أنا بالغ وأريد مراجعة المسودات'),
          ),
        ],
      ),
    ),
  );
}
