import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/pilot_effects.dart';
import '../content/curriculum.dart';
import '../home/noor_lantern.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import '../settings/settings_controller.dart';
import 'wudu_discovery.dart';
import 'wudu_courtyard.dart';
import 'wudu_courtyard_frame.dart';

const worshipTreasuresPath = '/preview/adventure/ibadah/treasures';
const wuduTreasureId = 'adventure.W06.treasure.drop';

enum WuduTreasureState { locked, ready, opened }

WuduTreasureState wuduTreasureState(JourneyProgress progress) {
  if (progress.records[wuduMissionProgressId]?.completed != true) {
    return WuduTreasureState.locked;
  }
  return progress.records[wuduTreasureId]?.completed == true
      ? WuduTreasureState.opened
      : WuduTreasureState.ready;
}

final _openTreasureProvider = Provider<Future<bool> Function()>((ref) {
  var inFlight = false;
  return () async {
    if (inFlight) return false;
    inFlight = true;
    const scope = ProgressScope.preview;
    try {
      final store = ref.read(progressStoreProvider);
      // Re-read storage before writing the stable key, including on a deep link.
      if (wuduTreasureState(await store.load(scope)) !=
          WuduTreasureState.ready) {
        return false;
      }
      await store.save(
        scope,
        LessonProgress(
          world: WorldId.ibadah,
          lessonId: wuduTreasureId,
          contentVersion: 'W06.K3',
          stepIndex: 0,
          completed: true,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return true;
    } finally {
      inFlight = false;
      // The map can be back on screen by the time the SQLite write finishes.
      if (ref.mounted) ref.invalidate(progressProvider(scope));
    }
  };
});

class WuduTreasures extends ConsumerStatefulWidget {
  const WuduTreasures({
    super.key,
    required this.waterReminder,
    required this.onExit,
  });

  final String waterReminder;
  final VoidCallback onExit;

  @override
  ConsumerState<WuduTreasures> createState() => _WuduTreasuresState();
}

class _WuduTreasuresState extends ConsumerState<WuduTreasures>
    with SingleTickerProviderStateMixin {
  static const _scope = ProgressScope.preview;
  late final _opening = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 690),
  );
  bool _saving = false;
  bool _openedHere = false;
  bool _failed = false;

  Future<void> _openChest() async {
    if (_saving || _openedHere) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final saved = await ref.read(_openTreasureProvider)();
      if (!mounted || !saved) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _opening.value = 1;
      } else {
        _opening.forward();
      }
      ref.read(pilotEffectsProvider).playAdventure(AdventureEffect.reveal);
      setState(() => _openedHere = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider(_scope));
    final treasure = _openedHere
        ? WuduTreasureState.opened
        : progress.value == null
        ? null
        : wuduTreasureState(progress.requireValue);
    final ready = treasure == WuduTreasureState.ready;
    final opened = treasure == WuduTreasureState.opened;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    ref.watch(settingsProvider);
    return WuduCourtyardFrame(
      title: 'كنوزي',
      onExit: widget.onExit,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final size = Size(bounds.maxWidth, bounds.maxHeight);
          final chestSize = (math.min(size.width, size.height) * .47).clamp(
            124.0,
            220.0,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: CourtyardPainter(
                    Offset(size.width * .18, size.height * .44),
                    Offset(size.width * .79, size.height * .83),
                    chestSize * .50,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        container: true,
                        liveRegion: true,
                        child: Text(
                          opened
                              ? 'جوهرة القطرة'
                              : ready
                              ? 'كنز نافورة الوضوء'
                              : progress.hasError
                              ? 'تعذّر تحميل الكنوز'
                              : treasure == null
                              ? 'لحظة…'
                              : 'أكمل مهمة الوضوء',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF184843),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chestSize + 72,
                        height: chestSize,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            PositionedDirectional(
                              bottom: 10,
                              end: 0,
                              child: NoorReaction(
                                size: 74,
                                mood: opened
                                    ? NoorMood.celebrating
                                    : NoorMood.curious,
                                trigger: _openedHere ? 1 : 0,
                              ),
                            ),
                            PositionedDirectional(
                              top: 0,
                              start: 0,
                              width: chestSize,
                              height: chestSize,
                              child: Semantics(
                                button: ready,
                                label: ready
                                    ? 'افتح الصندوق'
                                    : 'صندوق جوهرة القطرة',
                                enabled: ready ? !_saving : null,
                                onTap: ready && !_saving ? _openChest : null,
                                excludeSemantics: true,
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: InkWell(
                                    excludeFromSemantics: true,
                                    borderRadius: BorderRadius.circular(32),
                                    splashFactory: NoSplash.splashFactory,
                                    onTap: ready && !_saving
                                        ? _openChest
                                        : null,
                                    child: AnimatedBuilder(
                                      key: const ValueKey('wudu-chest-motion'),
                                      animation: _opening,
                                      builder: (_, _) => CustomPaint(
                                        painter: _ChestPainter(
                                          phase: !opened
                                              ? 0
                                              : !_openedHere || reduceMotion
                                              ? 1
                                              : _opening.value,
                                          locked: !ready && !opened,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (opened)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 410),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1C6),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            widget.waterReminder,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF184843),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (_failed)
                        const Text('تعذّر حفظ الكنز. حاول مرة أخرى.'),
                      if (ready)
                        Text(
                          _saving ? 'لحظة…' : 'المس الصندوق',
                          style: const TextStyle(
                            color: Color(0xFF184843),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (opened)
                        FilledButton.icon(
                          onPressed: widget.onExit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('إلى الخريطة'),
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
}

class WuduGem extends StatelessWidget {
  const WuduGem({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const CustomPaint(painter: _GemPainter()),
  );
}

class _GemPainter extends CustomPainter {
  const _GemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final paint = Paint();
    final drop = Path()
      ..moveTo(32, 4)
      ..lineTo(52, 29)
      ..lineTo(55, 42)
      ..lineTo(45, 56)
      ..lineTo(32, 61)
      ..lineTo(19, 56)
      ..lineTo(9, 42)
      ..lineTo(12, 29)
      ..close();
    canvas.drawPath(drop, paint..color = const Color(0xFF216465));
    canvas.save();
    canvas.clipPath(drop);
    canvas.drawPath(
      Path()
        ..moveTo(32, 7)
        ..lineTo(52, 33)
        ..lineTo(32, 43)
        ..lineTo(11, 35)
        ..close(),
      paint..color = const Color(0xFF68D5D0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(32, 7)
        ..lineTo(29, 33)
        ..lineTo(11, 35)
        ..close(),
      paint..color = const Color(0xFFB3F5D6),
    );
    canvas.drawPath(
      Path()
        ..moveTo(9, 42)
        ..lineTo(32, 43)
        ..lineTo(32, 61)
        ..lineTo(16, 57)
        ..close(),
      paint..color = const Color(0xFF369BA0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(32, 43)
        ..lineTo(55, 35)
        ..lineTo(49, 54)
        ..lineTo(32, 61)
        ..close(),
      paint..color = const Color(0xFF247F89),
    );
    canvas.restore();
    canvas.drawPath(
      drop,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFFD26E),
    );
    canvas.drawCircle(
      const Offset(25, 30),
      3,
      paint
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFF1FFE4),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GemPainter oldDelegate) => false;
}

class _ChestPainter extends CustomPainter {
  const _ChestPainter({required this.phase, required this.locked});

  final double phase;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 190, size.height / 190);
    final paint = Paint();
    void wood(Rect rect, double radius, Color color) => canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint..color = color,
    );
    const brass = Color(0xFFE9AC47);
    final lift = Curves.easeOutCubic.transform((phase * 1.55).clamp(0, 1));
    final rise = Curves.easeOutBack.transform(
      ((phase - .23) / .77).clamp(0, 1),
    );
    canvas.drawOval(
      const Rect.fromLTWH(24, 153, 143, 24),
      paint..color = const Color(0x4091623C),
    );
    if (phase > 0) {
      canvas.drawCircle(
        const Offset(95, 91),
        55 * lift,
        paint..color = const Color(0x60FFF3A2),
      );
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 - .35;
        final d = 30 + 31 * lift;
        final center = Offset(
          95 + math.cos(angle) * d,
          88 + math.sin(angle) * d,
        );
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - 6)
            ..lineTo(center.dx + 4, center.dy)
            ..lineTo(center.dx, center.dy + 6)
            ..lineTo(center.dx - 4, center.dy)
            ..close(),
          paint
            ..color = i.isEven
                ? const Color(0xFFFFE07A)
                : const Color(0xFFFFF6C9),
        );
      }
    }
    if (lift > 0) {
      final back = 115 - 34 * lift;
      canvas.drawPath(
        Path()
          ..moveTo(37, 118)
          ..lineTo(39, back)
          ..lineTo(151, back)
          ..lineTo(153, 118)
          ..close(),
        paint..color = const Color(0xFF684632),
      );
      canvas.drawLine(
        Offset(45, back + 4),
        const Offset(45, 114),
        paint
          ..color = brass
          ..strokeWidth = 4,
      );
      canvas.drawLine(
        Offset(145, back + 4),
        const Offset(145, 114),
        paint
          ..color = brass
          ..strokeWidth = 4,
      );
    }
    wood(const Rect.fromLTWH(32, 117, 126, 47), 9, const Color(0xFF805139));
    wood(const Rect.fromLTWH(37, 117, 116, 39), 7, const Color(0xFFAD6745));
    wood(const Rect.fromLTWH(37, 112, 116, 13), 4, brass);
    for (final x in [48.0, 130.0]) {
      wood(Rect.fromLTWH(x, 119, 11, 43), 2, brass);
      canvas.drawCircle(
        Offset(x + 5, 149),
        2,
        paint..color = const Color(0xFFFBE29A),
      );
    }
    canvas.save();
    canvas.translate(0, -34 * lift);
    wood(const Rect.fromLTWH(32, 80, 126, 43), 13, const Color(0xFF8C573D));
    wood(const Rect.fromLTWH(38, 84, 114, 29), 11, const Color(0xFFC98651));
    for (final x in [48.0, 130.0]) {
      wood(Rect.fromLTWH(x, 83, 10, 32), 3, brass);
    }
    wood(const Rect.fromLTWH(33, 109, 124, 11), 3, brass);
    wood(const Rect.fromLTWH(82, 106, 26, 21), 6, const Color(0xFFFFCC63));
    canvas.drawCircle(
      const Offset(95, 116),
      locked ? 4 : 3,
      paint..color = const Color(0xFF805139),
    );
    canvas.restore();

    if (rise > 0) {
      canvas.save();
      canvas.translate(68, 103 - 68 * rise);
      const _GemPainter().paint(canvas, const Size.square(54));
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChestPainter oldDelegate) =>
      phase != oldDelegate.phase || locked != oldDelegate.locked;
}
