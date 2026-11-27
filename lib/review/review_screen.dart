import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import 'review_selection.dart';
import 'review_store.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.curriculum});

  final Curriculum curriculum;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _saving = false;

  Future<void> _setIntervals(Set<int> days) async {
    setState(() => _saving = true);
    try {
      await ref.read(reviewStoreProvider).setIntervals(days);
      if (mounted) ref.invalidate(reviewIntervalsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ فترات المراجعة.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final intervals = ref.watch(reviewIntervalsProvider);
    final number = MaterialLocalizations.of(context).formatDecimal;
    return Scaffold(
      appBar: const NoorAppBar('المراجعة'),
      body: NoorPage(
        maxWidth: 680,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.curriculum.reviewLabel),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => context.push('/review/adaptive'),
                  child: const Text('مراجعة مخصّصة'),
                ),
                OutlinedButton(
                  onPressed: () => context.push('/review/daily'),
                  child: const Text('تحدّي اليوم'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'فترات المراجعة بالأيام',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            intervals.when(
              data: (days) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in spacingDays)
                    FilterChip(
                      label: Text(number(day)),
                      selected: days.contains(day),
                      onSelected:
                          _saving || (days.length == 1 && days.contains(day))
                          ? null
                          : (selected) => _setIntervals(
                              selected ? {...days, day} : {...days}
                                ..remove(day),
                            ),
                    ),
                ],
              ),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(reviewIntervalsProvider),
                child: const Text('حاول فتح فترات المراجعة مجددًا'),
              ),
              loading: () => const LinearProgressIndicator(
                semanticsLabel: 'تحميل الفترات',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
