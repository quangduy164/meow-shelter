import 'dart:math' as math;
import 'package:flutter/rendering.dart';

import 'shelter_map.dart';

/// Chapter 6 rescue station on a rainy night, in the 1000x500 design space.
/// Sandbag walls are the [ShelterMap.storm] obstacles. Water, rain and the
/// truck are drawn live by StormSystem.
class StormStationPainter extends CustomPainter {
  const StormStationPainter();

  static Paint _p(Color c) => Paint()..color = c;
  static void _box(Canvas c, Rect r, Color color, [double radius = 0]) =>
      c.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(radius)), _p(color));
  static Rect _px(Rect r) =>
      Rect.fromLTWH(r.left * 1000, r.top * 500, r.width * 1000, r.height * 500);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 500);
    _sky(canvas);
    _ground(canvas);
    for (final bags in ShelterMap.storm.obstacles.map(_px)) {
      _sandbags(canvas, bags);
    }
    _tent(canvas);
    for (final x in [120.0, 880.0]) {
      _lamp(canvas, Offset(x, 230));
    }
    canvas.restore();
  }

  void _sky(Canvas c) {
    c.drawRect(
        const Rect.fromLTWH(0, 0, 1000, 130),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E2840), Color(0xFF3A4A66)])
              .createShader(const Rect.fromLTWH(0, 0, 1000, 130)));
    // Heavy clouds.
    for (final (x, y, w) in [
      (120.0, 30.0, 260.0),
      (460.0, 18.0, 320.0),
      (840.0, 34.0, 280.0)
    ]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: w, height: 70),
          _p(const Color(0xFF4A566E)));
      c.drawOval(
          Rect.fromCenter(
              center: Offset(x + 30, y + 14), width: w * .7, height: 50),
          _p(const Color(0xFF56627A)));
    }
    // Station building with lit windows and a red-cross sign.
    _box(c, const Rect.fromLTWH(640, 54, 300, 76), const Color(0xFF5E6A80), 4);
    c.drawPath(
        Path()
          ..moveTo(630, 58)
          ..lineTo(790, 22)
          ..lineTo(950, 58)
          ..close(),
        _p(const Color(0xFF7A3A3A)));
    for (var i = 0; i < 5; i++) {
      _box(c, Rect.fromLTWH(660 + i * 56.0, 72, 32, 24),
          i == 2 ? const Color(0xFF3A4A66) : const Color(0xFFFFD98A), 3);
    }
    _box(c, const Rect.fromLTWH(774, 30, 32, 22), const Color(0xFFF7F3EA), 4);
    c.drawRect(
        const Rect.fromLTWH(786, 33, 8, 16), _p(const Color(0xFFE0533E)));
    c.drawRect(
        const Rect.fromLTWH(782, 37, 16, 8), _p(const Color(0xFFE0533E)));
    // Road along the top where the truck parks.
    _box(c, const Rect.fromLTWH(0, 118, 1000, 56), const Color(0xFF3F4552));
    for (var x = 20.0; x < 1000; x += 70) {
      _box(c, Rect.fromLTWH(x, 144, 36, 4), const Color(0xCCF2C437), 2);
    }
    c.drawRect(
        const Rect.fromLTWH(0, 170, 1000, 6), _p(const Color(0xFF8A8F99)));
  }

  void _ground(Canvas c) {
    // Wet paving with puddles reflecting the lamps.
    _box(c, const Rect.fromLTWH(0, 176, 1000, 324), const Color(0xFF5C6676));
    final seam = Paint()
      ..color = const Color(0x553A4250)
      ..strokeWidth = 1.2;
    for (var y = 176.0, row = 0; y < 500; y += 30, row++) {
      c.drawLine(Offset(0, y), Offset(1000, y), seam);
      for (var x = row.isEven ? 0.0 : 45.0; x < 1000; x += 90) {
        c.drawLine(Offset(x, y), Offset(x, y + 30), seam);
      }
    }
    final random = math.Random(8);
    for (var i = 0; i < 9; i++) {
      final p = Offset(
          80 + random.nextDouble() * 840, 200 + random.nextDouble() * 120);
      final w = 40 + random.nextDouble() * 60;
      c.drawOval(Rect.fromCenter(center: p, width: w, height: w * .35),
          _p(const Color(0x664A6E90)));
      c.drawOval(
          Rect.fromCenter(
              center: p + const Offset(-6, -2), width: w * .4, height: 3),
          _p(const Color(0x55FFE9B8)));
    }
    // Water-level marks on a post: shows how high the flood may come.
    _box(c, const Rect.fromLTWH(960, 300, 10, 190), const Color(0xFFF2EBDD), 2);
    for (var y = 310.0; y < 490; y += 30) {
      c.drawLine(
          Offset(960, y),
          Offset(976, y),
          Paint()
            ..color = const Color(0xFFE0533E)
            ..strokeWidth = 2);
    }
  }

  void _sandbags(Canvas c, Rect r) {
    c.drawOval(Rect.fromLTWH(r.left - 4, r.bottom - 6, r.width + 8, 14),
        _p(const Color(0x55101828)));
    const rows = 2;
    for (var row = 0; row < rows; row++) {
      final y = r.top + row * r.height / rows;
      final count = row.isEven ? 4 : 3;
      final w = r.width / 4;
      for (var i = 0; i < count; i++) {
        final x = r.left + i * w + (row.isEven ? 0 : w / 2);
        final bag = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w - 2, r.height / rows + 2),
            const Radius.circular(8));
        c.drawRRect(bag, _p(const Color(0xFFC4AE7E)));
        c.drawRRect(
            bag,
            Paint()
              ..color = const Color(0xFF8E7A52)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
    }
  }

  void _tent(Canvas c) {
    // First-aid tent beside the road.
    c.drawPath(
        Path()
          ..moveTo(40, 176)
          ..lineTo(110, 130)
          ..lineTo(180, 176)
          ..close(),
        _p(const Color(0xFFF2EBDD)));
    c.drawRect(
        const Rect.fromLTWH(104, 148, 12, 4), _p(const Color(0xFFE0533E)));
    c.drawRect(
        const Rect.fromLTWH(108, 144, 4, 12), _p(const Color(0xFFE0533E)));
  }

  void _lamp(Canvas c, Offset base) {
    c.drawCircle(base + const Offset(0, -86), 50, _p(const Color(0x22FFE9B8)));
    c.drawLine(
        base,
        base + const Offset(0, -80),
        Paint()
          ..color = const Color(0xFF2E333B)
          ..strokeWidth = 4);
    c.drawCircle(base + const Offset(0, -84), 7, _p(const Color(0xFFFFE9B8)));
    c.drawOval(
        Rect.fromCenter(
            center: base + const Offset(0, 6), width: 70, height: 18),
        _p(const Color(0x33FFE9B8)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
