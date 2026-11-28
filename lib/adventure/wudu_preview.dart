import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/pilot_effects.dart';
import '../home/noor_lantern.dart';
import '../settings/settings_controller.dart';
import 'wudu_courtyard.dart';
import 'wudu_courtyard_frame.dart';
import 'wudu_discovery.dart';
import 'wudu_discovery_art.dart';

class WuduPreview extends ConsumerStatefulWidget {
  const WuduPreview({
    super.key,
    required this.discovery,
    required this.onExit,
    required this.onChallenge,
  });

  final WuduDiscovery discovery;
  final VoidCallback onExit;
  final VoidCallback onChallenge;

  @override
  ConsumerState<WuduPreview> createState() => _WuduPreviewState();
}

class _WuduPreviewState extends ConsumerState<WuduPreview>
    with SingleTickerProviderStateMixin {
  late final _response = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  final _touched = <WuduObject>{};
  WuduObject? _lastTouched;
  int _index = 0;
  int _reaction = 0;
  bool _selected = false;
  bool _hint = false;
  bool _dragging = false;
  double _wipeDistance = 0;
  final _wipeProgress = ValueNotifier<double>(0);
  late final _objectMotion = Listenable.merge([_response, _wipeProgress]);

  WuduStop get _stop => widget.discovery.stops[_index];
  bool get _ready => _touched.length == _stop.objects.length;
  bool get _last => _index == widget.discovery.stops.length - 1;

  void _play(AdventureEffect effect) =>
      ref.read(pilotEffectsProvider).playAdventure(effect);

  void _miss() {
    if (!mounted || _ready) return;
    if (!_hint) {
      setState(() {
        _hint = true;
        _reaction++;
      });
    }
    _play(AdventureEffect.retry);
  }

  void _touch(WuduObject object) {
    if (!_stop.objects.contains(object) || _touched.contains(object)) return;
    setState(() {
      _touched.add(object);
      _lastTouched = object;
      _selected = false;
      _hint = false;
      _reaction++;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      _response.forward(from: 0);
    }
    _play(switch (_stop.action) {
      WuduAction.wipe => AdventureEffect.wipe,
      WuduAction.closeTap => AdventureEffect.finish,
      _ => AdventureEffect.splash,
    });
  }

  void _continue() {
    if (!_ready) return;
    _response.reset();
    _wipeProgress.value = 0;
    setState(() {
      _index = _last ? 0 : _index + 1;
      _touched.clear();
      _lastTouched = null;
      _selected = false;
      _hint = false;
      _dragging = false;
      _wipeDistance = 0;
    });
  }

  String get _message {
    if (_ready) return _stop.feedback;
    if (_selected || (_hint && _stop.action == WuduAction.drop)) {
      return _selected ? 'المس الكفّين' : 'اسحب القطرة إلى الكفّين';
    }
    if (_hint && _stop.action == WuduAction.wipe) {
      return 'مرّر إصبعك من جانب إلى آخر، أو المس الرأس';
    }
    if (_touched.isNotEmpty) {
      final remaining = _stop.objects.firstWhere(
        (object) => !_touched.contains(object),
      );
      final cue = 'المس ${remaining.label}';
      final rinseLabel = widget.discovery.rinseLabels[_lastTouched];
      return rinseLabel == null ? cue : '$rinseLabel · $cue';
    }
    return _stop.hint;
  }

  @override
  void dispose() {
    _response.dispose();
    _wipeProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider);
    return WuduCourtyardFrame(
      title: widget.discovery.title,
      onExit: widget.onExit,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _courtyard(context, constraints.biggest),
      ),
    );
  }

  Widget _courtyard(BuildContext context, Size size) {
    final wide = size.width >= 540;
    final unit = (math.min(size.width, size.height) * .23).clamp(64.0, 134.0);
    final drop = Offset(size.width * .25, size.height * (wide ? .47 : .39));
    final basin = Offset(
      size.width * (wide ? .58 : .64),
      size.height * (wide ? .62 : .56),
    );
    final noor = Offset(
      size.width * (wide ? .84 : .26),
      size.height * (wide ? .68 : .82),
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final atTap = _stop.action == WuduAction.closeTap;
    final waterOff = atTap && _ready;
    final finish = _ready && _last;

    Widget at(Offset center, double extent, Widget child) => Positioned(
      left: center.dx - extent / 2,
      top: center.dy - extent / 2,
      width: extent,
      height: extent,
      child: child,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: CourtyardPainter(
              drop,
              basin,
              unit,
              flowing: atTap && !waterOff,
            ),
          ),
        ),
        if (!_ready)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _miss,
          ),
        at(
          noor,
          unit * 1.18,
          NoorReaction(
            size: unit * 1.18,
            mood: _ready
                ? NoorMood.celebrating
                : _hint
                ? NoorMood.encouraging
                : _selected || _dragging
                ? NoorMood.thinking
                : _touched.isNotEmpty
                ? NoorMood.happy
                : NoorMood.curious,
            trigger: _reaction,
          ),
        ),
        if (_stop.action == WuduAction.drop) ...[
          at(basin, unit * 1.42, _palms(reduceMotion)),
          if (!_ready) at(drop, unit, _droplet(unit, reduceMotion)),
        ] else
          for (final (index, object) in _stop.objects.indexed)
            at(
              atTap
                  ? drop.translate(unit * .18, -unit * .25)
                  : basin.translate(
                      _stop.objects.length == 1
                          ? 0
                          : unit * (index == 0 ? .66 : -.66),
                      0,
                    ),
              unit * (_stop.objects.length == 1 ? 1.42 : 1.18),
              _object(object, reduceMotion, unit),
            ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: IgnorePointer(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2CF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE9B681), width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label: 'نور',
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                      maxLines: _ready ? null : 3,
                      overflow: _ready
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF234E49),
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: 12,
          start: 12,
          child: Semantics(
            label: 'محطة ${_index + 1} من ${widget.discovery.stops.length}',
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2CF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < widget.discovery.stops.length; i++)
                        Icon(
                          i < _index || (i == _index && _ready)
                              ? Icons.check_rounded
                              : i == _index
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color: const Color(0xFF23685B),
                          size: 13,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_ready)
          PositionedDirectional(
            key: ValueKey(_index),
            start: 12,
            end: 12,
            bottom: finish ? 49 : 12,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (finish) ...[
                    IconButton.filledTonal(
                      tooltip: 'أعد الاكتشاف',
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(48),
                      ),
                      onPressed: _continue,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: FilledButton.icon(
                      onPressed: finish ? widget.onChallenge : _continue,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(finish ? 'جرّب التحدّي' : 'هيا نكمل'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _palms(bool reduceMotion) => DragTarget<WuduObject>(
    onWillAcceptWithDetails: (details) =>
        !_ready && details.data == WuduObject.palms,
    onAcceptWithDetails: (_) => _touch(WuduObject.palms),
    builder: (context, candidates, _) => _SceneButton(
      label: WuduObject.palms.label,
      onTap: _ready
          ? null
          : () {
              if (_selected) {
                _touch(WuduObject.palms);
              } else {
                _miss();
              }
            },
      child: AnimatedBuilder(
        animation: _response,
        builder: (_, _) => CustomPaint(
          painter: PalmsPainter(
            active: _selected || _dragging || _hint || candidates.isNotEmpty,
            washed: _ready,
            splash: reduceMotion ? 0 : _response.value,
          ),
        ),
      ),
    ),
  );

  Widget _droplet(double unit, bool reduceMotion) {
    final art = DropArt(size: unit, selected: _selected || _hint);
    return Draggable<WuduObject>(
      data: WuduObject.palms,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: Offset(-unit / 2, -unit / 2),
        child: DropArt(size: unit, selected: true),
      ),
      childWhenDragging: Opacity(opacity: .28, child: art),
      onDragStarted: () {
        setState(() {
          _dragging = true;
          _reaction++;
        });
        _play(AdventureEffect.pickup);
      },
      onDragEnd: (_) {
        if (mounted) setState(() => _dragging = false);
      },
      onDraggableCanceled: (_, _) => _miss(),
      child: _SceneButton(
        label: 'قطرة الماء',
        selected: _selected,
        onTap: () {
          setState(() => _selected = !_selected);
          _play(AdventureEffect.pickup);
        },
        child: AnimatedScale(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 135),
          scale: _selected ? 1.1 : 1,
          child: art,
        ),
      ),
    );
  }

  Widget _object(WuduObject object, bool reduceMotion, double unit) {
    final done = _touched.contains(object);
    final button = _SceneButton(
      label: object.label,
      onTap: done ? null : () => _touch(object),
      child: AnimatedBuilder(
        animation: _objectMotion,
        builder: (_, _) => CustomPaint(
          painter: DiscoveryObjectPainter(
            object: object,
            done: done,
            highlighted: !done && (_hint || _touched.isNotEmpty),
            wipeProgress: reduceMotion ? 0 : _wipeProgress.value,
            phase: !reduceMotion && _lastTouched == object
                ? _response.value
                : 0,
          ),
        ),
      ),
    );
    if (_stop.action != WuduAction.wipe || done) return button;
    return GestureDetector(
      excludeFromSemantics: true,
      onHorizontalDragStart: (_) {
        _wipeDistance = 0;
        _wipeProgress.value = 0;
      },
      onHorizontalDragUpdate: (details) {
        _wipeDistance += details.primaryDelta!;
        if (!reduceMotion) {
          _wipeProgress.value = (_wipeDistance / (unit * .36)).clamp(-1.0, 1.0);
        }
      },
      onHorizontalDragCancel: () => _wipeProgress.value = 0,
      onHorizontalDragEnd: (_) {
        _wipeProgress.value = 0;
        if (_wipeDistance.abs() >= unit * .36) {
          _touch(object);
        } else {
          _miss();
        }
      },
      child: button,
    );
  }
}

class _SceneButton extends StatelessWidget {
  const _SceneButton({
    required this.label,
    required this.onTap,
    required this.child,
    this.selected,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget child;
  final bool? selected;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    enabled: onTap != null,
    selected: selected,
    onTap: onTap,
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        excludeFromSemantics: true,
        child: child,
      ),
    ),
  );
}
