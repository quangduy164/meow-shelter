import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'herd_map.dart';
import 'herd_round.dart';
import 'herd_route_painter.dart';

/// Exclusive art for the herd mode. Geometry comes from HerdMap.
void paintHerdMap(Canvas canvas, Size size, HerdRound r) {
  canvas.save();
  canvas.scale(size.width / 800, size.height / 375);
  switch (r.map.kind) {
    case HerdMapKind.playground:
      _playground(canvas, r);
    case HerdMapKind.nightMarket:
      _market(canvas, r);
    case HerdMapKind.dunes:
      _desert(canvas, r);
    case HerdMapKind.snow:
      _snow(canvas, r);
  }
  canvas.restore();
  paintHerdRoute(canvas, size, r);
}

Rect _rect(Rect r) =>
    Rect.fromLTWH(r.left * 800, r.top * 375, r.width * 800, r.height * 375);
void _fill(Canvas c, Rect r, Color color, [double radius = 0]) => c.drawRRect(
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
void _base(Canvas c, Color top, Color bottom) {
  c.drawRect(
      const Rect.fromLTWH(0, 0, 800, 375),
      Paint()
        ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, bottom])
            .createShader(const Rect.fromLTWH(0, 0, 800, 375)));
}

void _market(Canvas c, HerdRound r) {
  _base(c, const Color(0xFF383C61), const Color(0xFF655374));
  final random = math.Random(9);
  for (var i = 0; i < 45; i++) {
    final p = Offset(random.nextDouble() * 800, random.nextDouble() * 55);
    c.drawCircle(p, 1, Paint()..color = const Color(0xFFDFD8B5));
  }
  for (var row = 0; row < 12; row++) {
    for (var col = 0; col < 28; col++) {
      final x = col * 30.0 + (row.isEven ? 0 : 15);
      _fill(c, Rect.fromLTWH(x, 62 + row * 28.0, 28, 26),
          const Color(0x225E6384), 3);
    }
  }
  for (final patrol in r.patrols) {
    final y = patrol.from.y / r.field.y * 375;
    _fill(c, Rect.fromLTWH(160, y - 18, 460, 36), const Color(0xFF45485C), 8);
    for (var x = 170.0; x < 610; x += 35) {
      _fill(c, Rect.fromLTWH(x, y - 1, 17, 2), const Color(0x887E8395));
    }
    for (var dx = 0; dx < 5; dx++) {
      _fill(c, Rect.fromLTWH(405, y - 17 + dx * 7, 34, 4),
          const Color(0xFFC3BDAA), 1);
    }
  }
  // Hanging lanterns stay above the play area.
  final rope = Path()
    ..moveTo(0, 48)
    ..quadraticBezierTo(400, 84, 800, 48);
  c.drawPath(
      rope,
      Paint()
        ..color = const Color(0xFF25233C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  for (var i = 0; i < 11; i++) {
    final x = 28 + i * 73.0, y = 51 + math.sin(i / 10 * math.pi) * 16;
    c.drawCircle(
        Offset(x, y + 6), 16, Paint()..color = const Color(0x18FFBE6A));
    _fill(c, Rect.fromLTWH(x - 7, y - 2, 14, 17), const Color(0xFFECA25D), 5);
    _line(c, Offset(x - 4, y + 3), Offset(x + 4, y + 3),
        const Color(0xFFF9D18F), 1);
    _line(c, Offset(x, y + 15), Offset(x, y + 21), const Color(0xFFECA25D), 1);
  }
  for (final wall in r.map.walls) {
    _stall(c, _rect(wall));
  }
  final green = r.map.green(r.time);
  _fill(c, const Rect.fromLTWH(447, 68, 6, 28), const Color(0xFF252B3F));
  _fill(c, const Rect.fromLTWH(438, 62, 24, 30), const Color(0xFF202538), 5);
  c.drawCircle(
      const Offset(450, 71),
      5,
      Paint()
        ..color = green ? const Color(0xFF593E48) : const Color(0xFFFF7667));
  c.drawCircle(
      const Offset(450, 83),
      5,
      Paint()
        ..color = green ? const Color(0xFF85E6AC) : const Color(0xFF304D45));
}

void _stall(Canvas c, Rect r) {
  _fill(c, r.shift(const Offset(3, 5)), const Color(0x44201B2E), 5);
  _fill(c, r, const Color(0xFFAA744D), 4);
  _fill(
      c, Rect.fromLTWH(r.left, r.top, r.width, 12), const Color(0xFFE8C281), 3);
  for (var i = 0; i < 6; i++) {
    _fill(
        c,
        Rect.fromLTWH(r.left + i * r.width / 6, r.top - 6, r.width / 6, 17),
        i.isEven ? const Color(0xFFCA6666) : const Color(0xFFFFE4B1),
        2);
  }
  for (var i = 0; i < 5; i++) {
    final p = Offset(r.left + 10 + i * (r.width - 20) / 4, r.top + 24);
    c.drawCircle(
        p,
        4,
        Paint()
          ..color =
              i.isEven ? const Color(0xFFE9B751) : const Color(0xFFA5BB67));
  }
  _line(c, r.bottomLeft + const Offset(4, -4),
      r.bottomRight + const Offset(-4, -4), const Color(0xFF76452F), 3);
}

void _desert(Canvas c, HerdRound r) {
  _base(c, const Color(0xFFF0CA89), const Color(0xFFE6B775));
  c.drawCircle(
      const Offset(115, 60), 28, Paint()..color = const Color(0xFFFFE1A0));
  for (var i = 0; i < 4; i++) {
    final y = 45 + i * 8.0;
    c.drawPath(
        Path()
          ..moveTo(0, y + 22)
          ..quadraticBezierTo(140, y - 15, 300, y + 15)
          ..quadraticBezierTo(530, y - 15, 800, y + 13)
          ..lineTo(800, 0)
          ..lineTo(0, 0)
          ..close(),
        Paint()
          ..color = Color.lerp(
              const Color(0xFFBF8758), const Color(0xFFF0CA89), i / 4)!);
  }
  for (var i = 0; i < 16; i++) {
    final y = 85 + i * 19.0;
    c.drawPath(
        Path()
          ..moveTo(0, y)
          ..cubicTo(230, y - 13, 550, y + 17, 800, y - 4),
        Paint()
          ..color = const Color(0x337D512C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }
  for (final patch in r.map.softSand) {
    final box = _rect(patch);
    _fill(c, box, const Color(0xFFC99A5E), 22);
    final rand = math.Random(4);
    for (var i = 0; i < 50; i++) {
      final p = Offset(box.left + 8 + rand.nextDouble() * (box.width - 16),
          box.top + 8 + rand.nextDouble() * (box.height - 16));
      c.drawCircle(p, 1, Paint()..color = const Color(0x887E5B39));
    }
  }
  for (final patch in r.map.slopes) {
    final box = _rect(patch);
    _fill(c, box, const Color(0xFFF7D89B), 24);
    c.drawArc(
        box,
        -math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFFB77D45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    for (var i = 0; i < 3; i++) {
      final p = Offset(box.left + 30 + i * 35, box.top + 30);
      _line(c, p, p + const Offset(12, 20), const Color(0xFFBB8652), 2);
      _line(c, p + const Offset(12, 20), p + const Offset(4, 17),
          const Color(0xFFBB8652), 2);
      _line(c, p + const Offset(12, 20), p + const Offset(14, 11),
          const Color(0xFFBB8652), 2);
    }
  }
  for (final wall in r.map.walls) {
    _rock(c, _rect(wall), const Color(0xFFB37D54));
  }
  for (final x in [20.0, 760.0]) {
    _line(c, Offset(x, 300), Offset(x, 260), const Color(0xFF648259), 8);
    _line(c, Offset(x, 283), Offset(x - 10, 283), const Color(0xFF648259), 6);
    _line(c, Offset(x - 10, 283), Offset(x - 10, 271), const Color(0xFF648259),
        6);
    _line(c, Offset(x, 274), Offset(x + 12, 274), const Color(0xFF648259), 6);
    _line(c, Offset(x + 12, 274), Offset(x + 12, 263), const Color(0xFF648259),
        6);
  }
}

void _snow(Canvas c, HerdRound r) {
  _base(c, const Color(0xFFBFDCE5), const Color(0xFFF3F6EE));
  c.drawPath(
      Path()
        ..moveTo(0, 64)
        ..lineTo(85, 6)
        ..lineTo(160, 65)
        ..lineTo(245, 13)
        ..lineTo(330, 67)
        ..lineTo(420, 4)
        ..lineTo(520, 68)
        ..lineTo(610, 15)
        ..lineTo(710, 66)
        ..lineTo(800, 20)
        ..lineTo(800, 80)
        ..lineTo(0, 80)
        ..close(),
      Paint()..color = const Color(0xFF8CAFC0));
  for (final x in [85.0, 245.0, 420.0, 610.0]) {
    c.drawPath(
        Path()
          ..moveTo(x - 20, 30)
          ..lineTo(x, 7)
          ..lineTo(x + 25, 36)
          ..lineTo(x + 9, 30)
          ..lineTo(x, 35)
          ..close(),
        Paint()..color = const Color(0xFFE6F2F3));
  }
  for (final patch in r.map.ice) {
    final box = _rect(patch);
    _fill(c, box.inflate(4), const Color(0xFFFDFEFA), 25);
    _fill(c, box, const Color(0xFF99D5E6), 24);
    c.drawRRect(
        RRect.fromRectAndRadius(box.deflate(4), const Radius.circular(20)),
        Paint()
          ..color = const Color(0xFFCDF3F6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var i = 0; i < 4; i++) {
      final x = box.left + 20 + i * box.width / 5;
      _line(c, Offset(x, box.top + 14), Offset(x + 13, box.top + 26),
          const Color(0xFFCEF2F6), 2);
    }
    c.drawPath(
        Path()
          ..moveTo(box.left + 20, box.bottom - 18)
          ..lineTo(box.center.dx, box.center.dy)
          ..lineTo(box.center.dx + 12, box.center.dy + 13)
          ..lineTo(box.right - 18, box.top + 20),
        Paint()
          ..color = const Color(0x8861A5BD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }
  for (final wall in r.map.walls) {
    final box = _rect(wall);
    _rock(c, box, const Color(0xFF8EA3AC));
    _fill(c, Rect.fromLTWH(box.left, box.top - 4, box.width, 13),
        const Color(0xFFF9FCF5), 8);
  }
  for (final x in [20.0, 775.0]) {
    for (var i = 0; i < 3; i++) {
      final y = 120 + i * 90.0;
      _line(c, Offset(x, y), Offset(x, y + 25), const Color(0xFF796659), 5);
      c.drawPath(
          Path()
            ..moveTo(x, y - 25)
            ..lineTo(x - 18, y + 13)
            ..lineTo(x + 18, y + 13)
            ..close(),
          Paint()..color = const Color(0xFF588C87));
      c.drawPath(
          Path()
            ..moveTo(x, y - 25)
            ..lineTo(x - 10, y - 4)
            ..lineTo(x + 10, y - 4)
            ..close(),
          Paint()..color = const Color(0xFFF0F6ED));
    }
  }
  for (var i = 0; i < 25; i++) {
    final x = (i * 71.0 + r.time * 9) % 800,
        y = 65 + (i * 31.0 + r.time * 12) % 300;
    c.drawCircle(Offset(x, y), 1.5, Paint()..color = const Color(0xCCFFFFFF));
  }
}

void _rock(Canvas c, Rect r, Color color) {
  _fill(c, r.shift(const Offset(3, 4)), const Color(0x33402A14), 12);
  c.drawPath(
      Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left + 5, r.top + 10)
        ..lineTo(r.center.dx, r.top)
        ..lineTo(r.right - 5, r.top + 8)
        ..lineTo(r.right, r.bottom)
        ..close(),
      Paint()..color = color);
  _line(c, Offset(r.left + 10, r.top + 13), Offset(r.center.dx, r.top + 5),
      const Color(0x55FFFFFF), 3);
}

void _playground(Canvas c, HerdRound r) {
  _base(c, const Color(0xFF9BD2B4), const Color(0xFFC4DA94));
  // Painted rubber track loops across a sunny play yard.
  for (final patrol in r.patrols) {
    final y = patrol.from.y / r.field.y * 375;
    _fill(c, Rect.fromLTWH(145, y - 20, 490, 40), const Color(0xFFD7B985), 18);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(150, y - 17, 480, 34), const Radius.circular(16)),
        Paint()
          ..color = const Color(0x99F8E7B7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var x = 170.0; x < 620; x += 34) {
      _fill(c, Rect.fromLTWH(x, y - 1, 15, 2), const Color(0xFFFAEDC8));
    }
  }
  // Low bright perimeter fence; the centre stays clear for the whole herd.
  for (var x = 12.0; x < 800; x += 23) {
    _fill(c, Rect.fromLTWH(x, 54, 13, 19), const Color(0xFFFFE8A9), 4);
  }
  _line(c, const Offset(0, 68), const Offset(800, 68), const Color(0xFFBA935D),
      3);
  // Toy blocks and a little slide sit outside the traffic lanes.
  for (var i = 0; i < 3; i++) {
    final x = 25 + i * 24.0;
    _fill(
        c,
        Rect.fromLTWH(x, 92 + (i.isEven ? 0 : 8), 22, 22),
        [
          const Color(0xFFE9A469),
          const Color(0xFF7DA7C0),
          const Color(0xFFD68E9E)
        ][i],
        3);
    _line(c, Offset(x + 5, 98 + (i.isEven ? 0 : 8)),
        Offset(x + 15, 98 + (i.isEven ? 0 : 8)), const Color(0x66FFFFFF), 2);
  }
  _line(c, const Offset(735, 310), const Offset(735, 260),
      const Color(0xFF827596), 4);
  _line(c, const Offset(758, 310), const Offset(758, 260),
      const Color(0xFF827596), 4);
  for (var i = 0; i < 4; i++) {
    _line(c, Offset(735, 270 + i * 10.0), Offset(758, 270 + i * 10.0),
        const Color(0xFFB2A5C2), 3);
  }
  c.drawPath(
      Path()
        ..moveTo(730, 261)
        ..lineTo(716, 261)
        ..quadraticBezierTo(704, 304, 677, 312)
        ..lineTo(677, 321)
        ..quadraticBezierTo(713, 319, 730, 261)
        ..close(),
      Paint()..color = const Color(0xFFEEA262));
  _line(c, const Offset(717, 261), const Offset(700, 301),
      const Color(0xFFFFCF8B), 3);
  for (final p in [const Offset(125, 345), const Offset(670, 90)]) {
    c.drawCircle(p, 10, Paint()..color = const Color(0xFFE6A1B4));
    c.drawArc(
        Rect.fromCircle(center: p, radius: 7),
        0,
        4,
        false,
        Paint()
          ..color = const Color(0xFFAB758D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }
}
