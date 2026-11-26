import 'package:flutter/material.dart';

class NoorLantern extends StatelessWidget {
  const NoorLantern({super.key, required this.happy});

  final bool happy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: happy ? 'نور سعيد' : 'نور يبتسم',
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size.square(176),
          painter: _LanternPainter(happy),
        ),
      ),
    );
  }
}

class _LanternPainter extends CustomPainter {
  const _LanternPainter(this.happy);

  final bool happy;

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
      paint.color = face;
      if (happy) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 5, 101)
            ..quadraticBezierTo(x, 92, x + 5, 101),
          paint
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.8,
        );
        paint.style = PaintingStyle.fill;
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 99), width: 5, height: 8),
          paint,
        );
      }
    }

    final smileWidth = happy ? 10.0 : 7.0;
    canvas.drawPath(
      Path()
        ..moveTo(88 - smileWidth, 109)
        ..quadraticBezierTo(88, happy ? 129 : 122, 88 + smileWidth, 109),
      paint
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LanternPainter oldDelegate) => oldDelegate.happy != happy;
}
