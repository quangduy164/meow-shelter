import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'herd_map.dart';

/// Map-specific shelter art centred on the unchanged arrival point.
void paintHerdHome(Canvas canvas, Offset center, HerdMapKind kind) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.drawOval(const Rect.fromLTWH(-46, 18, 92, 20),
      Paint()..color = const Color(0x33402A14));
  switch (kind) {
    case HerdMapKind.tutorial:
    case HerdMapKind.playground:
      _playhouse(canvas);
    case HerdMapKind.nightMarket:
      _marketHome(canvas);
    case HerdMapKind.dunes:
      _desertHome(canvas);
    case HerdMapKind.snow:
      _snowHome(canvas);
    case HerdMapKind.grandma:
      _basket(canvas);
    case HerdMapKind.station:
      _waitingRoom(canvas);
    case HerdMapKind.farm:
      _barn(canvas);
  }
  // A consistent doorstep and paw badge identify the goal on every map.
  _box(canvas, const Rect.fromLTWH(-20, 21, 40, 6), const Color(0xFFBFA57D), 2);
  const badge = Rect.fromLTWH(-24, 32, 48, 18);
  _box(canvas, badge, const Color(0xFFFFEBC5), 7);
  final paw = Paint()..color = const Color(0xFF8F623C);
  canvas.drawOval(const Rect.fromLTWH(-5, 40, 10, 6), paw);
  for (final p in [
    const Offset(-6, 39),
    const Offset(-2, 36.5),
    const Offset(2, 36.5),
    const Offset(6, 39)
  ]) {
    canvas.drawCircle(p, 2, paw);
  }
  canvas.restore();
}

/// Little red barn with a hay loft and cross-braced doors.
void _barn(Canvas c) {
  _box(c, const Rect.fromLTWH(-36, -20, 72, 44), const Color(0xFFC6463B), 3);
  final roof = Path()
    ..moveTo(-42, -16)
    ..lineTo(-28, -38)
    ..lineTo(28, -38)
    ..lineTo(42, -16)
    ..close();
  c.drawPath(roof, Paint()..color = const Color(0xFF5E3B2A));
  _line(c, const Offset(-42, -16), const Offset(42, -16),
      const Color(0xFFF2EBDD), 3);
  _box(c, const Rect.fromLTWH(-9, -32, 18, 12), const Color(0xFFF2EBDD), 2);
  _box(c, const Rect.fromLTWH(-6, -30, 12, 9), const Color(0xFFE6C05A), 1);
  _box(c, const Rect.fromLTWH(-16, -4, 32, 28), const Color(0xFFF2EBDD), 2);
  _box(c, const Rect.fromLTWH(-13, -1, 26, 25), const Color(0xFFA9362D), 1);
  _line(c, const Offset(-13, -1), const Offset(13, 24), const Color(0xFFF2EBDD),
      2);
  _line(c, const Offset(13, -1), const Offset(-13, 24), const Color(0xFFF2EBDD),
      2);
  for (final x in [-31.0, 21.0]) {
    _box(c, Rect.fromLTWH(x, -12, 10, 10), const Color(0xFFF2EBDD), 1);
  }
}

/// Cosy station waiting room with a cat-shaped sign.
void _waitingRoom(Canvas c) {
  _box(c, const Rect.fromLTWH(-34, -18, 68, 42), const Color(0xFFF1E3C8), 5);
  final roof = Path()
    ..moveTo(-42, -14)
    ..lineTo(0, -40)
    ..lineTo(42, -14)
    ..close();
  c.drawPath(roof, Paint()..color = const Color(0xFF3F6E8C));
  _line(c, const Offset(-42, -14), const Offset(42, -14),
      const Color(0xFF2E5570), 4);
  for (final x in [-27.0, 15.0]) {
    _box(c, Rect.fromLTWH(x, -8, 12, 12), const Color(0xFFFFE9A3), 2);
    _line(c, Offset(x + 6, -8), Offset(x + 6, 4), const Color(0xFFD9B26B), 1);
  }
  _door(c, const Color(0xFFB0794C), const Color(0xFF7A4F2E));
  // Cat-ear sign on the roof.
  final sign = Path()
    ..moveTo(-12, -40)
    ..lineTo(-10, -52)
    ..lineTo(-4, -46)
    ..lineTo(4, -46)
    ..lineTo(10, -52)
    ..lineTo(12, -40)
    ..close();
  c.drawPath(sign, Paint()..color = const Color(0xFFF2C437));
  c.drawCircle(
      const Offset(-4, -43), 1.4, Paint()..color = const Color(0xFF5A3214));
  c.drawCircle(
      const Offset(4, -43), 1.4, Paint()..color = const Color(0xFF5A3214));
}

/// Grandma's big wicker cat basket with a cushion and a knitted blanket.
void _basket(Canvas c) {
  final wicker = Paint()..color = const Color(0xFFC08A4E);
  final weave = Paint()
    ..color = const Color(0xFF9A6A36)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  // Back rim, cushion, then the front of the basket.
  c.drawOval(const Rect.fromLTWH(-42, -22, 84, 34), wicker);
  c.drawOval(const Rect.fromLTWH(-36, -17, 72, 24),
      Paint()..color = const Color(0xFFF2C6C9));
  c.drawOval(const Rect.fromLTWH(-30, -14, 60, 16),
      Paint()..color = const Color(0xFFF8DADB));
  final front = Path()
    ..moveTo(-42, -5)
    ..quadraticBezierTo(-40, 22, 0, 24)
    ..quadraticBezierTo(40, 22, 42, -5)
    ..quadraticBezierTo(0, 8, -42, -5)
    ..close();
  c.drawPath(front, wicker);
  c.save();
  c.clipPath(front);
  for (var x = -42.0; x < 44; x += 7) {
    c.drawLine(Offset(x, -10), Offset(x + 4, 26), weave);
  }
  for (var y = 0.0; y < 26; y += 6) {
    c.drawArc(Rect.fromLTWH(-44, y - 14, 88, 22), .1, 2.9, false, weave);
  }
  c.restore();
  c.drawPath(
      front,
      Paint()
        ..color = const Color(0xFF8A5B2C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  // Knitted blanket over the edge, a ball of yarn and a heart tag.
  final blanket = Path()
    ..moveTo(10, -4)
    ..quadraticBezierTo(24, -8, 36, -2)
    ..lineTo(32, 16)
    ..quadraticBezierTo(22, 12, 14, 14)
    ..close();
  c.drawPath(blanket, Paint()..color = const Color(0xFF8DB4D9));
  for (var i = 0; i < 3; i++) {
    c.drawLine(
        Offset(14 + i * 7.0, -2),
        Offset(15 + i * 6.0, 13),
        Paint()
          ..color = const Color(0xFFBFD7EC)
          ..strokeWidth = 1.5);
  }
  c.drawCircle(
      const Offset(-30, 14), 7, Paint()..color = const Color(0xFFE77FA0));
  c.drawArc(
      const Rect.fromLTWH(-35, 9, 10, 10),
      0,
      3.6,
      false,
      Paint()
        ..color = const Color(0xFFF9B9CC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3);
  final heart = Path()
    ..moveTo(0, -24)
    ..cubicTo(-8, -32, -14, -22, 0, -14)
    ..cubicTo(14, -22, 8, -32, 0, -24)
    ..close();
  c.drawPath(heart, Paint()..color = const Color(0xFFE0614F));
}

void _box(Canvas c, Rect r, Color color, [double radius = 0]) => c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)),
    Paint()..color = color);
void _line(Canvas c, Offset a, Offset b, Color color, double width) =>
    c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);

void _door(Canvas c, Color wood, Color edge) {
  _box(c, const Rect.fromLTWH(-13, -7, 26, 30), edge, 12);
  _box(c, const Rect.fromLTWH(-10, -4, 20, 27), wood, 10);
  for (final x in [-5.0, 0.0, 5.0]) {
    _line(c, Offset(x, 1), Offset(x, 21), edge.withValues(alpha: .45), 1);
  }
  c.drawCircle(
      const Offset(6, 11), 1.6, Paint()..color = const Color(0xFFFFDC7D));
}

void _window(Canvas c, Offset at, Color frame, {bool snow = false}) {
  _box(c, Rect.fromCenter(center: at, width: 17, height: 20), frame, 3);
  _box(c, Rect.fromCenter(center: at, width: 12, height: 15),
      const Color(0xFFFFD98B), 2);
  _line(c, at + const Offset(0, -7), at + const Offset(0, 7), frame, 1.5);
  _line(c, at + const Offset(-6, 0), at + const Offset(6, 0), frame, 1.5);
  _box(c, Rect.fromLTWH(at.dx - 10, at.dy + 10, 20, 3), frame, 1);
  if (snow) {
    _box(c, Rect.fromLTWH(at.dx - 11, at.dy + 8, 22, 4),
        const Color(0xFFF6FCF8), 2);
  }
}

void _marketHome(Canvas c) {
  // Warm pool of lamplight, plaster frontage and a tiled shop-house roof.
  c.drawCircle(
      const Offset(0, 1),
      46,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0, 1), 46,
            const [Color(0x33FFD786), Color(0x00FFD786)]));
  _box(c, const Rect.fromLTWH(-35, -27, 70, 50), const Color(0xFFC5A28C), 3);
  _box(c, const Rect.fromLTWH(-31, -24, 62, 47), const Color(0xFFF1D4AB), 2);
  for (final x in [-32.0, 32.0]) {
    _box(c, Rect.fromLTWH(x - 2, -25, 4, 49), const Color(0xFF7B4C42));
  }
  final roof = Path()
    ..moveTo(-43, -24)
    ..lineTo(-32, -43)
    ..lineTo(31, -43)
    ..lineTo(43, -24)
    ..quadraticBezierTo(0, -17, -43, -24)
    ..close();
  c.drawPath(roof, Paint()..color = const Color(0xFF416775));
  for (var i = 0; i < 9; i++) {
    final x = -32 + i * 8.0;
    _line(
        c, Offset(x, -40), Offset(x * 1.2, -26), const Color(0xFF79939A), 1.5);
  }
  _line(c, const Offset(-40, -24), const Offset(40, -24),
      const Color(0xFF293F55), 3);
  _box(c, const Rect.fromLTWH(-21, -24, 42, 12), const Color(0xFF765042), 3);
  // Small cat silhouette on the sign.
  c.drawPath(
      Path()
        ..moveTo(-6, -15)
        ..lineTo(-6, -23)
        ..lineTo(-2, -20)
        ..lineTo(2, -20)
        ..lineTo(6, -23)
        ..lineTo(6, -15)
        ..close(),
      Paint()..color = const Color(0xFFF9DC98));
  _window(c, const Offset(-23, 5), const Color(0xFF865849));
  _window(c, const Offset(23, 5), const Color(0xFF865849));
  _door(c, const Color(0xFFAB7651), const Color(0xFF6C4737));
  for (final x in [-41.0, 41.0]) {
    _line(c, Offset(x, -16), Offset(x, -9), const Color(0xFF55424B), 2);
    c.drawCircle(Offset(x, 0), 14, Paint()..color = const Color(0x22FFC46E));
    _box(c, Rect.fromLTWH(x - 6, -8, 12, 17), const Color(0xFFDC7955), 5);
    _line(c, Offset(x, -5), Offset(x, 6), const Color(0xFFF5C47A), 2);
    _line(c, Offset(x - 5, -8), Offset(x + 5, -8), const Color(0xFF7A4D3D), 2);
    _line(c, Offset(x, 9), Offset(x, 13), const Color(0xFFDC7955), 1);
  }
}

void _desertHome(Canvas c) {
  // Adobe shelter with a flat parapet, exposed beams and a woven awning.
  _box(c, const Rect.fromLTWH(-38, -35, 76, 59), const Color(0xFFB97F51), 5);
  _box(c, const Rect.fromLTWH(-34, -33, 68, 56), const Color(0xFFE9BB7C), 4);
  _box(c, const Rect.fromLTWH(-40, -38, 80, 9), const Color(0xFFF5D79F), 3);
  _line(c, const Offset(-38, -28), const Offset(38, -28),
      const Color(0xFFC48F58), 2);
  for (final x in [-27.0, -9.0, 9.0, 27.0]) {
    _box(c, Rect.fromLTWH(x - 2, -29, 5, 6), const Color(0xFF87613E), 1);
  }
  for (final p in [
    const Offset(-29, -11),
    const Offset(21, -18),
    const Offset(-25, 17)
  ]) {
    _line(c, p, p + const Offset(7, 0), const Color(0x55AD7B4C), 1.5);
  }
  _window(c, const Offset(-24, 3), const Color(0xFF8E6544));
  _window(c, const Offset(24, 3), const Color(0xFF8E6544));
  _door(c, const Color(0xFF5F9B9A), const Color(0xFF3E7777));
  _line(c, const Offset(-17, -11), const Offset(-19, 22),
      const Color(0xFF86623F), 3);
  _line(c, const Offset(17, -11), const Offset(19, 22), const Color(0xFF86623F),
      3);
  final awning = Path()
    ..moveTo(-15, -17)
    ..lineTo(15, -17)
    ..lineTo(22, -8)
    ..lineTo(-22, -8)
    ..close();
  c.drawPath(awning, Paint()..color = const Color(0xFFBF7254));
  for (final x in [-10.0, 0.0, 10.0]) {
    _line(c, Offset(x, -16), Offset(x * 1.4, -9), const Color(0xFFEAD09A), 3);
  }
  _box(c, const Rect.fromLTWH(-44, 13, 12, 13), const Color(0xFFBD7050), 5);
  _line(c, const Offset(-38, 14), const Offset(-38, 1), const Color(0xFF6C8C5B),
      4);
  _line(c, const Offset(-38, 8), const Offset(-43, 5), const Color(0xFF6C8C5B),
      3);
  // Clay water jar.
  c.drawOval(const Rect.fromLTWH(33, 10, 14, 17),
      Paint()..color = const Color(0xFFB77C54));
  _box(c, const Rect.fromLTWH(37, 8, 6, 5), const Color(0xFF9F6846), 1);
}

void _snowHome(Canvas c) {
  // Log cabin, steep snowy roof, stone chimney and glowing windows.
  _box(c, const Rect.fromLTWH(19, -49, 12, 28), const Color(0xFF7F939B), 2);
  _box(c, const Rect.fromLTWH(17, -51, 16, 5), const Color(0xFFF4FAF4), 3);
  _box(c, const Rect.fromLTWH(-34, -24, 68, 48), const Color(0xFF8A604A), 3);
  for (var y = -20.0; y < 24; y += 7) {
    _line(c, Offset(-34, y), Offset(34, y), const Color(0xFFB58D66), 5);
    for (final x in [-32.0, 32.0]) {
      c.drawCircle(Offset(x, y), 2, Paint()..color = const Color(0xFFDEC09A));
    }
  }
  final roof = Path()
    ..moveTo(-43, -20)
    ..lineTo(0, -49)
    ..lineTo(43, -20)
    ..lineTo(35, -15)
    ..lineTo(0, -38)
    ..lineTo(-35, -15)
    ..close();
  c.drawPath(roof, Paint()..color = const Color(0xFF526B78));
  c.drawPath(
      Path()
        ..moveTo(-43, -24)
        ..lineTo(-3, -52)
        ..quadraticBezierTo(0, -54, 5, -50)
        ..lineTo(43, -24)
        ..quadraticBezierTo(46, -17, 38, -19)
        ..lineTo(0, -43)
        ..lineTo(-36, -19)
        ..quadraticBezierTo(-47, -14, -43, -24)
        ..close(),
      Paint()..color = const Color(0xFFF3FAF5));
  for (final x in [-28.0, 24.0, 31.0]) {
    _line(c, Offset(x, -19), Offset(x, -13), const Color(0xFFCAE7EA), 2);
  }
  _window(c, const Offset(-23, 3), const Color(0xFF5C4840), snow: true);
  _window(c, const Offset(23, 3), const Color(0xFF5C4840), snow: true);
  _door(c, const Color(0xFF995E49), const Color(0xFF60463C));
  _box(c, const Rect.fromLTWH(-42, 22, 25, 7), const Color(0xFFF8FCF6), 4);
  _box(c, const Rect.fromLTWH(17, 22, 27, 7), const Color(0xFFF8FCF6), 4);
}

void _playhouse(Canvas c) {
  _box(c, const Rect.fromLTWH(-34, -23, 68, 47), const Color(0xFFFFE6A6), 4);
  for (var x = -29.0; x < 33; x += 12) {
    _line(c, Offset(x, -18), Offset(x, 22), const Color(0xFFEAC487), 1);
  }
  c.drawPath(
      Path()
        ..moveTo(-43, -21)
        ..lineTo(0, -49)
        ..lineTo(43, -21)
        ..close(),
      Paint()..color = const Color(0xFFD77F79));
  _line(c, const Offset(-42, -21), const Offset(0, -49),
      const Color(0xFFF0ADA0), 4);
  _line(c, const Offset(0, -49), const Offset(42, -21), const Color(0xFFA86062),
      3);
  _window(c, const Offset(-23, 3), const Color(0xFF7B9FA5));
  _window(c, const Offset(23, 3), const Color(0xFF7B9FA5));
  _door(c, const Color(0xFF84B4A0), const Color(0xFF527F70));
  c.drawCircle(
      const Offset(0, -28), 6, Paint()..color = const Color(0xFFFBEAC3));
}
