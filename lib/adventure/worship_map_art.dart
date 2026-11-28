import 'dart:math' as math;

import 'package:flutter/material.dart';

enum WorshipLandmark { fountain, arcade, gate, challenge }

typedef WorshipMapLocations = ({
  Offset fountain,
  Offset arcade,
  Offset gate,
  Offset challenge,
  Offset noor,
});

class WorshipMapPainter extends CustomPainter {
  const WorshipMapPainter(this.locations, {required this.wide});

  final WorshipMapLocations locations;
  final bool wide;

  @override
  void paint(Canvas canvas, Size size) {
    final art = _Brush(canvas);
    final w = size.width;
    final h = size.height;
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .43, 1],
          colors: [Color(0xFFFFDB95), Color(0xFFECC17F), Color(0xFFD9A46B)],
        ).createShader(bounds),
    );
    art.oval(w * .79, h * .12, h * .16, h * .16, 0xFFFFE7AB);

    for (final (y, height, color) in [
      (.21, .15, 0xFFDDA77B),
      (.28, .11, 0xFFCF9476),
      (.34, .11, 0xFFBC8168),
    ]) {
      art.shape(
        Path()
          ..moveTo(0, h * (y + height))
          ..cubicTo(
            w * .16,
            h * (y - height),
            w * .31,
            h * y,
            w * .42,
            h * (y + height / 2),
          )
          ..cubicTo(
            w * .63,
            h * (y + height),
            w * .77,
            h * (y - height),
            w,
            h * y,
          )
          ..lineTo(w, h * .56)
          ..lineTo(0, h * .56)
          ..close(),
        color,
      );
    }

    final courtyard = Path()
      ..moveTo(0, h * .38)
      ..cubicTo(w * .26, h * .30, w * .55, h * .42, w, h * .31)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    art.shape(courtyard, 0xFFE7B97D);
    final wall = Path()
      ..moveTo(0, h * .38)
      ..cubicTo(w * .26, h * .30, w * .55, h * .42, w, h * .31);
    art.line(wall, 0xFFA36E56, 14);
    art.line(wall.shift(const Offset(0, -4)), 0xFFEFC98B, 8);
    for (final segment in wall.computeMetrics()) {
      for (var distance = 10.0; distance < segment.length; distance += 41) {
        final spot = segment.getTangentForOffset(distance)!.position;
        art.box(
          Rect.fromCenter(center: spot.translate(0, -7), width: 13, height: 14),
          2,
          0xFFECC18A,
        );
        art.box(
          Rect.fromCenter(center: spot.translate(0, -12), width: 16, height: 4),
          1.5,
          0xFFF5D49E,
        );
      }
    }

    final ground = Path()
      ..moveTo(0, h * .70)
      ..cubicTo(w * .27, h * .56, w * .58, h * .94, w, h * .72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    art.shape(ground, 0xFFD9AA71);

    final f = locations.fountain;
    final a = locations.arcade;
    final g = locations.gate;
    final t = locations.challenge;
    final n = locations.noor;
    final pathWidth = wide ? h * .093 : w * .135;
    final mainPath = Path()
      ..moveTo(wide ? w * .91 : w * .39, h * 1.04)
      ..cubicTo(
        n.dx + w * .07,
        n.dy + h * .04,
        t.dx + w * .15,
        t.dy + h * .08,
        t.dx,
        t.dy,
      )
      ..cubicTo(
        f.dx + w * .18,
        t.dy - h * .07,
        f.dx - w * .13,
        f.dy + h * .16,
        f.dx,
        f.dy,
      );
    final westPath = Path()
      ..moveTo(f.dx, f.dy)
      ..cubicTo(
        f.dx - w * .13,
        f.dy + h * .12,
        a.dx - w * .05,
        a.dy + h * .17,
        a.dx,
        a.dy,
      );
    final eastPath = Path()
      ..moveTo(f.dx, f.dy)
      ..cubicTo(
        f.dx + w * .11,
        f.dy - h * .18,
        g.dx - w * .08,
        g.dy + h * .17,
        g.dx,
        g.dy,
      );

    for (final path in [westPath, eastPath, mainPath]) {
      art.line(path, 0xFFC08D61, pathWidth + 5);
      art.line(path, 0xFFF1CB8E, pathWidth);
      art.line(path.shift(const Offset(1, -3)), 0xFFF7D59C, pathWidth * .64);
    }
    for (final metric in mainPath.computeMetrics()) {
      for (var d = 18.0; d < metric.length; d += pathWidth * .67) {
        final p = metric.getTangentForOffset(d)!.position;
        art.oval(p.dx, p.dy, 7, 4, 0xFFD1A374);
      }
    }

    for (final (x, y, scale, flip)
        in (wide
            ? [
                (.10, .64, .90, false),
                (.29, .30, .72, true),
                (.72, .43, .73, false),
                (.93, .47, .88, true),
                (.12, .88, 1.08, true),
                (.62, .92, .64, false),
              ]
            : [
                (.12, .49, .72, true),
                (.41, .22, .59, false),
                (.91, .39, .75, true),
                (.85, .57, .66, false),
                (.11, .88, .86, true),
                (.94, .89, 1.0, false),
              ])) {
      _palm(
        art,
        Offset(w * x, h * y),
        math.min(w, h) * .20 * scale,
        flip: flip,
      );
    }
    for (final (x, y, scale) in [
      (.07, .30, 1.0),
      (.07, .72, .8),
      (.17, .94, 1.24),
      (.28, .68, .72),
      (.37, .87, .75),
      (.39, .38, .7),
      (.53, .29, 1.0),
      (.59, .83, .75),
      (.72, .94, 1.15),
      (.71, .55, .65),
      (.94, .65, 1.2),
      (.95, .27, .73),
    ]) {
      _shrubs(art, Offset(w * x, h * y), math.min(w, h) * .085 * scale);
    }

    for (final (x, y) in [
      (.045, .53),
      (.085, .82),
      (.19, .92),
      (.24, .68),
      (.29, .56),
      (.34, .81),
      (.38, .96),
      (.41, .74),
      (.47, .85),
      (.53, .95),
      (.60, .66),
      (.64, .91),
      (.68, .32),
      (.78, .84),
      (.82, .57),
      (.87, .92),
      (.95, .72),
      (.96, .94),
    ]) {
      art.oval(w * x, h * y, 6, 3, 0xFFBE8B60);
      art.oval(w * x + 6, h * y - 5, 3, 2, 0xFFFFD99D);
    }

    final frame = RRect.fromRectAndRadius(
      bounds.deflate(8),
      const Radius.circular(22),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..color = const Color(0x80905D42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (final point in [
      Offset(21, 21),
      Offset(w - 21, 21),
      Offset(21, h - 21),
      Offset(w - 21, h - 21),
    ]) {
      art.shape(
        Path()
          ..moveTo(point.dx, point.dy - 5)
          ..lineTo(point.dx + 5, point.dy)
          ..lineTo(point.dx, point.dy + 5)
          ..lineTo(point.dx - 5, point.dy)
          ..close(),
        0xFFE8C989,
      );
    }

    final compass = Offset(w * .09, h * .13);
    if (wide) {
      art.oval(compass.dx, compass.dy, 31, 31, 0x68FFF1BD);
      art.shape(
        Path()
          ..moveTo(compass.dx, compass.dy - 14)
          ..lineTo(compass.dx + 4, compass.dy - 2)
          ..lineTo(compass.dx + 12, compass.dy)
          ..lineTo(compass.dx + 4, compass.dy + 3)
          ..lineTo(compass.dx, compass.dy + 11)
          ..lineTo(compass.dx - 3, compass.dy + 3)
          ..lineTo(compass.dx - 12, compass.dy)
          ..lineTo(compass.dx - 3, compass.dy - 3)
          ..close(),
        0xFFA36E50,
      );
    }
  }

  void _palm(_Brush art, Offset base, double size, {required bool flip}) {
    final canvas = art.canvas;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(flip ? -size / 100 : size / 100, size / 100);
    art.oval(5, -2, 58, 15, 0x469A6548);
    art.shape(
      Path()
        ..moveTo(-8, 0)
        ..quadraticBezierTo(-4, -38, 14, -71)
        ..lineTo(23, -70)
        ..quadraticBezierTo(8, -38, 5, 0)
        ..close(),
      0xFFA96947,
    );
    for (final (x, y) in [
      (-1.0, -12.0),
      (2.5, -25.0),
      (7.0, -37.0),
      (12.0, -50.0),
    ]) {
      art.line(
        Path()
          ..moveTo(x - 6, y - 3)
          ..lineTo(x + 5, y + 1),
        0xFFD29A63,
        2.5,
      );
    }

    for (final (x, y, lift, paint) in [
      (-28.0, -60.0, 16.0, 0xFF517750),
      (-26.0, -86.0, 16.0, 0xFF688659),
      (-7.0, -104.0, 13.0, 0xFF64885B),
      (32.0, -107.0, 12.0, 0xFF547C52),
      (58.0, -90.0, 17.0, 0xFF799965),
      (57.0, -65.0, 18.0, 0xFF4F7954),
      (35.0, -49.0, 12.0, 0xFF668659),
    ]) {
      art.shape(
        Path()
          ..moveTo(18, -73)
          ..quadraticBezierTo((18 + x) / 2, (y - 73) / 2 - lift, x, y)
          ..quadraticBezierTo(x + (18 - x) / 3, y + lift, 18, -73)
          ..close(),
        paint,
      );
    }
    art.oval(16, -69, 8, 9, 0xFF97603F);
    art.oval(23, -68, 7, 8, 0xFFAA7545);
    canvas.restore();
  }

  void _shrubs(_Brush art, Offset base, double size) {
    final canvas = art.canvas;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(size / 80);
    art.oval(0, 2, 77, 18, 0x409C714D);
    for (final (x, y, width, height, paint) in [
      (-24.0, -7.0, 32.0, 20.0, 0xFF748F5B),
      (-5.0, -17.0, 38.0, 36.0, 0xFF638459),
      (19.0, -9.0, 28.0, 26.0, 0xFF79935A),
      (3.0, -4.0, 52.0, 16.0, 0xFF849F60),
    ]) {
      art.oval(x, y, width, height, paint);
    }
    for (final (x, y) in [(-19.0, -9.0), (0.0, -22.0), (14.0, -10.0)]) {
      art.oval(x, y, 6, 5, 0xFFEDC47D);
      art.oval(x + 4, y + 3, 3, 3, 0xFFF5DCAB);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(WorshipMapPainter oldDelegate) =>
      oldDelegate.locations != locations || oldDelegate.wide != wide;
}

class WorshipLandmarkPainter extends CustomPainter {
  const WorshipLandmarkPainter(this.landmark, {this.accent = false});

  final WorshipLandmark landmark;
  final bool accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 148);
    final art = _Brush(canvas);
    switch (landmark) {
      case WorshipLandmark.fountain:
        _fountain(art);
      case WorshipLandmark.arcade:
        _arcade(art);
      case WorshipLandmark.gate:
        _gate(art);
      case WorshipLandmark.challenge:
        _challenge(art);
    }
    canvas.restore();
  }

  void _fountain(_Brush art) {
    art.oval(80, 127, 153, 29, 0x4A8B5B43);
    art.oval(80, 115, 149, 51, 0xFFAC7757);
    art.oval(80, 110, 147, 46, 0xFFF4D497);
    art.oval(80, 110, 129, 39, 0xFFBC9365);
    art.oval(80, 108, 119, 34, 0xFFEAC78D);
    for (var i = 0; i < 12; i++) {
      final angle = i / 12 * 2 * math.pi;
      final x = 80 + math.cos(angle) * 63;
      final y = 108 + math.sin(angle) * 19;
      art.shape(
        Path()
          ..moveTo(x, y - 3)
          ..lineTo(x + 4, y)
          ..lineTo(x, y + 3)
          ..lineTo(x - 4, y)
          ..close(),
        0xFF9A8061,
      );
    }
    art.shape(
      Path()
        ..moveTo(27, 86)
        ..quadraticBezierTo(31, 118, 80, 122)
        ..quadraticBezierTo(129, 118, 133, 86)
        ..close(),
      0xFF538579,
    );
    art.oval(80, 86, 106, 41, 0xFF345F56);
    art.oval(80, 85, 101, 38, 0xFFFCE2A7);
    art.oval(80, 87, 91, 29, 0xFF4A9991);
    art.oval(80, 85, 86, 25, 0xFF85BB9D);
    for (final (x, y, width) in [
      (43.0, 86.0, 12.0),
      (102.0, 90.0, 21.0),
      (64.0, 94.0, 17.0),
    ]) {
      art.line(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + width / 2, y + 2, x + width, y),
        0xFFE2EBC2,
        2,
      );
    }
    art.oval(80, 84, 23, 10, 0xFF688D76);
    art.box(const Rect.fromLTWH(73, 53, 14, 30), 3, 0xFFC69C68);
    art.box(const Rect.fromLTWH(74, 55, 4, 24), 2, 0xFFF3D69C);
    art.oval(80, 55, 38, 15, 0xFFAD7D59);
    art.oval(80, 50, 38, 14, 0xFFFFDDA1);
    art.oval(80, 51, 28, 8, 0xFF67A993);
    final spray = Path()
      ..moveTo(80, 52)
      ..quadraticBezierTo(79, 31, 66, 44)
      ..moveTo(80, 51)
      ..quadraticBezierTo(83, 29, 94, 46);
    art.line(spray, 0xFF468875, 4.2);
    art.line(spray.shift(const Offset(0, -1)), 0xFFDBF2CD, 2.2);
    art.oval(81, 32, 4, 6, 0xFFFFF0CB);

    if (accent) {
      for (final (x, y) in [(23.0, 54.0), (126.0, 43.0), (140.0, 65.0)]) {
        art.shape(
          Path()
            ..moveTo(x, y - 8)
            ..quadraticBezierTo(x + 2, y - 2, x + 7, y)
            ..quadraticBezierTo(x + 2, y + 2, x, y + 8)
            ..quadraticBezierTo(x - 2, y + 2, x - 7, y)
            ..quadraticBezierTo(x - 2, y - 2, x, y - 8)
            ..close(),
          0xFFFFE4A6,
        );
      }
    }
  }

  void _arcade(_Brush art) {
    art.oval(80, 127, 139, 25, 0x3D8B5B43);
    art.box(const Rect.fromLTWH(18, 113, 125, 16), 4, 0xFFB98663);
    art.box(const Rect.fromLTWH(20, 56, 119, 62), 7, 0xFFE4B783);
    art.box(const Rect.fromLTWH(24, 60, 111, 8), 3, 0xFFF3D29D);
    for (final x in [44.0, 80.0, 116.0]) {
      art.shape(_arch(x, 76, 16, 44), 0xFFAA825F);
      art.shape(_arch(x, 83, 11, 35), 0xFF725E54);
      art.box(Rect.fromLTWH(x - 21, 110, 8, 12), 2, 0xFFC38F67);
    }
    art.shape(
      Path()
        ..moveTo(43, 59)
        ..quadraticBezierTo(44, 25, 80, 20)
        ..quadraticBezierTo(116, 25, 117, 59)
        ..close(),
      0xFF9A725C,
    );
    art.shape(
      Path()
        ..moveTo(46, 55)
        ..quadraticBezierTo(47, 30, 80, 23)
        ..quadraticBezierTo(113, 30, 114, 55)
        ..close(),
      0xFFAE8767,
    );
    art.line(
      Path()
        ..moveTo(56, 53)
        ..quadraticBezierTo(59, 31, 80, 25),
      0xFFD6AD80,
      3,
    );
    art.oval(80, 20, 8, 8, 0xFFD5A577);
    art.oval(25, 118, 15, 9, 0xFF7D8E61);
    art.oval(135, 118, 17, 10, 0xFF7D8E61);
  }

  void _gate(_Brush art) {
    art.oval(80, 128, 145, 25, 0x3D8B5B43);
    art.box(const Rect.fromLTWH(24, 58, 112, 67), 5, 0xFFC18F6C);
    art.shape(_arch(80, 50, 31, 77), 0xFFF1CA96);
    art.shape(_arch(80, 61, 24, 66), 0xFF825F51);
    art.shape(_arch(80, 69, 18, 56), 0xFF937657);
    for (final x in [16.0, 106.0]) {
      art.box(Rect.fromLTWH(x, 42, 36, 82), 3, 0xFFD5A77A);
      art.box(Rect.fromLTWH(x + 1, 43, 7, 80), 2, 0xFFE8BE8D);
      art.box(Rect.fromLTWH(x - 2, 40, 40, 9), 2, 0xFFE9C28E);
      for (var i = 0; i < 3; i++) {
        art.box(Rect.fromLTWH(x + i * 13, 31, 9, 12), 2, 0xFFDFB98D);
      }
      art.shape(_arch(x + 18, 58, 5, 15), 0xFFA57B61);
      art.line(
        Path()
          ..moveTo(x + 5, 93)
          ..lineTo(x + 25, 93),
        0xFFBB906F,
        2,
      );
      art.line(
        Path()
          ..moveTo(x + 12, 101)
          ..lineTo(x + 33, 101),
        0xFFE3B48B,
        2,
      );
    }
    art.box(const Rect.fromLTWH(45, 121, 70, 8), 2, 0xFFE0B27E);
  }

  void _challenge(_Brush art) {
    art.oval(80, 129, 117, 23, 0x4A8D6346);
    art.oval(80, 123, 99, 17, 0xFFC39162);
    art.box(const Rect.fromLTWH(73, 57, 15, 66), 4, 0xFF926B4A);
    art.box(const Rect.fromLTWH(74, 57, 5, 64), 3, 0xFFC69966);
    art.shape(
      Path()
        ..moveTo(33, 45)
        ..lineTo(109, 45)
        ..lineTo(132, 67)
        ..lineTo(110, 87)
        ..lineTo(33, 87)
        ..quadraticBezierTo(27, 86, 28, 79)
        ..lineTo(28, 51)
        ..quadraticBezierTo(28, 45, 33, 45)
        ..close(),
      0xFF8E6749,
    );
    art.shape(
      Path()
        ..moveTo(33, 48)
        ..lineTo(108, 48)
        ..lineTo(127, 66)
        ..lineTo(109, 82)
        ..lineTo(33, 82)
        ..close(),
      0xFF4D7863,
    );
    for (final (x, y, color) in [
      (45.0, 62.0, 0xFFF4D299),
      (65.0, 56.0, 0xFFFFDC9C),
      (85.0, 61.0, 0xFFC0C086),
    ]) {
      art.box(Rect.fromLTWH(x, y, 15, 13), 3, color);
      art.line(
        Path()
          ..moveTo(x + 4, y + 4)
          ..lineTo(x + 11, y + 4),
        0xFFD3A575,
        1.6,
      );
    }
    art.oval(72, 109, 6, 6, 0xFFF1C18B);
  }

  Path _arch(double x, double y, double halfWidth, double height) => Path()
    ..moveTo(x - halfWidth, y + height)
    ..lineTo(x - halfWidth, y + halfWidth)
    ..quadraticBezierTo(x - halfWidth, y + halfWidth * .32, x, y)
    ..quadraticBezierTo(
      x + halfWidth,
      y + halfWidth * .32,
      x + halfWidth,
      y + halfWidth,
    )
    ..lineTo(x + halfWidth, y + height)
    ..close();

  @override
  bool shouldRepaint(WorshipLandmarkPainter oldDelegate) =>
      landmark != oldDelegate.landmark || accent != oldDelegate.accent;
}

class _Brush {
  _Brush(this.canvas);

  final Canvas canvas;
  final _paint = Paint()
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void shape(Path path, int color) {
    canvas.drawPath(
      path,
      _paint
        ..color = Color(color)
        ..style = PaintingStyle.fill,
    );
  }

  void line(Path path, int color, double width) {
    canvas.drawPath(
      path,
      _paint
        ..color = Color(color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void oval(double x, double y, double width, double height, int color) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: width, height: height),
      _paint
        ..color = Color(color)
        ..style = PaintingStyle.fill,
    );
  }

  void box(Rect rect, double radius, int color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      _paint
        ..color = Color(color)
        ..style = PaintingStyle.fill,
    );
  }
}
