import '../content/curriculum.dart';

enum ProgressScope {
  approved('lesson_progress'),
  preview('preview_lesson_progress');

  const ProgressScope(this.table);

  final String table;
}

extension CurriculumProgressScope on Curriculum {
  ProgressScope get progressScope =>
      isPreview ? ProgressScope.preview : ProgressScope.approved;
}

class LessonProgress {
  const LessonProgress({
    required this.world,
    required this.lessonId,
    required this.contentVersion,
    required this.stepIndex,
    required this.completed,
    required this.updatedAt,
  });

  final WorldId world;
  final String lessonId;
  final String contentVersion;
  final int stepIndex;
  final bool completed;
  final int updatedAt;

  int resumeIndex(String version, int stepCount) {
    if (contentVersion != version || stepCount <= 0) return 0;
    return stepIndex.clamp(0, stepCount - 1);
  }
}

class JourneyProgress {
  const JourneyProgress([this.records = const {}]);

  final Map<String, LessonProgress> records;

  Set<String> completedFor(Curriculum curriculum, WorldId world) => {
    if (curriculum.isPreview)
      for (final id in curriculum.previewCompletions)
        if (curriculum.lesson(world, id) != null) id,
    for (final progress in records.values)
      if (progress.world == world && progress.completed) progress.lessonId,
  };

  String? currentFor(Curriculum curriculum, LearningUnit unit) {
    final completed = completedFor(curriculum, unit.world);
    LessonProgress? latest;
    String? firstAvailable;
    for (final lesson in unit.lessons) {
      if (lesson.state(completed: completed) != LessonState.available) continue;
      firstAvailable ??= lesson.id;
      final progress = records[lesson.id];
      if (progress != null &&
          progress.contentVersion == curriculum.version &&
          (latest == null || progress.updatedAt > latest.updatedAt)) {
        latest = progress;
      }
    }
    return latest?.lessonId ?? firstAvailable;
  }

  JourneyProgress withRecord(LessonProgress record) =>
      JourneyProgress(Map.unmodifiable({...records, record.lessonId: record}));
}
