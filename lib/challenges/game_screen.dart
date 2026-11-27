import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../audio/pilot_effects.dart';
import '../audio/speech_control.dart';
import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import '../home/noor_lantern.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import '../progress/reward_store.dart';
import 'arrangement.dart';
import 'arrangement_view.dart';
import 'flashcard.dart';
import 'flashcard_view.dart';
import 'game_session.dart';
import 'game_store.dart';
import 'question_view.dart';
import 'scored_question.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.world,
    required this.lesson,
    required this.curriculum,
  });

  final WorldId world;
  final LearningLesson lesson;
  final Curriculum curriculum;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final _plan = GamePlan(
    widget.curriculum.lessonVersion(widget.lesson),
    widget.lesson.challenges,
    compatibleDefinitionDigest: widget.lesson.contentRevision,
  );
  GameSession? _session;
  bool _busy = true;
  bool _error = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open({String? replayOf}) async {
    try {
      final random = Random.secure();
      final id =
          '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 30)}';
      final session = await ref
          .read(gameStoreProvider)
          .open(
            widget.curriculum.progressScope,
            widget.lesson.id,
            GameSession.start(id, _plan, random),
            replayOf: replayOf,
          );
      if (!mounted) return;
      setState(() {
        _session = session;
        _error = false;
        _revealed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(GameSession? next) async {
    if (_busy || next == null) return;
    setState(() => _busy = true);
    try {
      final scope = widget.curriculum.progressScope;
      await ref
          .read(gameStoreProvider)
          .save(scope, widget.world, widget.lesson.id, next);
      if (!mounted) return;
      if (next.finished) {
        ref.invalidate(progressProvider(scope));
        if (widget.curriculum.isPreview) ref.invalidate(previewRewardsProvider);
      }
      _effect(
        next.finished
            ? PilotEffect.complete
            : switch (next.feedback?.correct) {
                true => PilotEffect.correct,
                false => PilotEffect.retry,
                null => PilotEffect.tap,
              },
      );
      setState(() {
        if (_session?.cursor != next.cursor) _revealed = false;
        _session = next;
        _error = false;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _effect(PilotEffect effect) {
    if (widget.curriculum.isDraftPilot) {
      ref.read(pilotEffectsProvider).play(effect);
    }
  }

  void _retryOpen({String? replayOf}) {
    if (_busy) return;
    setState(() => _busy = true);
    _open(replayOf: replayOf);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: const NoorAppBar('التحدّيات'),
        body: NoorPage(
          key: ValueKey((session?.id, session?.cursor)),
          maxWidth: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.curriculum.isPreview)
                Text(widget.curriculum.reviewLabel),
              if (_error)
                Semantics(
                  liveRegion: true,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('تعذّر فتح التقدّم أو حفظه. حاول مرة أخرى.'),
                  ),
                ),
              if (session == null) ...[
                if (_busy)
                  const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'جارٍ التحميل',
                    ),
                  )
                else
                  FilledButton(
                    onPressed: _retryOpen,
                    child: const Text('حاول مرة أخرى'),
                  ),
              ] else if (session.finished)
                _results(context, session)
              else
                _activity(context, session),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activity(BuildContext context, GameSession session) {
    final item = session.current!;
    final answer = session.feedback?.answer;
    final lessonCount = session.plan.definitions.length;
    final review = session.cursor >= lessonCount;
    final step = review ? session.cursor - lessonCount + 1 : session.cursor + 1;
    final total = review ? session.queue.length - lessonCount : lessonCount;
    final format = MaterialLocalizations.of(context).formatDecimal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          review
              ? 'لِنراجع ما تعلّمناه'
              : 'النشاط ${format(session.cursor + 1)} من ${format(session.plan.definitions.length)}',
        ),
        LinearProgressIndicator(
          value: step / total,
          semanticsLabel: 'تقدّم التحدّيات',
        ),
        const SizedBox(height: 12),
        if (widget.curriculum.isDraftPilot && item is Arrangement)
          Text(item.kind.label, style: Theme.of(context).textTheme.titleMedium),
        switch (item) {
          final ScoredQuestion question => QuestionView(
            question: question,
            options: session.optionsFor(question),
            selectedId: answer?.single,
            enabled: !_busy,
            onAnswer: (id) => _save(session.submit([id])),
          ),
          final Arrangement question => ArrangementView(
            question: question,
            options: session.optionsFor(question),
            answer: answer,
            enabled: !_busy,
            enablePilotEffects: widget.curriculum.isDraftPilot,
            onAnswer: (ids) => _save(session.submit(ids)),
          ),
          final Flashcard card => FlashcardView(
            card: card,
            revealed: _revealed || answer != null,
            recall: answer == null ? null : Recall.values.byName(answer.single),
            onReveal: () {
              setState(() => _revealed = true);
              _effect(PilotEffect.tap);
            },
            onRecall: (recall) => _save(session.submit([recall.name])),
          ),
          _ => const Text('هذا النشاط غير متاح.'),
        },
        if (answer != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              onPressed: _busy ? null : () => _save(session.advance()),
              child: Text(
                session.cursor + 1 == session.queue.length
                    ? 'النتيجة'
                    : 'التالي',
              ),
            ),
          ),
      ],
    );
  }

  Widget _results(BuildContext context, GameSession session) {
    final score = session.score;
    final format = MaterialLocalizations.of(context).formatDecimal;
    final accuracy = score.scored == 0
        ? 'أكملت أنشطة المراجعة.'
        : 'صحيحة من أوّل محاولة: ${format(score.firstCorrect)} من ${format(score.scored)}';
    final eventual = score.scored == 0
        ? ''
        : ' إجابات صحيحة في نهاية الجولة: ${format(score.eventuallyCorrect)} من ${format(score.scored)}.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NoorReaction(
          key: ValueKey(session.id),
          mood: NoorMood.celebrating,
          size: 112,
          playOnEntry: true,
        ),
        const Text(
          'أكملتَ التحدّيات!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(accuracy),
        if (eventual.isNotEmpty) Text(eventual.trim()),
        if (widget.curriculum.isPreview)
          _PreviewRewards(lessonId: widget.lesson.id),
        SpeechControl(text: 'أكملتَ التحدّيات! $accuracy.$eventual'),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => context.go('/worlds/${widget.world.id}'),
              child: const Text('إلى الدرب'),
            ),
            TextButton(
              onPressed: _busy ? null : () => _retryOpen(replayOf: session.id),
              child: const Text('أعد التحدّيات'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewRewards extends ConsumerWidget {
  const _PreviewRewards({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(previewRewardsProvider).asData?.value;
    final stars = rewards?.starsByLesson[lessonId];
    if (rewards == null || stars == null) return const SizedBox.shrink();
    final number = MaterialLocalizations.of(context).formatDecimal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نجوم الدرس: ${number(stars)} من ${number(3)}'),
        Text('نجوم الرحلة: ${number(rewards.stars)}'),
        Text('مجموع نقاط الخبرة: ${number(rewards.xp)}'),
      ],
    );
  }
}
