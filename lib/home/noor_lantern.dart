import 'package:flutter/material.dart';

enum NoorMood {
  idle('نور يبتسم'),
  happy('نور سعيد'),
  curious('نور فضولي'),
  thinking('نور يفكّر'),
  encouraging('نور يشجّعك'),
  celebrating('نور يحتفل');

  const NoorMood(this.label);

  final String label;
}

class NoorLantern extends StatelessWidget {
  const NoorLantern({super.key, required this.mood, this.size = 176});

  final NoorMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: mood.label,
      textDirection: TextDirection.rtl,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _LanternPainter(mood),
        ),
      ),
    );
  }
}

class NoorReaction extends StatefulWidget {
  const NoorReaction({
    super.key,
    required this.mood,
    required this.size,
    this.trigger = 0,
    this.playOnEntry = false,
  });

  final NoorMood mood;
  final double size;
  final int trigger;
  final bool playOnEntry;

  @override
  State<NoorReaction> createState() => _NoorReactionState();
}

class _NoorReactionState extends State<NoorReaction>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  bool _allowed = false;
  bool _entered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final active = TickerMode.valuesOf(context).enabled;
    _allowed = !reduceMotion && active;
    if (!_allowed && _motion.value != 0) _motion.reset();
    if (!_entered && widget.playOnEntry && _allowed) _motion.forward(from: 0);
    _entered = true;
  }

  @override
  void didUpdateWidget(NoorReaction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_allowed && oldWidget.trigger != widget.trigger) {
      _motion.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lantern = NoorLantern(mood: widget.mood, size: widget.size);
    if (!_allowed) return lantern;
    return AnimatedBuilder(
      animation: _motion,
      child: lantern,
      builder: (context, child) {
        final phase = _motion.value;
        return Transform.translate(
          offset: Offset(0, -phase * (1 - phase) * 24),
          child: child,
        );
      },
    );
  }
}

class _LanternPainter extends CustomPainter {
  const _LanternPainter(this.mood);

  final NoorMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 176, size.height / 176);
    final paint = Paint();
    const frame = Color(0xFF235349);
    const face = Color(0xFF332A24);
    const glass = Color(0xFFFFD575);

    canvas.drawCircle(
      const Offset(88, 89),
      69,
      paint..color = const Color(0xFFFFEDBC),
    );
    for (final (Offset center, double radius) in [
      (const Offset(28, 57), 7.0),
      (const Offset(149, 42), 9.0),
      (const Offset(151, 117), 5.0),
    ]) {
      final star = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius / 3, center.dy - radius / 3)
        ..lineTo(center.dx + radius, center.dy)
        ..lineTo(center.dx + radius / 3, center.dy + radius / 3)
        ..lineTo(center.dx, center.dy + radius)
        ..lineTo(center.dx - radius / 3, center.dy + radius / 3)
        ..lineTo(center.dx - radius, center.dy)
        ..lineTo(center.dx - radius / 3, center.dy - radius / 3)
        ..close();
      canvas.drawPath(star, paint..color = const Color(0xFFAC722C));
    }

    canvas.drawOval(
      const Rect.fromLTWH(45, 151, 86, 13),
      paint..color = const Color(0xFFE8C77F),
    );
    canvas.drawCircle(
      const Offset(88, 40),
      13,
      paint
        ..color = frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    final roof = Path()
      ..moveTo(48, 73)
      ..quadraticBezierTo(52, 61, 79, 47)
      ..quadraticBezierTo(88, 42, 97, 47)
      ..quadraticBezierTo(124, 61, 128, 73)
      ..close();
    canvas.drawPath(roof, paint..style = PaintingStyle.fill);
    canvas.drawRRect(
      RRect.fromLTRBR(50, 68, 126, 144, const Radius.circular(18)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(57, 75, 119, 137, const Radius.circular(13)),
      paint..color = glass,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(46, 137, 130, 150, const Radius.circular(6)),
      paint..color = frame,
    );

    for (final x in [73.0, 103.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 111), width: 12, height: 6),
        paint..color = const Color(0xFFF79A72),
      );
      final leftEye = x < 88;
      paint.color = face;
      final closed =
          mood == NoorMood.happy ||
          mood == NoorMood.celebrating ||
          (mood == NoorMood.encouraging && leftEye);
      if (closed) {
        _line(
          canvas,
          paint,
          Path()
            ..moveTo(x - 5, 101)
            ..quadraticBezierTo(x, 92, x + 5, 101),
        );
      } else {
        final horizontal = mood == NoorMood.thinking ? x + 3 : x;
        final vertical = mood == NoorMood.thinking ? 96.0 : 99.0;
        final tall = mood == NoorMood.curious;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(horizontal, vertical),
            width: tall ? 7 : 5,
            height: tall ? 11 : 8,
          ),
          paint,
        );
      }
      if ((mood == NoorMood.curious && !leftEye) ||
          (mood == NoorMood.thinking && leftEye)) {
        _line(
          canvas,
          paint,
          Path()
            ..moveTo(x - 5, 90)
            ..quadraticBezierTo(x, 85, x + 5, 89),
        );
      }
    }

    paint.color = face;
    switch (mood) {
      case NoorMood.curious:
        canvas.drawOval(const Rect.fromLTWH(84, 110, 8, 9), paint);
      case NoorMood.thinking:
        _line(
          canvas,
          paint,
          Path()
            ..moveTo(84, 115)
            ..quadraticBezierTo(90, 110, 95, 114),
        );
      case NoorMood.celebrating:
        canvas.drawPath(
          Path()
            ..moveTo(76, 108)
            ..quadraticBezierTo(88, 113, 100, 108)
            ..quadraticBezierTo(88, 134, 76, 108)
            ..close(),
          paint,
        );
      case NoorMood.idle:
      case NoorMood.happy:
      case NoorMood.encouraging:
        final width = mood == NoorMood.idle ? 7.0 : 10.0;
        final depth = mood == NoorMood.happy ? 130.0 : 122.0;
        _line(
          canvas,
          paint,
          Path()
            ..moveTo(88 - width, 109)
            ..quadraticBezierTo(88, depth, 88 + width, 109),
        );
    }
    canvas.restore();
  }

  void _line(Canvas canvas, Paint paint, Path path) {
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.8,
    );
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(_LanternPainter oldDelegate) => oldDelegate.mood != mood;
}
