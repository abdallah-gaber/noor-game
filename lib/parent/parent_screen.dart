import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import '../review/review_history.dart';
import '../review/review_selection.dart';
import '../review/review_store.dart';

class ParentScreen extends ConsumerWidget {
  const ParentScreen({super.key, required this.curriculum});

  final Curriculum curriculum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = curriculum.progressScope;
    final progress = ref.watch(progressProvider(scope));
    final history = ref.watch(reviewHistoryFor(scope));
    final intervals = ref.watch(reviewIntervalsFor(scope));
    return Scaffold(
      appBar: const NoorAppBar('وضع الوالدين'),
      body: NoorPage(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (curriculum.isPreview) Text(curriculum.reviewLabel),
            const SizedBox(height: 16),
            if (progress.hasError || history.hasError || intervals.hasError)
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(progressProvider(scope));
                  ref.invalidate(reviewHistoryFor(scope));
                  ref.invalidate(reviewIntervalsFor(scope));
                },
                child: const Text('تعذّر فتح التقدّم. حاول مجددًا.'),
              )
            else if (progress.asData case final saved?)
              if (history.asData case final practice?)
                _ParentReport(
                  curriculum: curriculum,
                  progress: saved.value,
                  history: practice.value,
                  intervals: intervals.asData?.value ?? spacingDays,
                )
              else
                const LinearProgressIndicator(semanticsLabel: 'تحميل التدريب')
            else
              const LinearProgressIndicator(semanticsLabel: 'تحميل التقدّم'),
          ],
        ),
      ),
    );
  }
}

typedef _Area = ({String id, String label});

Iterable<_Area> _areas(LearningLesson lesson) sync* {
  final ids = {
    ...lesson.knowledgeLabels.keys,
    for (final challenge in lesson.challenges) ...challenge.knowledgeIds,
  };
  for (final (index, id) in ids.indexed) {
    yield (
      id: id,
      label: lesson.knowledgeLabels[id] ?? '${lesson.title} · ${index + 1}',
    );
  }
}

class _ParentReport extends StatelessWidget {
  const _ParentReport({
    required this.curriculum,
    required this.progress,
    required this.history,
    required this.intervals,
  });

  final Curriculum curriculum;
  final JourneyProgress progress;
  final ReviewHistory history;
  final List<int> intervals;

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    final byWorld = {
      for (final world in curriculum.units.keys)
        world: [for (final unit in curriculum.unitsFor(world)) ...unit.lessons],
    };
    final lessons = {
      for (final lessons in byWorld.values)
        for (final lesson in lessons) lesson.id: lesson,
    };
    final known = {
      for (final lesson in lessons.values)
        for (final area in _areas(lesson)) area.id: area,
    };
    final practiced = [
      for (final area in known.values)
        if (history.knowledge(area.id) case final result?)
          (area: area, result: result),
    ];
    bool isStrength(PracticeResult result) =>
        result.recentCorrect * 4 >= result.recentScored * 3 &&
        result.eventuallyCorrect == result.scored;
    final strong = practiced.where((entry) => isStrength(entry.result));
    final weaker = practiced.where((entry) => !isStrength(entry.result));
    final now = DateTime.now();
    final available = reviewCandidates(curriculum, progress);
    final suggested = <String>{
      for (final challenge in selectReview(
        available,
        history,
        intervals,
        now,
        maximum: 3,
      ))
        ...challenge.knowledgeIds,
    }.take(3);
    final recent = history.recent
        .where((row) => row.review || lessons.containsKey(row.lessonId))
        .take(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, 'التقدّم حسب العالم'),
        for (final MapEntry(key: world, value: items) in byWorld.entries)
          ExpansionTile(
            title: Text(world.title),
            subtitle: Text(
              '${locale.formatDecimal(items.where((lesson) => progress.records[lesson.id]?.completed == true).length)} من ${locale.formatDecimal(items.length)} درس مكتمل',
            ),
            children: [
              for (final lesson in items)
                ExpansionTile(
                  title: Text(lesson.title),
                  subtitle: Text(switch (progress.records[lesson.id]) {
                    LessonProgress(completed: true) => 'مكتمل',
                    LessonProgress() => 'قيد التعلّم',
                    null => 'لم يبدأ بعد',
                  }),
                  children: [
                    for (final area in _areas(lesson))
                      ListTile(
                        title: Text(area.label),
                        subtitle: Text(
                          _practiceLabel(locale, history.knowledge(area.id)),
                        ),
                      ),
                    if (lesson.sources.isEmpty)
                      const ListTile(title: Text('لا توجد مراجع لهذا الدرس.'))
                    else
                      ExpansionTile(
                        title: const Text('مراجع الدرس'),
                        subtitle: curriculum.isPreview
                            ? const Text('مراجع المسودة في انتظار التحقّق.')
                            : null,
                        children: [
                          for (final source in lesson.sources)
                            ListTile(
                              title: SelectableText(
                                source.title.isEmpty ? source.id : source.title,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    source.locator.isEmpty
                                        ? source.id
                                        : source.locator,
                                  ),
                                  if (source.url case final url?)
                                    SelectableText(
                                      url,
                                      textDirection: TextDirection.ltr,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        const SizedBox(height: 16),
        _heading(context, 'نقاط القوّة'),
        if (strong.isEmpty) const Text('ستظهر نقاط القوّة بعد التدريب.'),
        for (final entry in strong.take(4)) Text(entry.area.label),
        const SizedBox(height: 16),
        _heading(context, 'معارف تحتاج إلى مراجعة'),
        if (weaker.isEmpty)
          const Text('لا توجد معارف تحتاج للمراجعة بحسب التدريب المسجّل.'),
        for (final entry in weaker.take(4)) Text(entry.area.label),
        const SizedBox(height: 16),
        _heading(context, 'مراجعة مقترحة'),
        if (suggested.isEmpty)
          const Text('ستظهر المقترحات عند إتاحة أنشطة التدريب.'),
        for (final id in suggested)
          if (known[id] case final area?)
            ListTile(
              title: Text(area.label),
              subtitle: Text(switch (nextPractice(
                history.knowledge(id),
                intervals,
              )) {
                final DateTime due when !due.isAfter(now) => 'حان وقت مراجعتها',
                final DateTime due =>
                  'موعد المراجعة: ${locale.formatMediumDate(due)}',
                null => 'تدريب متاح',
              }),
            ),
        if (suggested.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => context.push('/review/adaptive'),
              child: const Text('فتح المراجعة المخصّصة'),
            ),
          ),
        const SizedBox(height: 16),
        _heading(context, 'النشاط الأخير'),
        if (recent.isEmpty) const Text('لا يوجد نشاط محفوظ بعد.'),
        for (final activity in recent)
          ListTile(
            title: Text(
              activity.review
                  ? (activity.lessonId.contains('/daily/')
                        ? 'تحدّي اليوم'
                        : 'مراجعة مخصّصة')
                  : lessons[activity.lessonId]!.title,
            ),
            subtitle: Text(
              activity.practicedAt == null
                  ? 'تدريب محفوظ بلا تاريخ'
                  : locale.formatMediumDate(activity.practicedAt!),
            ),
          ),
      ],
    );
  }
}

Widget _heading(BuildContext context, String title) => Semantics(
  header: true,
  child: Text(title, style: Theme.of(context).textTheme.titleLarge),
);

String _practiceLabel(MaterialLocalizations locale, PracticeResult? result) {
  if (result == null) return 'لا توجد إجابات مقيّمة بعد.';
  String fraction(int value, int total) =>
      '${locale.formatDecimal(value)} من ${locale.formatDecimal(total)}';
  return [
    'أول محاولة: ${fraction(result.firstCorrect, result.scored)}',
    'الأداء الأخير: ${fraction(result.recentCorrect, result.recentScored)}',
    'الصحيح في النهاية: ${fraction(result.eventuallyCorrect, result.scored)}',
  ].join('\n');
}
