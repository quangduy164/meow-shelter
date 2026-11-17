import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'herd_map.dart';
import 'herd_text_cache.dart';
import 'herd_round.dart';

/// Uncle Ba's farm. Base and motion use the 800x375 design space; geese are
/// drawn in pixels so they keep their shape.
Rect _r(Rect f) =>
    Rect.fromLTWH(f.left * 800, f.top * 375, f.width * 800, f.height * 375);
Offset _o(Offset f) => Offset(f.dx * 800, f.dy * 375);
Paint _p(Color c) => Paint()..color = c;
void _box(Canvas c, Rect r, Color color, [double radius = 0]) =>
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), _p(color));
void _line(Canvas c, Offset a, Offset b, Color color, double width) =>
    c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);

const _wood = Color(0xFFB07A48), _woodDark = Color(0xFF7E5232);

void paintFarmBase(Canvas c, HerdRound r) {
  // Sky with a barn, windmill and rolling fields on the horizon.
  c.drawRect(
      const Rect.fromLTWH(0, 0, 800, 70),
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFBFE4F2), Color(0xFFEAF6E0)])
            .createShader(const Rect.fromLTWH(0, 0, 800, 70)));
  for (final (x, w, color) in [
    (90.0, 300.0, const Color(0xFFA6CB7A)),
    (380.0, 340.0, const Color(0xFF95BF6E)),
    (690.0, 300.0, const Color(0xFFA6CB7A)),
  ]) {
    c.drawOval(Rect.fromCenter(center: Offset(x, 70), width: w, height: 60),
        _p(color));
  }
  _windmill(c, const Offset(470, 52));
  // Grass with mown stripes.
  _box(c, const Rect.fromLTWH(0, 62, 800, 313), const Color(0xFF9CC46A));
  for (var x = 0.0; x < 800; x += 60) {
    _box(c, Rect.fromLTWH(x, 62, 30, 313), const Color(0x149AC060));
  }
  final random = math.Random(11);
  for (var i = 0; i < 120; i++) {
    final p = Offset(random.nextDouble() * 800, 70 + random.nextDouble() * 300);
    _line(c, p, p + const Offset(-2, -5), const Color(0xFF7FAE52), 1.2);
    _line(c, p, p + const Offset(2, -5), const Color(0xFF7FAE52), 1.2);
  }
  // Dirt paths between the yard, the pens and the barn.
  final path = Paint()
    ..color = const Color(0xFFD8BD8A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 30
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  c.drawPath(
      Path()
        ..moveTo(40, 225)
        ..quadraticBezierTo(48, 180, 48, 157)
        ..moveTo(48, 200)
        ..quadraticBezierTo(140, 200, 208, 196)
        ..quadraticBezierTo(260, 230, 296, 277)
        ..moveTo(300, 222)
        ..quadraticBezierTo(480, 215, 640, 240)
        ..moveTo(520, 210)
        ..quadraticBezierTo(520, 150, 720, 110),
      path);
  // Vegetable rows in the right field, by the geese.
  for (var row = 0; row < 3; row++) {
    final y = 300.0 + row * 18;
    _box(c, Rect.fromLTWH(560, y, 200, 8), const Color(0xFFA7835A), 4);
    for (var x = 568.0; x < 756; x += 18) {
      c.drawCircle(Offset(x, y + 1), 5, _p(const Color(0xFF6FA34E)));
      if (row == 1) {
        c.drawCircle(Offset(x + 2, y + 5), 2.5, _p(const Color(0xFFF08A3C)));
      }
    }
  }
  // Pen floors: straw for the sheep, scratched dirt for the hens.
  final sheep = _r(HerdFarm.sheepPen.area);
  _box(c, sheep, const Color(0xFFE9D49A));
  for (var i = 0; i < 70; i++) {
    final p = Offset(sheep.left + random.nextDouble() * sheep.width,
        sheep.top + random.nextDouble() * sheep.height);
    _line(c, p, p + Offset(6, random.nextDouble() * 4 - 2),
        const Color(0xFFD1B46B), 1.2);
  }
  _box(c, Rect.fromLTWH(sheep.left + 6, sheep.top + 4, 34, 18),
      const Color(0xFFE2B95B), 4);
  _sheep(c, Offset(sheep.right - 30, sheep.top + 22));
  final coop = _r(HerdFarm.coop.area);
  _box(c, coop, const Color(0xFFC9A97B));
  for (var i = 0; i < 30; i++) {
    final p = Offset(coop.left + random.nextDouble() * coop.width,
        coop.top + random.nextDouble() * coop.height);
    c.drawCircle(p, 1.4, _p(const Color(0xFFAE8B5E)));
  }
  _henHouse(c, Rect.fromLTWH(coop.right - 52, coop.bottom - 46, 46, 40));
  for (final p in [Offset(coop.left + 18, coop.bottom - 16)]) {
    _hen(c, p, false);
  }
  for (final wall in HerdFarm.fences) {
    _fence(c, _r(wall));
  }
  _hay(c, _r(HerdFarm.hay));
  _trough(c, _r(HerdFarm.trough));
  _well(c, _r(HerdFarm.well));
  _scarecrow(c, const Offset(770, 300));
  // Plate wires: a dashed rope from each plate to its gate.
  for (final pen in [HerdFarm.sheepPen, HerdFarm.coop]) {
    final a = _o(pen.plate), b = _r(pen.gate).center;
    final d = b - a;
    for (var k = 0.0; k < 1; k += .08) {
      _line(c, a + d * k, a + d * (k + .04), const Color(0x887E5232), 2);
    }
  }
}

void paintFarmMotion(Canvas c, HerdRound r) {
  for (var i = 0; i < r.map.pens.length; i++) {
    final pen = r.map.pens[i];
    final open = i < r.gateOpen.length && r.gateOpen[i];
    final g = _r(pen.gate);
    // Gate leaves swing up out of the gap when open.
    if (open) {
      for (final (x, dir) in [(g.left, 1.0), (g.right, -1.0)]) {
        _line(c, Offset(x, g.center.dy), Offset(x + dir * 8, g.top - 18), _wood,
            5);
        _line(c, Offset(x + dir * 2, g.center.dy - 8),
            Offset(x + dir * 7, g.top - 10), _woodDark, 2);
      }
    } else {
      _box(c, g.inflate(1), _wood, 2);
      for (var x = g.left + 6; x < g.right; x += 10) {
        _line(c, Offset(x, g.top - 4), Offset(x, g.bottom + 2), _woodDark, 2);
      }
      _line(c, g.topLeft, g.bottomRight, _woodDark, 2);
      c.drawCircle(g.center, 3, _p(const Color(0xFFE9C25A)));
    }
    // Plate: stone ring, button down and glowing while pressed.
    final p = _o(pen.plate);
    final pressed = open && r.cats.any((cat) => cat.plate == i) ||
        (open &&
            r.leader.distanceTo(r.platePoint(i)) < HerdPlate.radius &&
            !pen.heavy);
    c.drawOval(
        Rect.fromCenter(center: p + const Offset(0, 3), width: 40, height: 22),
        _p(const Color(0x33402A14)));
    c.drawOval(Rect.fromCenter(center: p, width: 38, height: 20),
        _p(pen.heavy ? const Color(0xFF7D7F86) : const Color(0xFFA19C8E)));
    c.drawOval(
        Rect.fromCenter(
            center: p + Offset(0, pressed ? 2 : -2), width: 28, height: 13),
        _p(pressed
            ? const Color(0xFF8BD06B)
            : (pen.heavy ? const Color(0xFFE0533E) : const Color(0xFFF2C437))));
    if (pen.heavy) {
      // A heavy weight icon so players know only Bé Mập will do.
      final w = p + const Offset(0, -24);
      c.drawPath(
          Path()
            ..moveTo(w.dx - 9, w.dy + 7)
            ..lineTo(w.dx - 6, w.dy - 4)
            ..lineTo(w.dx + 6, w.dy - 4)
            ..lineTo(w.dx + 9, w.dy + 7)
            ..close(),
          _p(const Color(0xFF4F5560)));
      c.drawCircle(
          w + const Offset(0, -6),
          3,
          Paint()
            ..color = const Color(0xFF4F5560)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
      final t = herdLabel('NẶNG', 6, const Color(0xFFFFFFFF));
      t.paint(c, w + Offset(-t.width / 2, -1));
    }
  }
}

/// The goose patrol, in pixels.
void paintFarmGeese(Canvas canvas, HerdRound r) {
  for (final flock in r.map.geese) {
    for (var k = 0; k < HerdGoose.flock; k++) {
      final f = flock.at(r.time, k);
      final p = Offset(f.dx * r.field.x, f.dy * r.field.y);
      _goose(canvas, p, flock.facingLeft(r.time, k), r.time + k);
    }
  }
}

void _goose(Canvas c, Offset p, bool left, double t) {
  c.save();
  c.translate(p.dx, p.dy);
  if (left) c.scale(-1, 1);
  c.drawOval(const Rect.fromLTWH(-14, 9, 28, 7), _p(const Color(0x33402A14)));
  final step = math.sin(t * 10) * 3;
  _line(c, const Offset(-3, 6), Offset(-3 + step, 12), const Color(0xFFF08A3C),
      2);
  _line(
      c, const Offset(3, 6), Offset(3 - step, 12), const Color(0xFFF08A3C), 2);
  c.drawOval(const Rect.fromLTWH(-14, -6, 24, 15), _p(const Color(0xFFFFFFFF)));
  c.drawOval(const Rect.fromLTWH(-12, -3, 14, 8), _p(const Color(0xFFE6E8EA)));
  final neck = Path()
    ..moveTo(4, -2)
    ..quadraticBezierTo(12, -6, 9, -18)
    ..lineTo(14, -18)
    ..quadraticBezierTo(17, -6, 9, 2)
    ..close();
  c.drawPath(neck, _p(const Color(0xFFFFFFFF)));
  c.drawCircle(const Offset(12, -19), 4.5, _p(const Color(0xFFFFFFFF)));
  c.drawPath(
      Path()
        ..moveTo(15, -21)
        ..lineTo(23, -18 + math.sin(t * 14).abs() * 2)
        ..lineTo(15, -16)
        ..close(),
      _p(const Color(0xFFF08A3C)));
  c.drawCircle(const Offset(13, -20), 1.1, _p(const Color(0xFF222222)));
  // Angry brow.
  _line(c, const Offset(10, -23), const Offset(15, -21),
      const Color(0xFF222222), 1.2);
  c.restore();
}

void _fence(Canvas c, Rect w) {
  final vertical = w.height > w.width;
  _box(c, w.shift(const Offset(2, 4)), const Color(0x33402A14), 2);
  if (vertical) {
    for (final x in [w.left + 2, w.right - 2]) {
      _line(c, Offset(x, w.top), Offset(x, w.bottom), _wood, 3);
    }
    for (var y = w.top + 4; y < w.bottom; y += 22) {
      _box(c, Rect.fromLTWH(w.left - 2, y, w.width + 4, 6), _woodDark, 2);
    }
  } else {
    for (final y in [w.top + 3, w.bottom - 2]) {
      _line(c, Offset(w.left, y), Offset(w.right, y), _wood, 3.5);
    }
    for (var x = w.left + 3; x < w.right; x += 18) {
      _box(c, Rect.fromLTWH(x, w.top - 6, 6, w.height + 8), _woodDark, 2);
      c.drawCircle(Offset(x + 3, w.top - 6), 3, _p(_woodDark));
    }
  }
}

void _hay(Canvas c, Rect h) {
  _box(c, h.shift(const Offset(3, 4)), const Color(0x33402A14), 5);
  _box(c, h, const Color(0xFFE6C05A), 5);
  for (var y = h.top + 5; y < h.bottom; y += 5) {
    _line(c, Offset(h.left + 3, y), Offset(h.right - 3, y + 1),
        const Color(0xFFCFA43F), 1);
  }
  for (final x in [h.left + h.width * .3, h.left + h.width * .7]) {
    _line(c, Offset(x, h.top), Offset(x, h.bottom), const Color(0xFFA9532F), 2);
  }
}

void _trough(Canvas c, Rect t) {
  _box(c, t.shift(const Offset(2, 3)), const Color(0x33402A14), 4);
  _box(c, t, _woodDark, 4);
  _box(c, t.deflate(3), const Color(0xFF7FB8D6), 3);
}

void _well(Canvas c, Rect w) {
  _box(c, w.shift(const Offset(2, 3)), const Color(0x33402A14), 6);
  _box(c, w, const Color(0xFF9EA3A8), 6);
  c.drawOval(w.deflate(5), _p(const Color(0xFF3C4E5E)));
  _line(c, Offset(w.left + 2, w.top), Offset(w.left + 2, w.top - 16), _woodDark,
      3);
  _line(c, Offset(w.right - 2, w.top), Offset(w.right - 2, w.top - 16),
      _woodDark, 3);
  _line(c, Offset(w.left - 2, w.top - 16), Offset(w.right + 2, w.top - 16),
      const Color(0xFFB9574A), 5);
}

void _scarecrow(Canvas c, Offset p) {
  _line(c, p, p + const Offset(0, -40), _woodDark, 3);
  _line(c, p + const Offset(-16, -28), p + const Offset(16, -28), _woodDark, 3);
  _box(
      c,
      Rect.fromCenter(center: p + const Offset(0, -24), width: 16, height: 16),
      const Color(0xFF6E9EC8),
      3);
  c.drawCircle(p + const Offset(0, -40), 7, _p(const Color(0xFFF1DDB0)));
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(0, -46), width: 24, height: 6),
      _p(const Color(0xFFD9A84E)));
}

void _windmill(Canvas c, Offset p) {
  c.drawPath(
      Path()
        ..moveTo(p.dx - 7, p.dy + 18)
        ..lineTo(p.dx - 3, p.dy - 10)
        ..lineTo(p.dx + 3, p.dy - 10)
        ..lineTo(p.dx + 7, p.dy + 18)
        ..close(),
      _p(const Color(0xFFF2EBDD)));
  for (var i = 0; i < 4; i++) {
    final a = i * math.pi / 2 + .4;
    _line(
        c,
        p + const Offset(0, -10),
        p + const Offset(0, -10) + Offset(math.cos(a), math.sin(a)) * 16,
        const Color(0xFFB9574A),
        3);
  }
}

void _sheep(Canvas c, Offset p) {
  for (var i = 0; i < 5; i++) {
    c.drawCircle(p + Offset(-8 + i * 4.0, (i % 2) * 3.0), 7,
        _p(const Color(0xFFFDFBF4)));
  }
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(12, 2), width: 9, height: 11),
      _p(const Color(0xFF4A4146)));
  for (final x in [-6.0, 6.0]) {
    _line(c, p + Offset(x, 6), p + Offset(x, 13), const Color(0xFF4A4146), 2.5);
  }
}

void _hen(Canvas c, Offset p, bool left) {
  c.drawOval(Rect.fromCenter(center: p, width: 18, height: 13),
      _p(const Color(0xFFFFFFFF)));
  c.drawCircle(p + const Offset(7, -6), 5, _p(const Color(0xFFFFFFFF)));
  c.drawCircle(p + const Offset(7, -11), 2.5, _p(const Color(0xFFE0533E)));
  c.drawPath(
      Path()
        ..moveTo(p.dx + 11, p.dy - 7)
        ..lineTo(p.dx + 15, p.dy - 5)
        ..lineTo(p.dx + 11, p.dy - 4)
        ..close(),
      _p(const Color(0xFFF2B33D)));
}

void _henHouse(Canvas c, Rect h) {
  _box(c, h.shift(const Offset(3, 4)), const Color(0x33402A14), 4);
  _box(c, Rect.fromLTWH(h.left, h.top + 10, h.width, h.height - 10),
      const Color(0xFFD9675A), 3);
  c.drawPath(
      Path()
        ..moveTo(h.left - 4, h.top + 12)
        ..lineTo(h.center.dx, h.top - 4)
        ..lineTo(h.right + 4, h.top + 12)
        ..close(),
      _p(const Color(0xFF7E5232)));
  c.drawOval(
      Rect.fromCenter(
          center: Offset(h.center.dx, h.bottom - 10), width: 16, height: 18),
      _p(const Color(0xFF4A2E22)));
  _line(c, Offset(h.center.dx - 10, h.bottom),
      Offset(h.center.dx + 2, h.bottom + 10), _wood, 3);
}
