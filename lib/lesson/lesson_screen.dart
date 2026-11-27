import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../audio/pilot_effects.dart';
import '../audio/speech_control.dart';
import '../challenges/arrangement.dart';
import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import '../home/noor_lantern.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import '../worlds/world_art.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.world,
    required this.lesson,
    required this.curriculum,
  });

  final WorldId world;
  final LearningLesson lesson;
  final Curriculum curriculum;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _saving = false;
  bool _finished = false;

  Future<void> _save(int index, {bool completed = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(progressProvider(widget.curriculum.progressScope).notifier)
          .saveStep(
            world: widget.world,
            lesson: widget.lesson,
            contentVersion: widget.curriculum.lessonVersion(widget.lesson),
            index: index,
            completed: completed,
          );
      if (!mounted) return;
      if (completed) setState(() => _finished = true);
      _effect(completed ? PilotEffect.complete : PilotEffect.tap);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ الدرس. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _effect(PilotEffect effect) {
    if (widget.curriculum.isDraftPilot) {
      ref.read(pilotEffectsProvider).play(effect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(
      progressProvider(widget.curriculum.progressScope),
    );
    final lesson = widget.lesson;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: NoorAppBar(lesson.title),
        body: progress.when(
          loading: () => const Center(
            child: CircularProgressIndicator(semanticsLabel: 'جارٍ التحميل'),
          ),
          error: (error, stackTrace) => NoorPage(
            maxWidth: 640,
            child: FilledButton(
              onPressed: () => ref.invalidate(
                progressProvider(widget.curriculum.progressScope),
              ),
              child: const Text('تعذّر فتح الدرس. حاول مرة أخرى.'),
            ),
          ),
          data: (journey) {
            final index =
                journey.records[lesson.id]?.resumeIndex(
                  widget.curriculum.lessonVersion(lesson),
                  lesson.steps.length,
                ) ??
                0;
            return NoorPage(
              key: ValueKey((index, _finished)),
              maxWidth: 680,
              child: _content(context, index),
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, int index) {
    final lesson = widget.lesson;
    final world = widget.world;
    final step = lesson.steps[index];
    final last = index == lesson.steps.length - 1;
    final hasChallenges = lesson.challenges.isNotEmpty;
    final localizations = MaterialLocalizations.of(context);
    final current = localizations.formatDecimal(index + 1);
    final total = localizations.formatDecimal(lesson.steps.length);
    final indicator = 'الخطوة $current من $total';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.curriculum.isPreview)
          Text(
            widget.curriculum.reviewLabel,
            style: TextStyle(color: world.ink),
          ),
        if (!_finished) ...[
          if (widget.curriculum.isDraftPilot)
            for (final activity in lesson.challenges.whereType<Arrangement>())
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          _effect(PilotEffect.tap);
                          context.push(
                            '/worlds/${world.id}/lessons/${lesson.id}/practice/${activity.id}',
                          );
                        },
                  child: Text('جرّب ${activity.kind.label}'),
                ),
              ),
          const SizedBox(height: 8),
          Text(indicator, style: TextStyle(color: world.ink)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            backgroundColor: world.wash,
            color: world.ink,
            value: (index + 1) / lesson.steps.length,
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: 18),
        ],
        _LessonPanel(
          world: world,
          title: _finished ? 'أحسنت!' : step.title,
          text: _finished ? 'أكملتَ هذا الدرس.' : step.text,
          icon: _finished ? Icons.flag_rounded : _pictureIcon(step.picture),
          mood: _finished
              ? NoorMood.celebrating
              : index == 0
              ? NoorMood.thinking
              : NoorMood.encouraging,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            if (_finished)
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('إلى الدرب'),
              )
            else ...[
              FilledButton(
                onPressed: _saving
                    ? null
                    : last && hasChallenges
                    ? () {
                        _effect(PilotEffect.tap);
                        context.push(
                          '/worlds/${world.id}/lessons/${lesson.id}/play',
                        );
                      }
                    : () => _save(last ? 0 : index + 1, completed: last),
                child: Text(
                  last
                      ? (hasChallenges ? 'إلى التحدّيات' : 'أنهِ الدرس')
                      : 'التالي',
                ),
              ),
              if (index > 0)
                TextButton(
                  onPressed: _saving ? null : () => _save(index - 1),
                  child: const Text('السابق'),
                ),
            ],
          ],
        ),
        if (!_finished) SpeechControl(text: step.text),
      ],
    );
  }

  IconData _pictureIcon(LessonPicture picture) => switch (picture) {
    LessonPicture.sky => Icons.cloud_outlined,
    LessonPicture.palette => Icons.palette_outlined,
    LessonPicture.shapes => Icons.change_history_rounded,
    LessonPicture.trail => Icons.route_outlined,
  };
}

class _LessonPanel extends StatelessWidget {
  const _LessonPanel({
    required this.world,
    required this.title,
    required this.text,
    required this.icon,
    required this.mood,
  });

  final WorldId world;
  final String title;
  final String text;
  final IconData icon;
  final NoorMood mood;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: world.wash,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final picture = ExcludeSemantics(
              child: CircleAvatar(
                radius: 30,
                foregroundColor: world.ink,
                backgroundColor: Colors.white,
                child: Icon(icon, size: 34),
              ),
            );
            final lantern = mood == NoorMood.celebrating
                ? const NoorReaction(
                    mood: NoorMood.celebrating,
                    size: 128,
                    playOnEntry: true,
                  )
                : NoorLantern(mood: mood, size: 128);
            final words = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: world.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(text, style: TextStyle(color: world.ink, fontSize: 21)),
              ],
            );

            if (constraints.maxWidth >= 450) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [picture, const SizedBox(height: 16), words],
                    ),
                  ),
                  const SizedBox(width: 20),
                  lantern,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    picture,
                    Flexible(child: lantern),
                  ],
                ),
                words,
              ],
            );
          },
        ),
      ),
    );
  }
}
