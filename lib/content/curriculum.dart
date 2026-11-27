import 'package:flutter/foundation.dart';

import '../challenges/challenge_definition.dart';
import '../challenges/debug_catalog.dart';

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

enum LessonPicture { sky, palette, shapes, trail }

class LessonStep {
  const LessonStep(this.title, this.text, this.picture);

  final String title;
  final String text;
  final LessonPicture picture;
}

class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.title,
    required this.steps,
    this.prerequisiteId,
    this.prerequisiteIds = const [],
    this.contentRevision,
    this.challenges = const [],
  });

  final String id;
  final String title;
  final List<LessonStep> steps;
  final List<ChallengeDefinition> challenges;
  final String? prerequisiteId;
  final List<String> prerequisiteIds;
  final String? contentRevision;

  LessonState state({required Set<String> completed, String? currentId}) {
    if (completed.contains(id)) return LessonState.completed;
    if ((prerequisiteId != null && !completed.contains(prerequisiteId)) ||
        !prerequisiteIds.every(completed.contains)) {
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
  const Curriculum({
    required this.version,
    this.isPreview = false,
    this.units = const {},
    this.previewCompletions = const {},
  });

  final String version;
  final bool isPreview;
  final Map<WorldId, List<LearningUnit>> units;
  final Set<String> previewCompletions;

  String lessonVersion(LearningLesson lesson) =>
      lesson.contentRevision ?? version;

  List<LearningUnit> unitsFor(WorldId world) => units[world] ?? const [];

  LearningLesson? lesson(WorldId world, String? lessonId) {
    for (final unit in unitsFor(world)) {
      for (final lesson in unit.lessons) {
        if (lesson.id == lessonId) return lesson;
      }
    }
    return null;
  }
}

Curriculum loadCurriculum({bool enablePreview = true}) {
  if (!kDebugMode || !enablePreview) return const Curriculum(version: '0');

  return Curriculum(
    version: 'preview-1',
    isPreview: true,
    previewCompletions: Set.unmodifiable(
      WorldId.values.map((world) => '${world.id}-first'),
    ),
    units: Map.unmodifiable({
      for (final world in WorldId.values)
        world: List<LearningUnit>.unmodifiable([_fixtureUnit(world)]),
    }),
  );
}

LearningUnit _fixtureUnit(WorldId world) {
  final prefix = world.id;
  return LearningUnit(
    id: '$prefix-trail',
    world: world,
    title: 'درب الاكتشاف',
    lessons: List.unmodifiable([
      LearningLesson(
        id: '$prefix-first',
        title: 'أولى الخطوات',
        steps: const [
          LessonStep(
            'لِنبدأ!',
            'تأمّل السماء. ماذا ترى فيها؟',
            LessonPicture.sky,
          ),
          LessonStep(
            'وقتُ الملاحظة',
            'انظر حولك واختر شيئًا تحبّ لونه.',
            LessonPicture.palette,
          ),
        ],
      ),
      LearningLesson(
        id: '$prefix-colors',
        title: 'ألوانٌ حولنا',
        prerequisiteId: '$prefix-first',
        steps: const [
          LessonStep(
            'لونُ السماء',
            'قد ترى لونًا أزرق عندما تنظر إلى السماء.',
            LessonPicture.sky,
          ),
          LessonStep(
            'لِنبحث عن لون',
            'ابحث حولك عن شيء أزرق.',
            LessonPicture.palette,
          ),
          LessonStep(
            'ألوانٌ أخرى',
            'اختر لونًا آخر واذكر شيئًا بلونه.',
            LessonPicture.palette,
          ),
        ],
      ),
      LearningLesson(
        id: '$prefix-shapes',
        title: 'لعبة الأشكال',
        prerequisiteId: '$prefix-first',
        steps: const [
          LessonStep(
            'أشكالٌ حولنا',
            'تأمّل صورة المثلّث.',
            LessonPicture.shapes,
          ),
          LessonStep(
            'أين المثلّث؟',
            'ابحث حولك عن شكل له ثلاث زوايا.',
            LessonPicture.shapes,
          ),
        ],
      ),
      if (world == WorldId.iman)
        LearningLesson(
          id: '$prefix-activities',
          title: 'تحدّيات الأشكال',
          prerequisiteId: '$prefix-first',
          steps: const [
            LessonStep(
              'لِنستعدّ',
              'تأمّل الأشكال وعدّ زواياها.',
              LessonPicture.shapes,
            ),
          ],
          challenges: List.unmodifiable(debugChallenges.values),
        ),
      if (world == WorldId.iman)
        LearningLesson(
          id: '$prefix-activities-next',
          title: 'خطوة بعد التحدّيات',
          prerequisiteId: '$prefix-activities',
          steps: const [
            LessonStep('أكمل الدرب', 'اختر شكلًا وارسمه.', LessonPicture.trail),
          ],
        ),
      LearningLesson(
        id: '$prefix-end',
        title: 'نهاية الدرب',
        prerequisiteId: '$prefix-colors',
        steps: const [
          LessonStep(
            'تذكّر رحلتك',
            'تذكّر لونًا أو شكلًا لاحظتَه اليوم.',
            LessonPicture.trail,
          ),
          LessonStep(
            'أكمل رحلتك',
            'اختر شيئًا جديدًا تتأمّله في المرّة القادمة.',
            LessonPicture.sky,
          ),
        ],
      ),
    ]),
  );
}

const previewLabel = 'معاينة تجريبية للمطوّر';
