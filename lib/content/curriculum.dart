import 'package:flutter/foundation.dart';

enum WorldId {
  iman('iman', 'عالم الإيمان'),
  ibadah('ibadah', 'عالم العبادة'),
  seerah('seerah', 'عالم السيرة'),
  exemplars('exemplars', 'عالم القدوات');

  const WorldId(this.id, this.title);

  final String id;
  final String title;

  static WorldId? fromId(String? id) {
    for (final world in values) {
      if (world.id == id) return world;
    }
    return null;
  }
}

enum LessonState {
  completed('مكتمل'),
  current('درسُكَ الحالي'),
  available('متاح'),
  locked('مغلق');

  const LessonState(this.label);

  final String label;
}

class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.title,
    this.prerequisiteId,
  });

  final String id;
  final String title;
  final String? prerequisiteId;

  LessonState state({required Set<String> completed, String? currentId}) {
    if (completed.contains(id)) return LessonState.completed;
    if (prerequisiteId case final requiredId?
        when !completed.contains(requiredId)) {
      return LessonState.locked;
    }
    return id == currentId ? LessonState.current : LessonState.available;
  }
}

class LearningUnit {
  const LearningUnit({
    required this.id,
    required this.world,
    required this.title,
    required this.lessons,
  });

  final String id;
  final WorldId world;
  final String title;
  final List<LearningLesson> lessons;
}

class Curriculum {
  const Curriculum({required this.version, this.units = const {}});

  final String version;
  final Map<WorldId, LearningUnit> units;
  bool get isPreview => units.isNotEmpty;

  LearningLesson? lesson(WorldId world, String? lessonId) {
    for (final lesson in units[world]?.lessons ?? const <LearningLesson>[]) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }
}

Curriculum loadCurriculum({bool enablePreview = true}) {
  if (!kDebugMode || !enablePreview) return const Curriculum(version: '0');

  final units = <WorldId, LearningUnit>{};
  for (final world in WorldId.values) {
    final prefix = world.id;
    units[world] = LearningUnit(
      id: '$prefix-trail',
      world: world,
      title: 'درب الاكتشاف',
      lessons: [
        LearningLesson(id: '$prefix-first', title: 'أولى الخطوات'),
        LearningLesson(
          id: '$prefix-colors',
          title: 'ألوانٌ حولنا',
          prerequisiteId: '$prefix-first',
        ),
        LearningLesson(
          id: '$prefix-shapes',
          title: 'لعبة الأشكال',
          prerequisiteId: '$prefix-first',
        ),
        LearningLesson(
          id: '$prefix-end',
          title: 'نهاية الدرب',
          prerequisiteId: '$prefix-colors',
        ),
      ],
    );
  }
  return Curriculum(version: 'preview-1', units: Map.unmodifiable(units));
}

const previewLabel = 'معاينة تجريبية للمطوّر';
