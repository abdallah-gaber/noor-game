import 'dart:math' as math;

import 'package:flutter/material.dart';

class CourtyardPainter extends CustomPainter {
  const CourtyardPainter(
    this.drop,
    this.palms,
    this.unit, {
    this.flowing = false,
  });

  final Offset drop;
  final Offset palms;
  final double unit;
  final bool flowing;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ground = h * .66;
    final paint = Paint();
    canvas.drawRect(
      Offset.zero & size,
      paint
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD28D), Color(0xFFF4A876), Color(0xFFFFDDA5)],
        ).createShader(Offset.zero & size),
    );
    paint.shader = null;
    canvas.drawCircle(
      Offset(w * .77, h * .27),
      unit * .38,
      paint..color = const Color(0xFFFFE6A7),
    );
    final hills = Path()
      ..moveTo(0, ground)
      ..lineTo(0, h * .44)
      ..quadraticBezierTo(w * .16, h * .28, w * .37, h * .53)
      ..quadraticBezierTo(w * .67, h * .31, w, h * .47)
      ..lineTo(w, ground)
      ..close();
    canvas.drawPath(hills, paint..color = const Color(0xFFE39871));
    canvas.drawRect(
      Rect.fromLTRB(0, ground - 12, w, ground + 6),
      paint..color = const Color(0xFFDD8863),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, ground + 6, w, h),
      paint..color = const Color(0xFFFFCC91),
    );
    for (var i = -3; i <= 7; i++) {
      canvas.drawLine(
        Offset(w * .5 + i * w / 12, ground + 6),
        Offset(w * .5 + i * w / 5, h),
        paint
          ..color = const Color(0x35B76451)
          ..strokeWidth = 2,
      );
    }
    for (final y in [.74, .86]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * y), paint);
    }

    _plant(canvas, Offset(w * .065, h * .89), unit * .87);
    _plant(canvas, Offset(w * .94, h * .55), unit * .83);
    _plant(canvas, Offset(w * .85, h * .91), unit * .59);

    // The arch, tap and water bowl share the droplet's visual anchor.
    canvas.save();
    canvas.translate(drop.dx, drop.dy);
    canvas.scale(unit / 100);
    final arch = Path()
      ..moveTo(-69, 66)
      ..lineTo(-69, -67)
      ..cubicTo(-69, -100, -33, -115, 0, -135)
      ..cubicTo(33, -115, 69, -100, 69, -67)
      ..lineTo(69, 66)
      ..close();
    canvas.drawPath(arch, paint..color = const Color(0xFFBE6F53));
    canvas.save();
    canvas.translate(0, -4);
    canvas.scale(.88, .88);
    canvas.drawPath(arch, paint..color = const Color(0xFF457E76));
    canvas.clipPath(arch);
    for (var row = -6; row <= 2; row++) {
      for (var col = -3; col <= 3; col++) {
        final x = col * 24.0 + (row.isEven ? 12 : 0);
        final y = row * 24.0;
        final tile = Path()
          ..moveTo(x, y - 10)
          ..lineTo(x + 9, y)
          ..lineTo(x, y + 10)
          ..lineTo(x - 9, y)
          ..close();
        canvas.drawPath(tile, paint..color = const Color(0xFF68A499));
        canvas.drawCircle(
          Offset(x, y),
          2,
          paint..color = const Color(0xFFF1C483),
        );
      }
    }
    canvas.restore();
    final spout = Path()
      ..moveTo(-25, -64)
      ..lineTo(1, -64)
      ..quadraticBezierTo(19, -64, 19, -48)
      ..lineTo(19, -40);
    paint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15
      ..color = const Color(0xFF704731);
    canvas.drawPath(spout, paint);
    canvas.drawPath(
      spout,
      paint
        ..strokeWidth = 9
        ..color = const Color(0xFFFFCB62),
    );
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-36, -78, 22, 27),
        const Radius.circular(6),
      ),
      paint..color = const Color(0xFFE9A651),
    );
    if (flowing) {
      for (final (x, y) in [(19.0, 25.0), (16.0, 51.0), (24.0, 63.0)]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 6, height: 13),
            const Radius.circular(3),
          ),
          paint..color = const Color(0xFFB8F9EF),
        );
      }
    }
    _bowl(canvas, 72, 74, paint);
    canvas.restore();

    canvas.save();
    canvas.translate(palms.dx, palms.dy);
    canvas.scale(unit / 100);
    _bowl(canvas, 46, 77, paint);
    canvas.restore();
  }

  void _bowl(Canvas canvas, double y, double radius, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, y + 35),
        width: radius * 2.14,
        height: 18,
      ),
      paint..color = const Color(0x30572929),
    );
    final body = Path()
      ..moveTo(-radius, y)
      ..quadraticBezierTo(-radius * .74, y + 42, 0, y + 40)
      ..quadraticBezierTo(radius * .74, y + 42, radius, y)
      ..close();
    canvas.drawPath(body, paint..color = const Color(0xFF29766C));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, y), width: radius * 2, height: 30),
      paint..color = const Color(0xFFFFE0A8),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, y), width: radius * 1.8, height: 20),
      paint..color = const Color(0xFF69D8D4),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * .26, y - 2),
        width: radius * .58,
        height: 3,
      ),
      paint..color = const Color(0xFFCDF9ED),
    );
  }

  void _plant(Canvas canvas, Offset base, double size) {
    final paint = Paint();
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(size / 100);
    canvas.drawOval(
      const Rect.fromLTWH(-35, -7, 70, 12),
      paint..color = const Color(0x30572929),
    );
    final pot = Path()
      ..moveTo(-26, -31)
      ..lineTo(-18, -1)
      ..quadraticBezierTo(0, 9, 18, -1)
      ..lineTo(26, -31)
      ..close();
    canvas.drawPath(pot, paint..color = const Color(0xFFC66A4F));
    for (final (x, y) in [
      (-33.0, -69.0),
      (-21.0, -89.0),
      (6.0, -100.0),
      (32.0, -79.0),
      (38.0, -55.0),
    ]) {
      final leaf = Path()
        ..moveTo(0, -30)
        ..quadraticBezierTo(x - 17, y + 12, x, y)
        ..quadraticBezierTo(x + 21, y + 4, 0, -30);
      canvas.drawPath(
        leaf,
        paint..color = Color(x < 0 ? 0xFF428779 : 0xFF559A6D),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-29, -36, 58, 10),
        const Radius.circular(4),
      ),
      paint..color = const Color(0xFFE38A5B),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CourtyardPainter oldDelegate) =>
      drop != oldDelegate.drop ||
      palms != oldDelegate.palms ||
      unit != oldDelegate.unit ||
      flowing != oldDelegate.flowing;
}

class DropArt extends StatelessWidget {
  const DropArt({super.key, required this.size, required this.selected});

  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _DropPainter(selected));
}

class _DropPainter extends CustomPainter {
  const _DropPainter(this.selected);

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint();
    const center = Offset(50, 50);
    canvas.drawCircle(center, 46, paint..color = const Color(0x45FFF7C9));
    canvas.drawCircle(
      center,
      38,
      paint
        ..color = selected ? const Color(0xFFFFCE68) : const Color(0xFFE6FCF0),
    );
    final drop = Path()
      ..moveTo(50, 21)
      ..cubicTo(46, 35, 28, 45, 28, 60)
      ..cubicTo(28, 85, 72, 85, 72, 60)
      ..cubicTo(72, 45, 55, 35, 50, 21)
      ..close();
    canvas.drawPath(drop, paint..color = const Color(0xFF257E96));
    canvas.drawPath(
      drop.shift(const Offset(0, -3)),
      paint..color = const Color(0xFF43BFDA),
    );
    canvas.drawOval(
      const Rect.fromLTWH(37, 48, 8, 13),
      paint..color = const Color(0xFFC5FAF5),
    );
  }

  @override
  bool shouldRepaint(_DropPainter oldDelegate) =>
      selected != oldDelegate.selected;
}

class PalmsPainter extends CustomPainter {
  const PalmsPainter({
    required this.active,
    required this.washed,
    required this.splash,
  });

  final bool active;
  final bool washed;
  final double splash;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 142, size.height / 142);
    final paint = Paint();
    const center = Offset(71, 70);
    canvas.drawCircle(
      center,
      active ? 62 : 53,
      paint..color = const Color(0x4DFFF0B6),
    );
    canvas.drawCircle(
      center,
      51,
      paint..color = active ? const Color(0xFFFFD675) : const Color(0xFFFFF0CF),
    );
    final hand = Path()
      ..moveTo(47, 99)
      ..quadraticBezierTo(36, 91, 34, 78)
      ..lineTo(30, 66)
      ..quadraticBezierTo(29, 59, 35, 62)
      ..lineTo(41, 69)
      ..lineTo(38, 49)
      ..quadraticBezierTo(38, 43, 43, 45)
      ..lineTo(48, 61)
      ..lineTo(46, 43)
      ..quadraticBezierTo(47, 37, 52, 41)
      ..lineTo(56, 60)
      ..lineTo(57, 46)
      ..quadraticBezierTo(60, 41, 63, 47)
      ..lineTo(64, 66)
      ..quadraticBezierTo(67, 55, 71, 59)
      ..quadraticBezierTo(73, 64, 69, 77)
      ..quadraticBezierTo(68, 88, 61, 97)
      ..lineTo(58, 105)
      ..close();
    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) {
        canvas.translate(142, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawPath(
        hand,
        paint
          ..color = const Color(0xFF9E573C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        hand,
        paint
          ..color = const Color(0xFFFFAD77)
          ..style = PaintingStyle.fill,
      );
      canvas.drawArc(
        const Rect.fromLTWH(46, 70, 15, 13),
        3.65,
        2,
        false,
        paint
          ..color = const Color(0xFFD87955)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      paint.style = PaintingStyle.fill;
      canvas.restore();
    }

    if (washed) {
      canvas.drawCircle(
        const Offset(111, 102),
        16,
        paint..color = const Color(0xFF237965),
      );
      final check = Path()
        ..moveTo(104, 102)
        ..lineTo(109, 107)
        ..lineTo(118, 97);
      canvas.drawPath(
        check,
        paint
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3,
      );
      paint.style = PaintingStyle.fill;
    }
    if (splash > 0 && splash < 1) {
      final distance = 23 + Curves.easeOut.transform(splash) * 45;
      for (var index = 0; index < 12; index++) {
        final angle = index * math.pi / 6;
        final offset = Offset(
          math.cos(angle) * distance,
          math.sin(angle) * distance,
        );
        canvas.drawCircle(
          center + offset,
          (index.isEven ? 6 : 4) * (1 - splash * .65),
          paint
            ..color =
                (index.isEven
                        ? const Color(0xFF29AFD4)
                        : const Color(0xFFFEBA46))
                    .withValues(alpha: 1 - splash),
        );
      }
    }
  }

  @override
  bool shouldRepaint(PalmsPainter oldDelegate) =>
      active != oldDelegate.active ||
      washed != oldDelegate.washed ||
      splash != oldDelegate.splash;
}
