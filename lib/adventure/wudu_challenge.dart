import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/pilot_effects.dart';
import '../challenges/game_session.dart';
import '../challenges/game_store.dart';
import '../content/curriculum.dart';
import '../home/noor_lantern.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import '../progress/reward_store.dart';
import '../review/review_store.dart';
import '../settings/settings_controller.dart';
import 'wudu_courtyard.dart';
import 'wudu_courtyard_frame.dart';
import 'wudu_discovery.dart';
import 'wudu_discovery_art.dart';

class WuduChallenge extends ConsumerStatefulWidget {
  const WuduChallenge({
    super.key,
    required this.discovery,
    required this.onExit,
    this.replayCompletedOnEntry = false,
  });

  // Reserve a preview completion key so a draft lesson with ID W06 retains its
  // reading position. The session still records the approved variant and KUs.
  static const progressId = 'adventure.W06';

  final WuduDiscovery discovery;
  final VoidCallback onExit;
  final bool replayCompletedOnEntry;

  @override
  ConsumerState<WuduChallenge> createState() => _WuduChallengeState();
}

class _WuduChallengeState extends ConsumerState<WuduChallenge> {
  static const _scope = ProgressScope.preview;
  static const _progressId = WuduChallenge.progressId;
  static final _controlStyle = FilledButton.styleFrom(
    minimumSize: const Size(48, 48),
  );

  late final _definition = widget.discovery.ordering;
  late final _plan = GamePlan('courtyard.W06.1', [
    _definition,
  ], allowAssistedRetries: true);
  late final _slots = List<String?>.filled(_definition.items.length, null);
  GameSession? _session;
  bool _busy = true;
  bool _storageError = false;
  bool _placementHint = false;

  bool get _canEdit =>
      !_busy &&
      !_storageError &&
      _session != null &&
      !_session!.finished &&
      _session!.feedback == null;

  @override
  void initState() {
    super.initState();
    _open(replayCompleted: widget.replayCompletedOnEntry);
  }

  Future<void> _open({String? replayOf, bool replayCompleted = false}) async {
    try {
      final random = math.Random.secure();
      final id =
          '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 30)}';
      final store = ref.read(gameStoreProvider);
      final draft = GameSession.start(id, _plan, random);
      var session = await store.open(
        _scope,
        _progressId,
        draft,
        replayOf: replayOf,
      );
      if (replayCompleted && session.finished && mounted) {
        session = await store.open(
          _scope,
          _progressId,
          draft,
          replayOf: session.id,
        );
      }
      if (!mounted) return;
      setState(() {
        _showSession(session);
        _storageError = false;
      });
    } catch (_) {
      if (mounted) setState(() => _storageError = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSession(GameSession session) {
    final previous = _session;
    _session = session;
    _placementHint = false;
    final answer = _shownAttempt(session)?.answer;
    if (answer != null) {
      _slots.setAll(0, answer);
    } else if (previous?.id != session.id ||
        previous?.cursor != session.cursor) {
      _slots.fillRange(0, _slots.length, null);
    }
  }

  GameAttempt? _shownAttempt(GameSession session) =>
      session.finished ? session.attempts.last : session.feedback;

  Future<void> _save(GameSession from, GameSession? next) async {
    if (_busy || _storageError || !identical(_session, from) || next == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(gameStoreProvider)
          .save(_scope, WorldId.ibadah, _progressId, next);
      if (!mounted) return;
      ref.invalidate(reviewHistoryFor(_scope));
      if (next.finished) {
        ref.invalidate(progressProvider(_scope));
        ref.invalidate(previewRewardsProvider);
      }
      final effect = next.finished
          ? PilotEffect.complete
          : switch (next.feedback?.correct) {
              true => PilotEffect.correct,
              false => PilotEffect.retry,
              null => PilotEffect.tap,
            };
      ref.read(pilotEffectsProvider).play(effect);
      setState(() => _showSession(next));
    } catch (_) {
      if (mounted) setState(() => _storageError = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reopen({String? replayOf}) {
    if (_busy) return;
    setState(() => _busy = true);
    _open(replayOf: replayOf);
  }

  bool _accepts(String id, int index) {
    if (!_canEdit || _slots[index] == id) return false;
    final help = _session!.assistedOrder;
    return help == null || (index == _slots.indexOf(null) && id == help[index]);
  }

  void _place(String id, int index) {
    if (!_accepts(id, index)) return;
    final from = _slots.indexOf(id);
    setState(() {
      if (from != -1) _slots[from] = _slots[index];
      _slots[index] = id;
      _placementHint = false;
    });
    ref.read(pilotEffectsProvider).play(PilotEffect.tap);
  }

  void _tapPiece(String id) {
    if (!_canEdit || _slots.contains(id)) return;
    final index = _slots.indexOf(null);
    if (index != -1 && _accepts(id, index)) {
      _place(id, index);
    } else {
      setState(() => _placementHint = true);
      ref.read(pilotEffectsProvider).play(PilotEffect.retry);
    }
  }

  void _remove(int index) {
    if (!_canEdit || _slots[index] == null) return;
    setState(() {
      if (_session!.usesAssistance) {
        _slots.fillRange(index, _slots.length, null);
      } else {
        _slots[index] = null;
      }
      _placementHint = false;
    });
  }

  String _message(GameSession? session) {
    if (_storageError) return 'تعذّر حفظ الجولة. افتحها مجددًا.';
    if (session == null) return 'لحظة…';
    final attempt = _shownAttempt(session);
    if (attempt != null) {
      if (attempt.correct == false) return 'اقتربت! جرّب ترتيبًا آخر.';
      return attempt.assisted
          ? 'أكملت الترتيب مع نور!'
          : 'رتّبتها بنفسك! أحسنت!';
    }
    if (session.usesAssistance) return 'ضع القطعة المضيئة في مكانها.';
    if (_placementHint) return 'المس قطعة على الدرب لتبديلها.';
    return session.attempts.isEmpty
        ? 'رتّب القطع على الدرب'
        : 'جرّب من جديد. ابدأ من يمين الدرب.';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider);
    final session = _session;
    final attempt = session == null ? null : _shownAttempt(session);
    final rewards = session?.finished == true
        ? ref.watch(previewRewardsProvider).asData?.value
        : null;
    return WuduCourtyardFrame(
      title: 'تحدّي الترتيب',
      onExit: widget.onExit,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final width = bounds.maxWidth;
          final height = bounds.maxHeight;
          final compact = height < 430;
          final spacing = width >= 520 ? 12.0 : 4.0;
          final size =
              ((width - 24 - spacing * (_slots.length - 1)) / _slots.length)
                  .clamp(48.0, compact ? 72.0 : 98.0);
          final number = MaterialLocalizations.of(context).formatDecimal;
          final next = _slots.indexOf(null);
          final highlightedId = next == -1
              ? null
              : session?.assistedOrder?[next];
          final options = session?.optionsFor(_definition);
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: CourtyardPainter(
                    Offset(width * .15, height * .38),
                    Offset(width * .83, height * .72),
                    math.min(width, height) * .19,
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, height - 24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NoorReaction(
                            size: compact ? 48 : 66,
                            mood: attempt?.correct == true
                                ? NoorMood.celebrating
                                : attempt?.correct == false ||
                                      highlightedId != null
                                ? NoorMood.encouraging
                                : NoorMood.happy,
                            trigger: session?.revision ?? 0,
                          ),
                          Flexible(
                            child: _CourtyardCaption(
                              label: _message(session),
                              detail: attempt?.correct == true
                                  ? _definition.explanation
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (options != null) ...[
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: spacing,
                          runSpacing: 4,
                          children: [
                            for (final option in options)
                              SizedBox.square(
                                dimension: size,
                                child: _slots.contains(option.id)
                                    ? const SizedBox.shrink()
                                    : _piece(
                                        id: option.id,
                                        size: size,
                                        label: option.label,
                                        highlight: option.id == highlightedId,
                                        onTap: _canEdit
                                            ? () => _tapPiece(option.id)
                                            : null,
                                      ),
                              ),
                          ],
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF276F66),
                            border: Border.all(
                              color: const Color(0xFFFFE4AA),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: spacing,
                              runSpacing: 4,
                              children: [
                                for (
                                  var index = 0;
                                  index < _slots.length;
                                  index++
                                )
                                  _slot(
                                    index,
                                    size,
                                    'الموضع ${number(index + 1)}',
                                    number(index + 1),
                                    index == next && highlightedId != null,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_busy && session == null)
                        const CircularProgressIndicator()
                      else
                        _controls(
                          session,
                          rewards?.starsByLesson[_progressId],
                          number,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _controls(
    GameSession? session,
    int? stars,
    String Function(int) number,
  ) {
    if (_storageError) {
      return FilledButton(
        style: _controlStyle,
        onPressed: _busy ? null : _reopen,
        child: const Text('أعد فتح الجولة'),
      );
    }
    if (session == null) return const SizedBox.shrink();
    final feedback = session.feedback;
    if (session.finished) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: [
          if (stars != null)
            _CourtyardCaption(label: 'أفضل النجوم · ${number(stars)}'),
          FilledButton.icon(
            style: _controlStyle,
            onPressed: _busy ? null : widget.onExit,
            icon: const Icon(Icons.map_outlined),
            label: const Text('إلى الخريطة'),
          ),
          FilledButton.tonalIcon(
            style: _controlStyle,
            onPressed: _busy ? null : () => _reopen(replayOf: session.id),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('العب مجددًا'),
          ),
        ],
      );
    }
    return FilledButton.icon(
      key: ValueKey((session.id, session.cursor, feedback != null)),
      style: _controlStyle,
      onPressed: _busy
          ? null
          : feedback != null
          ? () => _save(session, session.advance())
          : _slots.contains(null)
          ? null
          : () => _save(session, session.submit(_slots.cast<String>())),
      icon: Icon(
        feedback?.correct == false
            ? Icons.refresh_rounded
            : Icons.check_rounded,
      ),
      label: Text(switch (feedback?.correct) {
        true => 'إنهاء التحدّي',
        false => 'جرّب مجددًا',
        null => 'تحقّق',
      }),
    );
  }

  Widget _slot(
    int index,
    double size,
    String label,
    String number,
    bool highlight,
  ) {
    final id = _slots[index];
    final itemLabel = id == null
        ? label
        : '$label · ${_definition.items.singleWhere((item) => item.id == id).label}';
    return SizedBox.square(
      dimension: size,
      child: DragTarget<String>(
        key: ValueKey('wudu-slot-$index'),
        onWillAcceptWithDetails: (details) => _accepts(details.data, index),
        onAcceptWithDetails: (details) => _place(details.data, index),
        builder: (context, candidates, _) => id == null
            ? Semantics(
                label: label,
                hint: highlight ? 'الموضع التالي' : null,
                excludeSemantics: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: candidates.isNotEmpty || highlight
                        ? const Color(0xFFFFDC8B)
                        : const Color(0xFFD3ECE0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF387E70),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Color(0xFF245B51),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
            : _piece(
                id: id,
                size: size,
                label: itemLabel,
                onTap: _canEdit ? () => _remove(index) : null,
              ),
      ),
    );
  }

  Widget _piece({
    required String id,
    required double size,
    required String label,
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    final art = Stack(
      fit: StackFit.expand,
      children: [
        _SequencePiece(id: id, highlight: highlight),
        if (highlight)
          const PositionedDirectional(
            end: 4,
            top: 3,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Color(0xFF59400F),
            ),
          ),
      ],
    );
    final interactive = Semantics(
      button: true,
      label: label,
      hint: highlight ? 'قطعة يقترحها نور' : null,
      enabled: onTap != null,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: art,
        ),
      ),
    );
    if (onTap == null) return interactive;
    return Draggable<String>(
      data: id,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: Offset(-size / 2, -size / 2),
        child: SizedBox.square(dimension: size, child: art),
      ),
      childWhenDragging: Opacity(opacity: .36, child: art),
      child: interactive,
    );
  }
}

class _CourtyardCaption extends StatelessWidget {
  const _CourtyardCaption({required this.label, this.detail});

  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFFFF2CF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF184843),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (detail != null)
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF184843)),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SequencePiece extends StatelessWidget {
  const _SequencePiece({required this.id, required this.highlight});

  final String id;
  final bool highlight;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: highlight ? const Color(0xFFFFCE64) : const Color(0xFFF7D49A),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: highlight ? const Color(0xFF7C5017) : const Color(0xFFAA7552),
        width: highlight ? 3 : 2,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: switch (id) {
        'i1' => Stack(
          fit: StackFit.expand,
          children: [
            const Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: .66,
                heightFactor: .66,
                child: CustomPaint(
                  painter: PalmsPainter(
                    active: false,
                    washed: false,
                    splash: 0,
                  ),
                ),
              ),
            ),
            for (final (object, side) in [
              (WuduObject.mouth, Alignment.bottomRight),
              (WuduObject.nose, Alignment.bottomLeft),
            ])
              Align(
                alignment: side,
                child: FractionallySizedBox(
                  widthFactor: .45,
                  heightFactor: .45,
                  child: _token(object),
                ),
              ),
          ],
        ),
        'i2' => _token(WuduObject.face, washing: true),
        'i3' => _token(WuduObject.rightArm, washing: true),
        'i4' => _token(WuduObject.head),
        'i5' => _token(WuduObject.rightFoot, washing: true),
        _ => throw StateError('Unknown W06 piece'),
      },
    ),
  );

  Widget _token(WuduObject object, {bool washing = false}) => Stack(
    fit: StackFit.expand,
    children: [
      CustomPaint(
        painter: DiscoveryObjectPainter(
          object: object,
          done: false,
          highlighted: false,
          phase: 0,
        ),
      ),
      if (washing)
        const PositionedDirectional(
          start: 4,
          bottom: 4,
          child: Icon(
            Icons.water_drop_rounded,
            size: 16,
            color: Color(0xFF217C9A),
          ),
        ),
    ],
  );
}
