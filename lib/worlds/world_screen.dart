import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import '../home/noor_lantern.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import 'world_art.dart';

class WorldScreen extends ConsumerWidget {
  const WorldScreen({super.key, required this.world, required this.curriculum});

  final WorldId world;
  final Curriculum curriculum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = curriculum.unitsFor(world);
    final progress = units.isEmpty
        ? null
        : ref.watch(progressProvider(curriculum.progressScope));
    return Scaffold(
      appBar: NoorAppBar(world.title),
      body: NoorPage(
        maxWidth: 1000,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth >= 760;
            final view = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorldBanner(world, showCompanion: !landscape),
                if (landscape)
                  const Center(
                    child: NoorLantern(mood: NoorMood.curious, size: 124),
                  ),
              ],
            );
            final path =
                progress?.when(
                  skipLoadingOnRefresh: false,
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'جارٍ التحميل',
                    ),
                  ),
                  error: (error, stackTrace) => FilledButton(
                    onPressed: () => ref.invalidate(
                      progressProvider(curriculum.progressScope),
                    ),
                    child: const Text('تعذّر فتح الدرب. حاول مرة أخرى.'),
                  ),
                  data: (journey) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (curriculum.isPreview)
                        Text(
                          curriculum.reviewLabel,
                          style: TextStyle(color: world.ink),
                        ),
                      for (final unit in units)
                        LearningPath(
                          unit: unit,
                          completed: journey.completedIn(curriculum),
                          currentId: journey.currentFor(curriculum, unit),
                          onOpen: (id) =>
                              context.push('/worlds/${world.id}/lessons/$id'),
                        ),
                    ],
                  ),
                ) ??
                const Padding(
                  padding: EdgeInsetsDirectional.only(top: 8),
                  child: Text('الدروس قيد الإعداد.'),
                );
            return landscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: view),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: path),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [view, const SizedBox(height: 18), path],
                  );
          },
        ),
      ),
    );
  }
}

class _WorldBanner extends StatelessWidget {
  const _WorldBanner(this.world, {required this.showCompanion});

  final WorldId world;
  final bool showCompanion;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 146,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WorldArt(world),
            if (showCompanion)
              const PositionedDirectional(
                end: 12,
                bottom: 0,
                child: NoorLantern(mood: NoorMood.curious, size: 98),
              ),
          ],
        ),
      ),
    );
  }
}

class LearningPath extends StatelessWidget {
  const LearningPath({
    super.key,
    required this.unit,
    required this.completed,
    required this.currentId,
    required this.onOpen,
  });

  final LearningUnit unit;
  final Set<String> completed;
  final String? currentId;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final world = unit.world;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            unit.title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: world.ink, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        for (final (index, lesson) in unit.lessons.indexed)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: index.isOdd ? 18 : 0,
              end: index.isOdd ? 0 : 18,
              bottom: 8,
            ),
            child: _PathStop(
              world: world,
              lesson: lesson,
              state: lesson.state(completed: completed, currentId: currentId),
              onOpen: () => onOpen(lesson.id),
            ),
          ),
      ],
    );
  }
}

class _PathStop extends StatelessWidget {
  const _PathStop({
    required this.world,
    required this.lesson,
    required this.state,
    required this.onOpen,
  });

  final WorldId world;
  final LearningLesson lesson;
  final LessonState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final locked = state == LessonState.locked;
    final current = state == LessonState.current;
    final icon = switch (state) {
      LessonState.completed => Icons.check_rounded,
      LessonState.current => Icons.explore_rounded,
      LessonState.available => Icons.play_arrow_rounded,
      LessonState.locked => Icons.lock_outline_rounded,
    };
    final foreground = locked ? const Color(0xFF51544B) : world.ink;

    return Semantics(
      label: '${lesson.title}، ${state.label}',
      button: true,
      enabled: !locked,
      onTap: locked ? null : onOpen,
      excludeSemantics: true,
      child: Material(
        color: locked ? const Color(0xFFF1EFE5) : world.wash,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: current
              ? BorderSide(color: foreground, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: locked ? null : onOpen,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: current ? foreground : Colors.white,
                  foregroundColor: current ? Colors.white : foreground,
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(state.label, style: TextStyle(color: foreground)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
