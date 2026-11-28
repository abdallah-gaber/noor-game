import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/pilot_effects.dart';
import '../home/noor_lantern.dart';
import '../settings/settings_controller.dart';
import 'wudu_courtyard.dart';

class WuduPreview extends ConsumerStatefulWidget {
  const WuduPreview({super.key, required this.title, required this.onExit});

  final String title;
  final VoidCallback onExit;

  @override
  ConsumerState<WuduPreview> createState() => _WuduPreviewState();
}

class _WuduPreviewState extends ConsumerState<WuduPreview>
    with SingleTickerProviderStateMixin {
  late final _splash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  bool _selected = false;
  bool _washed = false;
  int _reaction = 0;

  void _play(PilotEffect effect) => ref.read(pilotEffectsProvider).play(effect);

  void _wash() {
    if (_washed) return;
    setState(() {
      _washed = true;
      _selected = false;
      _reaction++;
    });
    if (!MediaQuery.disableAnimationsOf(context)) _splash.forward(from: 0);
    _play(PilotEffect.complete);
  }

  void _reset() {
    _splash.reset();
    setState(() {
      _washed = false;
      _selected = false;
    });
    _play(PilotEffect.tap);
  }

  @override
  void dispose() {
    _splash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF184843),
      body: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'العودة إلى المعاينة',
                      color: Colors.white,
                      onPressed: widget.onExit,
                      icon: const BackButtonIcon(),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFF1CB),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        final wide = size.width >= 540;
                        final scale = math.min(size.width, size.height);
                        final unit = (scale * .23).clamp(64.0, 134.0);
                        final drop = Offset(
                          size.width * .25,
                          size.height * (wide ? .47 : .39),
                        );
                        final palms = Offset(
                          size.width * (wide ? .58 : .67),
                          size.height * (wide ? .62 : .57),
                        );
                        final noor = Offset(
                          size.width * (wide ? .84 : .28),
                          size.height * (wide ? .68 : .83),
                        );
                        Widget at(Offset center, double extent, Widget child) =>
                            Positioned(
                              left: center.dx - extent / 2,
                              top: center.dy - extent / 2,
                              width: extent,
                              height: extent,
                              child: child,
                            );

                        final dropArt = DropArt(
                          size: unit,
                          selected: _selected,
                        );
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: CourtyardPainter(drop, palms, unit),
                              ),
                            ),
                            at(
                              noor,
                              unit * 1.18,
                              NoorReaction(
                                size: unit * 1.18,
                                mood: _washed
                                    ? NoorMood.celebrating
                                    : NoorMood.happy,
                                trigger: _reaction,
                              ),
                            ),
                            at(
                              palms,
                              unit * 1.42,
                              DragTarget<bool>(
                                onWillAcceptWithDetails: (_) => !_washed,
                                onAcceptWithDetails: (_) => _wash(),
                                builder: (context, candidates, _) =>
                                    _SceneButton(
                                      label: 'الكفّان',
                                      onTap: _washed
                                          ? null
                                          : () {
                                              if (_selected) {
                                                _wash();
                                              } else {
                                                setState(
                                                  () => _selected = true,
                                                );
                                                _play(PilotEffect.tap);
                                              }
                                            },
                                      child: AnimatedBuilder(
                                        animation: _splash,
                                        builder: (_, _) => CustomPaint(
                                          painter: PalmsPainter(
                                            active:
                                                _selected ||
                                                candidates.isNotEmpty,
                                            washed: _washed,
                                            splash: reduceMotion
                                                ? 0
                                                : _splash.value,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                            if (!_washed)
                              at(
                                drop,
                                unit,
                                Draggable<bool>(
                                  data: true,
                                  maxSimultaneousDrags: 1,
                                  dragAnchorStrategy: pointerDragAnchorStrategy,
                                  feedback: Transform.translate(
                                    offset: Offset(-unit / 2, -unit / 2),
                                    child: DropArt(size: unit, selected: true),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: .28,
                                    child: dropArt,
                                  ),
                                  onDraggableCanceled: (_, _) {
                                    if (mounted) _play(PilotEffect.retry);
                                  },
                                  child: _SceneButton(
                                    label: 'قطرة الماء',
                                    selected: _selected,
                                    onTap: () {
                                      setState(() => _selected = !_selected);
                                      _play(PilotEffect.tap);
                                    },
                                    child: dropArt,
                                  ),
                                ),
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
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: const Color(0xFFE9B681),
                                        width: 2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Semantics(
                                        liveRegion: true,
                                        child: Text(
                                          _washed
                                              ? 'رائع!'
                                              : _selected
                                              ? 'المس الكفّين'
                                              : 'اسحب القطرة أو المسها',
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
                            if (_washed)
                              PositionedDirectional(
                                end: 12,
                                bottom: 12,
                                child: FilledButton.icon(
                                  onPressed: _reset,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('العب مجددًا'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
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
