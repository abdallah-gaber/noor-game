import 'package:flutter/material.dart';

import '../content/curriculum.dart';

class WorldArt extends StatelessWidget {
  const WorldArt(this.world, {super.key});

  final WorldId world;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _WorldPainter(world),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

extension WorldColors on WorldId {
  Color get wash => switch (this) {
    WorldId.iman => const Color(0xFFE8ECFA),
    WorldId.ibadah => const Color(0xFFE2F1EF),
    WorldId.seerah => const Color(0xFFFBEBD7),
    WorldId.exemplars => const Color(0xFFEAF1DD),
  };

  Color get ink => switch (this) {
    WorldId.iman => const Color(0xFF303A65),
    WorldId.ibadah => const Color(0xFF14535A),
    WorldId.seerah => const Color(0xFF774016),
    WorldId.exemplars => const Color(0xFF365227),
  };
}

class _WorldPainter extends CustomPainter {
  const _WorldPainter(this.world);

  final WorldId world;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = (size.width / 360).clamp(size.height / 140, double.infinity);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(
      (size.width - 360 * scale) / 2,
      (size.height - 140 * scale) / 2,
    );
    canvas.scale(scale);
    final scene = _Scene(canvas);
    switch (world) {
      case WorldId.iman:
        _starValley(scene);
      case WorldId.ibadah:
        _waterGarden(scene);
      case WorldId.seerah:
        _desertTrail(scene);
      case WorldId.exemplars:
        _palmGrove(scene);
    }
    canvas.restore();
  }

  void _starValley(_Scene s) {
    s.sky(const Color(0xFF394E81));
    s.circle(241, 45, 28, const Color(0xFFFBE4A9));
    s.circle(252, 35, 25, const Color(0xFF394E81));
    for (final (x, y, radius) in [
      (48.0, 29.0, 6.0),
      (101.0, 53.0, 4.0),
      (157.0, 22.0, 7.0),
      (308.0, 29.0, 5.0),
      (287.0, 76.0, 4.0),
    ]) {
      s.sparkle(x, y, radius, const Color(0xFFFFE8A5));
    }
    s.fill(
      Path()
        ..moveTo(0, 103)
        ..quadraticBezierTo(62, 45, 143, 111)
        ..quadraticBezierTo(239, 60, 360, 91)
        ..lineTo(360, 145)
        ..lineTo(0, 145)
        ..close(),
      const Color(0xFF6975A9),
    );
    s.fill(
      Path()
        ..moveTo(0, 118)
        ..quadraticBezierTo(93, 91, 152, 128)
        ..quadraticBezierTo(235, 85, 360, 115)
        ..lineTo(360, 145)
        ..lineTo(0, 145)
        ..close(),
      const Color(0xFF303A65),
    );
    for (final x in [190.0, 214.0, 243.0]) {
      s.circle(x, 127 - (x - 190) / 5, 2, const Color(0xFFF9D68E));
    }
  }

  void _waterGarden(_Scene s) {
    s.sky(const Color(0xFFA8D8D9));
    s.circle(76, 40, 21, const Color(0xFFFFF3C4));
    s.fill(
      Path()
        ..moveTo(0, 100)
        ..quadraticBezierTo(102, 67, 214, 106)
        ..quadraticBezierTo(295, 77, 360, 85)
        ..lineTo(360, 145)
        ..lineTo(0, 145)
        ..close(),
      const Color(0xFF6DAB92),
    );
    s.fill(
      Path()
        ..moveTo(119, 140)
        ..cubicTo(151, 120, 250, 102, 260, 89)
        ..cubicTo(281, 92, 280, 111, 208, 140)
        ..close(),
      const Color(0xFF7FD6DA),
    );
    s.fill(
      Path()
        ..moveTo(168, 89)
        ..lineTo(168, 60)
        ..lineTo(200, 35)
        ..lineTo(232, 60)
        ..lineTo(232, 89)
        ..close(),
      const Color(0xFF226871),
    );
    s.fill(
      Path()
        ..moveTo(190, 89)
        ..lineTo(190, 68)
        ..quadraticBezierTo(200, 51, 210, 68)
        ..lineTo(210, 89)
        ..close(),
      const Color(0xFFFFE7A7),
    );
    for (final (x, y) in [(48.0, 113.0), (83.0, 123.0), (302.0, 109.0)]) {
      s.leaves(x, y, const Color(0xFF286F63));
    }
  }

  void _desertTrail(_Scene s) {
    s.sky(const Color(0xFFF3CB8F));
    s.circle(267, 47, 30, const Color(0xFFFFEBB1));
    s.fill(
      Path()
        ..moveTo(0, 104)
        ..quadraticBezierTo(124, 39, 225, 96)
        ..quadraticBezierTo(315, 68, 360, 96)
        ..lineTo(360, 145)
        ..lineTo(0, 145)
        ..close(),
      const Color(0xFFE5A15E),
    );
    s.fill(
      Path()
        ..moveTo(0, 129)
        ..quadraticBezierTo(82, 85, 169, 116)
        ..quadraticBezierTo(260, 100, 360, 123)
        ..lineTo(360, 145)
        ..lineTo(0, 145)
        ..close(),
      const Color(0xFFCD8050),
    );
    s.stroke(
      Path()
        ..moveTo(80, 142)
        ..cubicTo(135, 110, 262, 135, 251, 103),
      const Color(0xFFF7D693),
      7,
    );
    s.leaves(62, 93, const Color(0xFF8B563D));
    s.leaves(304, 125, const Color(0xFF8B563D));
  }

  void _palmGrove(_Scene s) {
    s.sky(const Color(0xFFD4E6AB));
    s.circle(170, 43, 23, const Color(0xFFF9F0B8));
    s.fill(
      Path()
        ..moveTo(0, 98)
        ..quadraticBezierTo(136, 69, 203, 111)
        ..quadraticBezierTo(298, 69, 360, 102)
        ..lineTo(360, 145)
        ..lineTo(0, 145)
        ..close(),
      const Color(0xFFABC879),
    );
    s.fill(
      Path()
        ..moveTo(0, 126)
        ..quadraticBezierTo(88, 100, 176, 124)
        ..quadraticBezierTo(267, 98, 360, 123)
        ..lineTo(360, 145)
        ..lineTo(0, 145)
        ..close(),
      const Color(0xFF6F9B64),
    );
    for (final (x, y, height) in [
      (77.0, 117.0, 48.0),
      (116.0, 118.0, 30.0),
      (280.0, 116.0, 58.0),
    ]) {
      s.stroke(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x - 7, y - height / 2, x, y - height),
        const Color(0xFF735D3B),
        6,
      );
      s.leaves(x, y - height, const Color(0xFF477650), reach: 22);
      s.circle(x + 4, y - height + 6, 3, const Color(0xFFB67536));
    }
    s.sparkle(216, 62, 7, const Color(0xFFF9F0B8));
  }

  @override
  bool shouldRepaint(_WorldPainter oldDelegate) => world != oldDelegate.world;
}

class _Scene {
  _Scene(this.canvas);

  final Canvas canvas;
  final paint = Paint();

  void sky(Color color) => canvas.drawRect(
    const Rect.fromLTWH(0, 0, 360, 140),
    paint..color = color,
  );
  void circle(double x, double y, double radius, Color color) =>
      canvas.drawCircle(Offset(x, y), radius, paint..color = color);
  void fill(Path path, Color color) =>
      canvas.drawPath(path, paint..color = color);

  void stroke(Path path, Color color, double width) {
    canvas.drawPath(
      path,
      paint
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    paint.style = PaintingStyle.fill;
  }

  void sparkle(double x, double y, double r, Color color) {
    fill(
      Path()
        ..moveTo(x, y - r)
        ..quadraticBezierTo(x + 2, y - 2, x + r, y)
        ..quadraticBezierTo(x + 2, y + 2, x, y + r)
        ..quadraticBezierTo(x - 2, y + 2, x - r, y)
        ..quadraticBezierTo(x - 2, y - 2, x, y - r)
        ..close(),
      color,
    );
  }

  void leaves(double x, double y, Color color, {double reach = 12}) {
    for (final direction in [-1, 1]) {
      final end = x + reach * direction;
      fill(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(end, y - reach, end, y + reach / 3)
          ..quadraticBezierTo(x + 7 * direction, y, x, y)
          ..close(),
        color,
      );
    }
    fill(
      Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + reach / 2, y - reach, x, y - reach)
        ..quadraticBezierTo(x - reach / 2, y - reach, x, y)
        ..close(),
      color,
    );
  }
}
