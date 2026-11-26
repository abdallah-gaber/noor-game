import 'package:noor/progress/lesson_progress.dart';
import 'package:noor/progress/progress_store.dart';

class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([this.value = const JourneyProgress()]);

  JourneyProgress value;
  JourneyProgress approved = const JourneyProgress();
  bool failSave = false;

  @override
  Future<JourneyProgress> load(ProgressScope scope) async =>
      scope == ProgressScope.preview ? value : approved;

  @override
  Future<LessonProgress> save(
    ProgressScope scope,
    LessonProgress record,
  ) async {
    if (failSave) throw StateError('Progress write failed');
    final snapshot = await load(scope);
    final existing = snapshot.records[record.lessonId];
    final saved = LessonProgress(
      world: record.world,
      lessonId: record.lessonId,
      contentVersion: record.contentVersion,
      stepIndex: record.stepIndex,
      completed: record.completed || (existing?.completed ?? false),
      updatedAt: record.updatedAt,
    );
    if (scope == ProgressScope.preview) {
      value = snapshot.withRecord(saved);
    } else {
      approved = snapshot.withRecord(saved);
    }
    return saved;
  }
}
