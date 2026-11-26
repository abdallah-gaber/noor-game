import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';

class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([this.value = const JourneyProgress()]);

  JourneyProgress value;
  bool failSave = false;

  @override
  Future<JourneyProgress> load() async => value;

  @override
  Future<LessonProgress> save(LessonProgress record) async {
    if (failSave) throw StateError('Progress write failed');
    final existing = value.records[record.lessonId];
    final saved = LessonProgress(
      world: record.world,
      lessonId: record.lessonId,
      contentVersion: record.contentVersion,
      stepIndex: record.stepIndex,
      completed: record.completed || (existing?.completed ?? false),
      updatedAt: record.updatedAt,
    );
    value = value.withRecord(saved);
    return saved;
  }
}
