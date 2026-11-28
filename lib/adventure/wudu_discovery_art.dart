import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'wudu_discovery.dart';

class DiscoveryObjectPainter extends CustomPainter {
  const DiscoveryObjectPainter({
    required this.object,
    required this.done,
    required this.highlighted,
    required this.phase,
    this.wipeProgress = 0,
  });

  final WuduObject object;
  final bool done;
  final bool highlighted;
  final double phase;
  final double wipeProgress;

  static const _outline = Color(0xFF275A51);
  static const _skin = Color(0xFFFFB77E);
  static const _water = Color(0xFF38A7C7);
  static const _wipe = Color(0xFF247960);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 120);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const center = Offset(60, 60);
    final isHead = object == WuduObject.head;
    final isTap = object == WuduObject.tap;
    canvas.drawCircle(center, 56, paint..color = const Color(0x56FFF6D7));
    canvas.drawCircle(
      center,
      49,
      paint
        ..color = highlighted
            ? const Color(0xFFFFD574)
            : const Color(0xFFFFF0CF),
    );
    canvas.drawCircle(
      center,
      49,
      paint
        ..color = const Color(0xFFD89E69)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    paint.style = PaintingStyle.fill;

    switch (object) {
      case WuduObject.mouth:
        _shape(
          canvas,
          paint,
          Path()
            ..moveTo(34, 54)
            ..quadraticBezierTo(51, 41, 60, 50)
            ..quadraticBezierTo(69, 41, 86, 54)
            ..quadraticBezierTo(75, 79, 60, 77)
            ..quadraticBezierTo(45, 79, 34, 54)
            ..close(),
          const Color(0xFFDE816D),
        );
        _line(
          canvas,
          paint,
          Path()
            ..moveTo(42, 56)
            ..quadraticBezierTo(60, 66, 78, 56),
          const Color(0xFF963F40),
          3,
        );
      case WuduObject.nose:
        _shape(
          canvas,
          paint,
          Path()
            ..moveTo(53, 35)
            ..quadraticBezierTo(52, 52, 43, 63)
            ..quadraticBezierTo(40, 72, 50, 73)
            ..quadraticBezierTo(60, 86, 70, 73)
            ..quadraticBezierTo(80, 72, 77, 63)
            ..quadraticBezierTo(68, 52, 67, 35),
          _skin,
        );
        for (final x in [52.0, 68.0]) {
          canvas.drawCircle(Offset(x, 70), 2.5, paint..color = _outline);
        }
      case WuduObject.face:
      case WuduObject.head:
        _face(canvas, paint, isHead);
      case WuduObject.rightArm:
      case WuduObject.leftArm:
        _arm(canvas, paint, object == WuduObject.leftArm);
      case WuduObject.rightFoot:
      case WuduObject.leftFoot:
        _foot(canvas, paint, object == WuduObject.leftFoot);
      case WuduObject.tap:
        _tap(canvas, paint);
      case WuduObject.palms:
        break; // The original courtyard palms have their own painter.
    }

    if (isHead) {
      _wipeTrail(canvas, paint);
    } else if (done && !isTap) {
      _splash(canvas, paint);
    }

    if (done) {
      const badge = Offset(95, 94);
      canvas.drawCircle(badge, 13, paint..color = _wipe);
      _line(
        canvas,
        paint,
        Path()
          ..moveTo(90, 94)
          ..lineTo(94, 98)
          ..lineTo(101, 90),
        Colors.white,
        2.7,
      );
    }
  }

  void _face(Canvas canvas, Paint paint, bool head) {
    canvas.drawOval(
      const Rect.fromLTWH(33, 29, 54, 65),
      paint..color = _outline,
    );
    canvas.drawOval(const Rect.fromLTWH(36, 32, 48, 59), paint..color = _skin);
    _shape(
      canvas,
      paint,
      Path()
        ..moveTo(36, 52)
        ..cubicTo(31, 28, 52, 22, 65, 28)
        ..cubicTo(82, 26, 88, 41, 84, 53)
        ..quadraticBezierTo(73, 51, 68, 42)
        ..quadraticBezierTo(56, 53, 36, 52)
        ..close(),
      const Color(0xFF554436),
    );
    for (final x in [50.0, 70.0]) {
      canvas.drawCircle(Offset(x, 61), 2.6, paint..color = _outline);
    }
    _line(
      canvas,
      paint,
      Path()
        ..moveTo(54, 73)
        ..quadraticBezierTo(60, 80, 66, 73),
      _outline,
      2.4,
    );
    if (!head && done) {
      for (final x in [46.0, 74.0]) {
        canvas.drawCircle(Offset(x, 70), 3, paint..color = _water);
      }
    }
  }

  void _arm(Canvas canvas, Paint paint, bool mirror) {
    canvas.save();
    if (mirror) {
      canvas.translate(120, 0);
      canvas.scale(-1, 1);
    }
    _shape(
      canvas,
      paint,
      Path()
        ..moveTo(30, 77)
        ..quadraticBezierTo(35, 63, 47, 58)
        ..lineTo(69, 42)
        ..lineTo(70, 32)
        ..quadraticBezierTo(74, 27, 77, 35)
        ..lineTo(83, 31)
        ..quadraticBezierTo(91, 29, 91, 37)
        ..quadraticBezierTo(86, 48, 79, 53)
        ..lineTo(53, 84)
        ..quadraticBezierTo(46, 95, 30, 84)
        ..close(),
      _skin,
    );
    _shape(
      canvas,
      paint,
      Path()
        ..moveTo(31, 71)
        ..quadraticBezierTo(44, 73, 54, 85)
        ..lineTo(47, 94)
        ..quadraticBezierTo(29, 91, 24, 82)
        ..close(),
      const Color(0xFF62A48A),
    );
    if (done) {
      _line(
        canvas,
        paint,
        Path()
          ..moveTo(50, 67)
          ..quadraticBezierTo(60, 64, 68, 53),
        _water,
        3,
      );
    }
    canvas.restore();
  }

  void _foot(Canvas canvas, Paint paint, bool mirror) {
    canvas.save();
    if (mirror) {
      canvas.translate(120, 0);
      canvas.scale(-1, 1);
    }
    _shape(
      canvas,
      paint,
      Path()
        ..moveTo(48, 32)
        ..quadraticBezierTo(54, 25, 64, 32)
        ..lineTo(65, 52)
        ..quadraticBezierTo(75, 59, 81, 55)
        ..quadraticBezierTo(94, 54, 93, 65)
        ..quadraticBezierTo(90, 75, 74, 77)
        ..lineTo(52, 86)
        ..quadraticBezierTo(35, 88, 37, 73)
        ..lineTo(43, 56)
        ..close(),
      _skin,
    );
    _line(
      canvas,
      paint,
      Path()
        ..moveTo(51, 55)
        ..quadraticBezierTo(57, 51, 63, 55),
      const Color(0xFFC37458),
      2.5,
    );
    if (done) {
      _line(
        canvas,
        paint,
        Path()
          ..moveTo(47, 73)
          ..quadraticBezierTo(59, 72, 72, 64),
        _water,
        3,
      );
    }
    canvas.restore();
  }

  void _tap(Canvas canvas, Paint paint) {
    final spout = Path()
      ..moveTo(34, 60)
      ..lineTo(68, 60)
      ..quadraticBezierTo(84, 60, 84, 75);
    _line(canvas, paint, spout, _outline, 18);
    _line(canvas, paint, spout, const Color(0xFFF5BB59), 12);
    _line(
      canvas,
      paint,
      Path()
        ..moveTo(54, 56)
        ..lineTo(54, 43),
      _outline,
      8,
    );
    canvas.save();
    canvas.translate(54, 41);
    canvas.rotate(done ? -.85 : .16);
    _line(
      canvas,
      paint,
      Path()
        ..moveTo(-14, 0)
        ..lineTo(14, 0),
      _outline,
      11,
    );
    _line(
      canvas,
      paint,
      Path()
        ..moveTo(-14, 0)
        ..lineTo(14, 0),
      const Color(0xFFFFCE75),
      6,
    );
    canvas.restore();
    if (!done) {
      canvas.drawOval(
        const Rect.fromLTWH(81, 85, 6, 10),
        paint..color = _water,
      );
    }
  }

  void _wipeTrail(Canvas canvas, Paint paint) {
    final sweep = Path()
      ..moveTo(31, 41)
      ..quadraticBezierTo(60, 14, 89, 41);
    _line(canvas, paint, sweep, const Color(0xCCFFFCF0), 3);
    if (done || wipeProgress != 0) {
      final stroke = sweep.computeMetrics().first;
      final amount = done
          ? (phase > 0 && phase < 1
                ? .4 + .6 * Curves.easeOut.transform(phase)
                : 1.0)
          : wipeProgress.abs();
      final traced = stroke.length * amount;
      _line(
        canvas,
        paint,
        wipeProgress < 0
            ? stroke.extractPath(stroke.length - traced, stroke.length)
            : stroke.extractPath(0, traced),
        done ? _wipe : const Color(0xFF54AD9A),
        5,
      );
    } else {
      _line(
        canvas,
        paint,
        Path()
          ..moveTo(82, 41)
          ..lineTo(89, 41)
          ..lineTo(87, 34),
        const Color(0xCCFFFCF0),
        3,
      );
    }
  }

  void _splash(Canvas canvas, Paint paint) {
    final animated = phase > 0 && phase < 1;
    final travel = animated ? Curves.easeOutCubic.transform(phase) : 1.0;
    final radius = 22 + travel * 22;
    if (animated) {
      final wave = Rect.fromCenter(
        center: const Offset(60, 70),
        width: 21 + 67 * travel,
        height: 9 + 22 * travel,
      );
      canvas.drawArc(
        wave,
        .1,
        math.pi - .2,
        false,
        paint
          ..color = const Color(0xFF76D1DC).withValues(alpha: .72 * (1 - phase))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
      paint.style = PaintingStyle.fill;
    }
    for (final (index, angle) in [-2.8, -2.1, -1.3, -.5, .3, 2.9].indexed) {
      final location = Offset(
        60 + radius * math.cos(angle),
        61 + radius * math.sin(angle),
      );
      final length = animated ? 8 - phase * 3 : 5.2;
      canvas.drawOval(
        Rect.fromCenter(center: location, width: length * .69, height: length),
        paint
          ..color = index.isEven
              ? const Color(0xFF40AEC5)
              : const Color(0xFF78CED3),
      );
    }
  }

  void _shape(Canvas canvas, Paint paint, Path path, Color fill) {
    canvas.drawPath(path, paint..color = fill);
    _line(canvas, paint, path, _outline, 2.6);
  }

  void _line(Canvas canvas, Paint paint, Path path, Color color, double width) {
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = width,
    );
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(DiscoveryObjectPainter oldDelegate) =>
      object != oldDelegate.object ||
      done != oldDelegate.done ||
      highlighted != oldDelegate.highlighted ||
      phase != oldDelegate.phase ||
      wipeProgress != oldDelegate.wipeProgress;
}
