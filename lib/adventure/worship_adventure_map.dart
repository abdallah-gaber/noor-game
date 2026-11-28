import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/curriculum.dart';
import '../home/noor_lantern.dart';
import '../progress/lesson_progress.dart';
import '../progress/progress_store.dart';
import '../progress/reward_store.dart';
import 'worship_map_art.dart';
import 'wudu_challenge.dart';
import 'wudu_treasure.dart';

const worshipMapPath = '/preview/adventure/ibadah';

class WorshipAdventureMap extends ConsumerStatefulWidget {
  const WorshipAdventureMap({
    super.key,
    required this.onExit,
    required this.onDiscovery,
    required this.onChallenge,
    required this.onTreasures,
  });

  final VoidCallback onExit;
  final VoidCallback onDiscovery;
  final VoidCallback onChallenge;
  final VoidCallback onTreasures;

  @override
  ConsumerState<WorshipAdventureMap> createState() =>
      _WorshipAdventureMapState();
}

class _WorshipAdventureMapState extends ConsumerState<WorshipAdventureMap> {
  String? _visited;

  @override
  Widget build(BuildContext context) {
    const mission = WuduChallenge.progressId;
    final progress = ref.watch(progressProvider(ProgressScope.preview));
    final completed =
        progress.asData?.value.records[mission]?.completed == true;
    final rewards = completed
        ? ref.watch(previewRewardsProvider).asData?.value
        : null;
    final status = !completed
        ? null
        : rewards?.independentCompletions.contains(mission) == true
        ? 'أكملتها بنفسك'
        : rewards?.starsByLesson.containsKey(mission) == true
        ? 'أكملتها مع نور'
        : 'اكتملت المهمة';
    return Scaffold(
      backgroundColor: const Color(0xFF315648),
      body: SafeArea(
        minimum: const EdgeInsets.all(10),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final wide = bounds.maxWidth >= 590;
                  final height = math.max(
                    bounds.maxHeight,
                    wide ? 370.0 : 530.0,
                  );
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: bounds.maxWidth,
                      height: height,
                      child: _landscape(
                        Size(bounds.maxWidth, height),
                        wide: wide,
                        completed: completed,
                        recommended: progress.hasValue && !completed,
                        status: status,
                        treasure: progress.value == null
                            ? WuduTreasureState.locked
                            : wuduTreasureState(progress.requireValue),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _landscape(
    Size size, {
    required bool wide,
    required bool completed,
    required bool recommended,
    required String? status,
    required WuduTreasureState treasure,
  }) {
    final w = size.width;
    final h = size.height;
    final hero = math.min(w * (wide ? .26 : .51), h * .36).clamp(125.0, 230.0);
    final distant = (hero * .66).clamp(88.0, 150.0);
    final marker = (hero * .53).clamp(76.0, 114.0);
    final noorSize = (hero * .55).clamp(78.0, 124.0);
    final WorshipMapLocations places = (
      fountain: Offset(w * .51, h * (wide ? .49 : .50)),
      arcade: Offset(w * (wide ? .22 : .23), h * (wide ? .46 : .32)),
      gate: Offset(w * (wide ? .81 : .76), h * (wide ? .32 : .27)),
      challenge: Offset(w * (wide ? .68 : .72), h * (wide ? .75 : .77)),
      noor: Offset(w * (wide ? .86 : .23), h * (wide ? .76 : .77)),
    );

    Widget landmark(
      Offset anchor,
      double diameter,
      WorshipLandmark type,
      String label,
      String hint,
      VoidCallback onTap, {
      String? note,
      IconData? icon,
      bool primary = false,
    }) {
      final width = math.min(
        w * (primary ? .65 : .44),
        math.max(diameter, 118.0),
      );
      return Positioned(
        left: (anchor.dx - width / 2).clamp(9.0, w - width - 9.0),
        top: anchor.dy - diameter / 2,
        width: width,
        child: _Landmark(
          type: type,
          diameter: diameter,
          label: label,
          hint: hint,
          onTap: onTap,
          note: note,
          icon: icon,
          recommended: primary && recommended,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: WorshipMapPainter(places, wide: wide)),
        ),
        landmark(
          places.arcade,
          distant,
          WorshipLandmark.arcade,
          'رواق الفوانيس',
          'غير متاح في المعاينة',
          () => setState(() => _visited = 'رواق الفوانيس'),
          icon: Icons.lock_outline_rounded,
        ),
        landmark(
          places.gate,
          distant,
          WorshipLandmark.gate,
          'بوابة النخيل',
          'غير متاح في المعاينة',
          () => setState(() => _visited = 'بوابة النخيل'),
          icon: Icons.lock_outline_rounded,
        ),
        landmark(
          places.fountain,
          hero,
          WorshipLandmark.fountain,
          'نافورة الوضوء',
          completed ? 'أعد الاكتشاف' : 'افتح مهمة الوضوء',
          widget.onDiscovery,
          note: status,
          icon: completed ? Icons.check_circle_outline_rounded : null,
          primary: true,
        ),
        landmark(
          places.challenge,
          marker,
          WorshipLandmark.challenge,
          completed ? 'أعد التحدّي' : 'التحدّي',
          'افتح تحدّي ترتيب الوضوء',
          widget.onChallenge,
        ),
        Positioned(
          left: places.noor.dx - noorSize / 2,
          top: places.noor.dy - noorSize / 2,
          child: NoorReaction(
            size: noorSize,
            mood: completed ? NoorMood.celebrating : NoorMood.curious,
            playOnEntry: true,
          ),
        ),
        Positioned(
          top: 16,
          left: 66,
          right: 66,
          child: IgnorePointer(
            child: Center(
              child: Semantics(
                header: true,
                child: _MapSign(
                  label: WorldId.ibadah.title,
                  size: 26,
                  color: const Color(0xFF365C4D),
                  ink: const Color(0xFFFFE1A5),
                  icon: Icons.explore_outlined,
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 13,
          start: 13,
          child: IconButton.filled(
            tooltip: 'العودة إلى المعاينة',
            style: IconButton.styleFrom(
              minimumSize: const Size.square(48),
              foregroundColor: const Color(0xFFFFE8B7),
              backgroundColor: const Color(0xFF365C4D),
            ),
            onPressed: widget.onExit,
            icon: const BackButtonIcon(),
          ),
        ),
        PositionedDirectional(
          top: 13,
          end: 13,
          child: Semantics(
            value: switch (treasure) {
              WuduTreasureState.opened => 'جوهرة القطرة',
              WuduTreasureState.ready => 'صندوق جاهز للفتح',
              WuduTreasureState.locked => null,
            },
            child: IconButton.filled(
              tooltip: 'كنوزي',
              onPressed: widget.onTreasures,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                foregroundColor: const Color(0xFFFFE8B7),
                backgroundColor: const Color(0xFF365C4D),
              ),
              icon: switch (treasure) {
                WuduTreasureState.opened => const WuduGem(size: 27),
                WuduTreasureState.ready => const Icon(
                  Icons.inventory_2_rounded,
                ),
                WuduTreasureState.locked => const Icon(
                  Icons.inventory_2_outlined,
                ),
              },
            ),
          ),
        ),
        if (_visited case final visited?)
          Positioned(
            bottom: 15,
            left: 14,
            right: 14,
            child: Center(
              child: Semantics(
                container: true,
                liveRegion: true,
                child: _MapSign(
                  label: '$visited · غير متاح في المعاينة',
                  icon: Icons.lock_outline_rounded,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Landmark extends StatelessWidget {
  const _Landmark({
    required this.type,
    required this.diameter,
    required this.label,
    required this.hint,
    required this.onTap,
    required this.recommended,
    this.note,
    this.icon,
  });

  final WorshipLandmark type;
  final double diameter;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final bool recommended;
  final String? note;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final primary = type == WorshipLandmark.fountain;
    final locked = icon == Icons.lock_outline_rounded;
    return Semantics(
      button: true,
      label: label,
      value: recommended ? 'ابدأ هنا' : note,
      hint: hint,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(22),
          focusColor: const Color(0x70FFF3BA),
          splashFactory: NoSplash.splashFactory,
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: diameter * (primary ? .79 : .77),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: WorshipLandmarkPainter(
                        type,
                        accent: recommended,
                      ),
                    ),
                    if (recommended)
                      const Align(
                        alignment: Alignment.topCenter,
                        child: _MapSign(
                          label: 'ابدأ هنا',
                          icon: Icons.south_rounded,
                          color: Color(0xFFFFCF6F),
                        ),
                      ),
                  ],
                ),
              ),
              _MapSign(
                label: label,
                icon: icon,
                size: primary ? 17 : 14,
                color: locked
                    ? const Color(0xFFF0D0A2)
                    : const Color(0xFF365C4D),
                ink: locked ? const Color(0xFF62472F) : const Color(0xFFFFE8B9),
              ),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: _MapSign(label: note!, size: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapSign extends StatelessWidget {
  const _MapSign({
    required this.label,
    this.icon,
    this.size = 14,
    this.color = const Color(0xFFFFE3AA),
    this.ink = const Color(0xFF3B5140),
  });

  final String label;
  final IconData? icon;
  final double size;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: const Color(0xC8A36F48), width: 1.2),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Color(0x49905C3D), offset: Offset(0, 2)),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size + 1, color: ink),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: size,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
