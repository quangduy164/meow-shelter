import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'herd_map.dart';
import 'herd_round.dart';

/// Grandma's house art. Base and motion use the 800x375 design space; the
/// robot is drawn in pixels so it stays round on every screen.
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
void _stroke(Canvas c, RRect r, Color color, double width) => c.drawRRect(
    r,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width);

const _wallTop = 64.0;
const _ink = Color(0xFF6E4A33);

void paintGrandmaBase(Canvas c, HerdRound r) {
  _wallpaper(c);
  _floors(c);
  _decor(c);
  for (final wall in HerdHouse.walls) {
    _wall(c, _r(wall));
  }
  _doors(c);
  for (final flap in HerdHouse.flaps) {
    _flap(c, _r(flap));
  }
  _sofa(c, _r(HerdHouse.sofa));
  _clockCase(c, _r(HerdHouse.clock));
  _coffeeTable(c, _r(HerdHouse.coffeeTable));
  _wardrobe(c, _r(HerdHouse.wardrobe));
  _bed(c, _r(HerdHouse.bed));
  _kitchenTable(c, _r(HerdHouse.kitchenTable));
  _fridge(c, _r(HerdHouse.fridge));
  _yarn(c, _o(HerdHouse.yarn));
  _fishDish(c, _o(HerdHouse.fishDish));
}

void paintGrandmaMotion(Canvas c, HerdRound r) {
  final t = r.time;
  final clock = _r(HerdHouse.clock);
  // Pendulum behind the little glass window.
  final pivot = Offset(clock.center.dx, clock.top + 30);
  final swing = math.sin(t * 3.2) * .35;
  final bob = pivot + Offset(math.sin(swing) * 11, math.cos(swing) * 11);
  c.save();
  c.clipRect(Rect.fromLTWH(
      clock.left + 6, clock.top + 26, clock.width - 12, clock.height - 30));
  _line(c, pivot, bob, const Color(0xFFC59B3C), 1.6);
  c.drawCircle(bob, 3.6, _p(const Color(0xFFE9C25A)));
  c.restore();
  // Cuckoo pops out of the roof door and sound rings spread over the room.
  if (HerdCuckoo.ringing(t)) {
    final k =
        ((t + HerdCuckoo.offset) % HerdCuckoo.period) / HerdCuckoo.ringSeconds;
    final out = math.sin(math.min(1, k * 4) * math.pi / 2) * 14;
    final head = Offset(clock.center.dx, clock.top + 2 - out);
    _line(c, Offset(clock.center.dx, clock.top + 8), head,
        const Color(0xFF8B6440), 2);
    c.drawOval(Rect.fromCenter(center: head, width: 14, height: 10),
        _p(const Color(0xFF5E86C2)));
    c.drawCircle(head + const Offset(4, -2), 1.3, _p(const Color(0xFF1F2430)));
    c.drawPath(
        Path()
          ..moveTo(head.dx + 6, head.dy - 1)
          ..lineTo(head.dx + 12 + math.sin(t * 20) * 2, head.dy + 1)
          ..lineTo(head.dx + 6, head.dy + 2)
          ..close(),
        _p(const Color(0xFFF2A93B)));
    final text = TextPainter(
        text: const TextSpan(
            text: 'Cúc cu!',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w900, color: _ink)),
        textDirection: TextDirection.ltr)
      ..layout();
    final at = head + const Offset(14, -22);
    _box(c, (at & text.size).inflate(4), const Color(0xF2FFF6E3), 8);
    text.paint(c, at);
    final room = _r(HerdHouse.livingRoom);
    c.save();
    c.clipRect(room);
    for (var i = 0; i < 3; i++) {
      final grow = ((k + i / 3) % 1) * 260;
      c.drawCircle(
          clock.center,
          grow,
          Paint()
            ..color = Color.fromRGBO(245, 196, 92, .45 * (1 - grow / 260))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    c.restore();
  }
  // Fireplace flames.
  for (var i = 0; i < 3; i++) {
    final x = 690.0 + i * 12;
    final h = 12 + math.sin(t * 9 + i * 2) * 3;
    c.drawPath(
        Path()
          ..moveTo(x - 6, 56)
          ..quadraticBezierTo(x - 5, 56 - h * .6, x, 56 - h)
          ..quadraticBezierTo(x + 5, 56 - h * .6, x + 6, 56)
          ..close(),
        _p(i == 1 ? const Color(0xFFFFC94D) : const Color(0xFFF07A3E)));
  }
}

/// Robot vacuums, in pixel space.
void paintGrandmaRobots(Canvas canvas, HerdRound r) {
  for (var i = 0; i < r.map.robots.length; i++) {
    final loop = r.map.pixels(r.map.robots[i], r.field);
    final p = HerdRobot.at(loop, r.time);
    final dir = HerdRobot.heading(loop, r.time);
    // A cleaner stripe behind the robot.
    for (var k = 1; k <= 6; k++) {
      final q = HerdRobot.at(loop, r.time - k * .09);
      canvas.drawCircle(
          q, 12 - k * 1.2, _p(Color.fromRGBO(255, 255, 255, .22 - k * .03)));
    }
    canvas.drawOval(
        Rect.fromCenter(center: p + const Offset(0, 6), width: 38, height: 14),
        _p(const Color(0x33402A14)));
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.drawCircle(Offset.zero, 17, _p(const Color(0xFF3E4652)));
    canvas.drawCircle(Offset.zero, 14, _p(const Color(0xFF6B7684)));
    canvas.drawCircle(const Offset(-3, -4), 6, _p(const Color(0xFF8C97A6)));
    // Bumper on the leading side.
    final angle = math.atan2(dir.dy, dir.dx);
    canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 16.5),
        angle - .9,
        1.8,
        false,
        Paint()
          ..color = const Color(0xFFE0A23B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final blink = (r.time * 2).floor().isEven;
    canvas.drawCircle(dir * 9, 2.2,
        _p(blink ? const Color(0xFF7CE38B) : const Color(0xFF3B8C4A)));
    // Spinning side brush.
    final brush = dir * 12 + Offset(-dir.dy, dir.dx) * 10;
    for (var k = 0; k < 3; k++) {
      final a = r.time * 14 + k * 2.09;
      _line(canvas, brush, brush + Offset(math.cos(a), math.sin(a)) * 6,
          const Color(0xFF2C323B), 1.2);
    }
    canvas.restore();
  }
}

void _wallpaper(Canvas c) {
  _box(c, const Rect.fromLTWH(0, 0, 800, _wallTop), const Color(0xFFF3D9C8));
  for (var x = 6.0; x < 800; x += 22) {
    _line(c, Offset(x, 0), Offset(x, _wallTop), const Color(0xFFEBC8B5), 5);
  }
  for (var x = 17.0; x < 800; x += 44) {
    for (var y = 12.0; y < 56; y += 20) {
      c.drawCircle(Offset(x, y), 2, _p(const Color(0xFFE2A99A)));
    }
  }
  // Windows, picture frames and the fireplace mantel.
  for (final x in [96.0, 470.0]) {
    _box(c, Rect.fromLTWH(x, 8, 64, 46), const Color(0xFFFFF7EA), 3);
    _box(c, Rect.fromLTWH(x + 4, 12, 56, 38), const Color(0xFFAED9E8), 2);
    _line(
        c, Offset(x + 32, 12), Offset(x + 32, 50), const Color(0xFFFFF7EA), 3);
    _line(c, Offset(x + 4, 31), Offset(x + 60, 31), const Color(0xFFFFF7EA), 3);
    c.drawCircle(Offset(x + 18, 24), 7, _p(const Color(0xFFFFF3B8)));
    _box(c, Rect.fromLTWH(x - 6, 50, 76, 6), const Color(0xFFD4A06E), 2);
    for (final dx in [-4.0, 64.0]) {
      _box(c, Rect.fromLTWH(x + dx, 6, 8, 48), const Color(0xFFE48A87), 3);
    }
  }
  for (final (x, color) in [
    (30.0, const Color(0xFFF2B3A0)),
    (196.0, const Color(0xFFB7D1A6)),
    (400.0, const Color(0xFFC6B3E0)),
    (575.0, const Color(0xFFF2D18A)),
  ]) {
    _box(c, Rect.fromLTWH(x, 14, 30, 24), const Color(0xFFB27C4E), 2);
    _box(c, Rect.fromLTWH(x + 4, 18, 22, 16), color, 1);
    c.drawCircle(Offset(x + 15, 26), 4, _p(const Color(0xFFFFF4E0)));
  }
  _box(c, const Rect.fromLTWH(668, 20, 96, 44), const Color(0xFFB9674A), 3);
  for (var y = 24.0; y < 64; y += 9) {
    _line(c, Offset(670, y), Offset(762, y), const Color(0xFF9E5540), 1);
  }
  _box(c, const Rect.fromLTWH(682, 34, 60, 30), const Color(0xFF3A2620), 14);
  _box(c, const Rect.fromLTWH(660, 14, 112, 8), const Color(0xFFE8D2B4), 2);
  c.drawCircle(const Offset(675, 9), 5, _p(const Color(0xFF8CB98A)));
  _box(c, const Rect.fromLTWH(740, 4, 16, 10), const Color(0xFFD9A15A), 2);
  // Kitchen shelf with jars on the right wall.
  _box(c, const Rect.fromLTWH(782, 0, 18, _wallTop), const Color(0xFFF3D9C8));
  _line(c, const Offset(0, _wallTop), const Offset(800, _wallTop),
      const Color(0xFFB98A64), 5);
}

void _floors(Canvas c) {
  void planks(Rect room, Color base, Color seam) {
    _box(c, room, base);
    var row = 0;
    for (var y = room.top + 12; y < room.bottom; y += 12, row++) {
      _line(c, Offset(room.left, y), Offset(room.right, y), seam, 1);
      for (var x = room.left + (row.isEven ? 30 : 70);
          x < room.right;
          x += 90) {
        _line(c, Offset(x, y - 12), Offset(x, y), seam, 1);
      }
    }
  }

  planks(_r(HerdHouse.livingRoom), const Color(0xFFE2B587),
      const Color(0xFFCC9A6A));
  // Big oval rug in the living room.
  final rug =
      Rect.fromCenter(center: const Offset(140, 220), width: 200, height: 120);
  c.drawOval(rug.inflate(6), _p(const Color(0xFFB4594F)));
  c.drawOval(rug, _p(const Color(0xFFD9786A)));
  c.drawOval(
      rug.deflate(16),
      Paint()
        ..color = const Color(0xFFF4D7A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  for (var i = 0; i < 10; i++) {
    final a = i * math.pi / 5;
    c.drawCircle(rug.center + Offset(math.cos(a) * 72, math.sin(a) * 40), 3,
        _p(const Color(0xFFF4D7A8)));
  }
  // Bedroom carpet.
  final bedroom = _r(HerdHouse.bedroom);
  _box(c, bedroom, const Color(0xFFB9D1E2));
  var row = 0;
  for (var y = bedroom.top + 9; y < bedroom.bottom; y += 16, row++) {
    for (var x = bedroom.left + 8 + (row.isEven ? 0 : 8);
        x < bedroom.right;
        x += 16) {
      c.drawCircle(Offset(x, y), 1.2, _p(const Color(0xFF9EBDD3)));
    }
  }
  planks(
      _r(HerdHouse.fireRoom), const Color(0xFFD0A06E), const Color(0xFFB98756));
  c.drawOval(
      Rect.fromCenter(center: const Offset(704, 136), width: 150, height: 56),
      _p(const Color(0xFF8FA968)));
  c.drawOval(
      Rect.fromCenter(center: const Offset(704, 136), width: 130, height: 44),
      _p(const Color(0xFFA8C07E)));
  // Kitchen checker tiles.
  final kitchen = _r(HerdHouse.kitchen);
  _box(c, kitchen, const Color(0xFFF6EBD6));
  c.save();
  c.clipRect(kitchen);
  for (var y = kitchen.top; y < kitchen.bottom; y += 20) {
    for (var x = kitchen.left; x < kitchen.right; x += 20) {
      if (((x - kitchen.left) ~/ 20 + (y - kitchen.top) ~/ 20).isEven) {
        _box(c, Rect.fromLTWH(x, y, 20, 20), const Color(0xFFE7B49A));
      }
    }
  }
  c.restore();
}

void _decor(Canvas c) {
  // Potted plants and slippers: floor decoration only.
  for (final p in [
    const Offset(26, 350),
    const Offset(318, 76),
    const Offset(770, 200)
  ]) {
    _box(
        c,
        Rect.fromCenter(center: p + const Offset(0, 6), width: 18, height: 14),
        const Color(0xFFC0714F),
        3);
    for (var i = -1; i <= 1; i++) {
      c.drawOval(
          Rect.fromCenter(
              center: p + Offset(i * 6.0, -6 - (i == 0 ? 4 : 0)),
              width: 9,
              height: 16),
          _p(const Color(0xFF6E9E5E)));
    }
  }
  for (final dx in [0.0, 13.0]) {
    _box(c, Rect.fromLTWH(56 + dx, 300, 10, 18), const Color(0xFFF2A3B3), 5);
    c.drawCircle(Offset(61 + dx, 302), 3, _p(const Color(0xFFFFFFFF)));
  }
  // Knitting basket beside the sofa.
  c.drawOval(const Rect.fromLTWH(196, 88, 26, 16), _p(const Color(0xFFB98B55)));
  c.drawCircle(const Offset(203, 89), 5, _p(const Color(0xFF8DB4D9)));
  c.drawCircle(const Offset(214, 90), 5, _p(const Color(0xFFF0C25B)));
}

void _wall(Canvas c, Rect w) {
  _box(c, w.shift(const Offset(3, 4)), const Color(0x334D3020), 3);
  _box(c, w, const Color(0xFFEEDCC0), 3);
  final cap = w.height > w.width
      ? Rect.fromLTWH(w.left, w.top, w.width, 6)
      : Rect.fromLTWH(w.left, w.top, w.width, w.height * .45);
  _box(c, cap, const Color(0xFFFFF6E6), 3);
  _stroke(c, RRect.fromRectAndRadius(w, const Radius.circular(3)),
      const Color(0xFFA9845F), 1.5);
  // Baseboard along the long side.
  if (w.height > w.width) {
    _line(c, Offset(w.left + 2, w.bottom - 4),
        Offset(w.right - 2, w.bottom - 4), const Color(0xFFC49A6C), 2);
  }
}

const _living = (Color(0xFFE2B587), Color(0xFFCC9A6A));
const _bedroom = (Color(0xFFB9D1E2), Color(0xFF9EBDD3));
const _fire = (Color(0xFFD0A06E), Color(0xFFB98756));
const _kitchen = (Color(0xFFF6EBD6), Color(0xFFE7B49A));

/// Floor continues through every opening, half in each room's colour, so
/// exits read as walkable floor; a thin brass threshold marks the middle.
void _gapFloor(Canvas c, Rect g, (Color, Color) a, (Color, Color) b,
    {required bool vertical}) {
  final first = vertical
      ? Rect.fromLTRB(g.left, g.top, g.center.dx, g.bottom)
      : Rect.fromLTRB(g.left, g.top, g.right, g.center.dy);
  final second = vertical
      ? Rect.fromLTRB(g.center.dx, g.top, g.right, g.bottom)
      : Rect.fromLTRB(g.left, g.center.dy, g.right, g.bottom);
  for (final (half, floor) in [(first, a), (second, b)]) {
    _box(c, half.inflate(.5), floor.$1);
    // A couple of seams so the strip looks like the room's floor.
    if (vertical) {
      for (var y = half.top + 12; y < half.bottom; y += 12) {
        _line(c, Offset(half.left, y), Offset(half.right, y), floor.$2, 1);
      }
    } else {
      for (var x = half.left + 20; x < half.right; x += 20) {
        _line(c, Offset(x, half.top), Offset(x, half.bottom), floor.$2, 1);
      }
    }
  }
  if (vertical) {
    _line(c, Offset(g.center.dx, g.top + 2), Offset(g.center.dx, g.bottom - 2),
        const Color(0xFFD9B26B), 2);
  } else {
    _line(c, Offset(g.left + 2, g.center.dy), Offset(g.right - 2, g.center.dy),
        const Color(0xFFD9B26B), 2);
  }
}

void _doors(Canvas c) {
  // Big doors: floor through the gap, wooden jambs, leaf open against wall.
  for (final (gap, vertical, a, b) in [
    (const Rect.fromLTWH(.36, .62, .025, .16), true, _living, _bedroom),
    (const Rect.fromLTWH(.66, .26, .025, .16), true, _bedroom, _fire),
    (const Rect.fromLTWH(.78, .555, .12, .03), false, _fire, _kitchen),
  ]) {
    final g = _r(gap);
    _gapFloor(c, g, a, b, vertical: vertical);
    if (vertical) {
      for (final y in [g.top - 1, g.bottom - 4]) {
        _box(c, Rect.fromLTWH(g.left - 2, y, g.width + 4, 5),
            const Color(0xFF8C6544), 1);
      }
      _line(c, Offset(g.right + 1, g.top + 2), Offset(g.right + 18, g.top - 10),
          const Color(0xFFA5734A), 5);
    } else {
      for (final x in [g.left - 1, g.right - 4]) {
        _box(c, Rect.fromLTWH(x, g.top - 2, 5, g.height + 4),
            const Color(0xFF8C6544), 1);
      }
      _line(c, Offset(g.right - 2, g.bottom),
          Offset(g.right + 14, g.bottom + 18), const Color(0xFFA5734A), 5);
    }
  }
  // Cat flap openings get the same floor before their frames are drawn.
  for (final (gap, a, b) in [
    (const Rect.fromLTWH(.36, .30, .025, .13), _living, _bedroom),
    (const Rect.fromLTWH(.66, .70, .025, .13), _bedroom, _kitchen),
  ]) {
    _gapFloor(c, _r(gap), a, b, vertical: true);
  }
}

/// Narrow flap door with a "no chubby cats" badge on the wall above.
void _flap(Canvas c, Rect f) {
  final frame = Rect.fromLTWH(f.left + 2, f.top, f.width - 4, f.height);
  for (final y in [frame.top, frame.bottom - 5]) {
    _box(c, Rect.fromLTWH(frame.left - 2, y, frame.width + 4, 5),
        const Color(0xFFE08E3C), 2);
  }
  // A clear flap hanging in the opening: floor shows through it.
  _box(c, Rect.fromLTWH(frame.left + 1, frame.top + 5, 3, frame.height - 10),
      const Color(0x88E08E3C), 1.5);
  // Paw print on the floor.
  final paw = _p(const Color(0x668F623C));
  final pc = frame.center;
  c.drawOval(
      Rect.fromCenter(center: pc + const Offset(0, 3), width: 8, height: 6),
      paw);
  for (final d in [
    const Offset(-4, -2),
    const Offset(0, -5),
    const Offset(4, -2)
  ]) {
    c.drawCircle(pc + d, 1.6, paw);
  }
  // Badge: a round fat cat, crossed out.
  final badge = Offset(f.center.dx, f.top - 2);
  c.drawCircle(badge, 9, _p(const Color(0xFFFFF7EA)));
  c.drawOval(
      Rect.fromCenter(center: badge + const Offset(0, 1), width: 11, height: 9),
      _p(const Color(0xFFE9A15C)));
  for (final s in [-1.0, 1.0]) {
    c.drawPath(
        Path()
          ..moveTo(badge.dx + s * 5, badge.dy - 2)
          ..lineTo(badge.dx + s * 4, badge.dy - 7)
          ..lineTo(badge.dx + s * 1, badge.dy - 3)
          ..close(),
        _p(const Color(0xFFE9A15C)));
  }
  c.drawCircle(
      badge,
      9,
      Paint()
        ..color = const Color(0xFFD9483B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  _line(c, badge + const Offset(-6, -6), badge + const Offset(6, 6),
      const Color(0xFFD9483B), 2);
}

void _shadow(Canvas c, Rect r) =>
    _box(c, r.shift(const Offset(3, 5)), const Color(0x33402A14), 6);

void _sofa(Canvas c, Rect s) {
  _shadow(c, s);
  _box(c, s, const Color(0xFF6E9873), 8);
  _box(c, Rect.fromLTWH(s.left, s.top, s.width, s.height * .45),
      const Color(0xFF5C8462), 8);
  final seat = Rect.fromLTWH(
      s.left + 12, s.top + s.height * .38, s.width - 24, s.height * .55);
  for (var i = 0; i < 3; i++) {
    final w = seat.width / 3;
    _box(c, Rect.fromLTWH(seat.left + i * w + 1, seat.top, w - 2, seat.height),
        const Color(0xFF86AF89), 5);
  }
  for (final x in [s.left, s.right - 12]) {
    _box(c, Rect.fromLTWH(x, s.top + 4, 12, s.height - 2),
        const Color(0xFF557B5A), 6);
  }
  _box(c, Rect.fromLTWH(s.left + 18, s.top + 4, 22, 14),
      const Color(0xFFF4C7A1), 5);
  _box(c, Rect.fromLTWH(s.left + 22, s.top + 6, 14, 10),
      const Color(0xFFE79C88), 4);
}

void _clockCase(Canvas c, Rect k) {
  _shadow(c, k);
  final roof = Path()
    ..moveTo(k.left - 4, k.top + 10)
    ..lineTo(k.center.dx, k.top - 8)
    ..lineTo(k.right + 4, k.top + 10)
    ..close();
  _box(c, Rect.fromLTWH(k.left, k.top + 8, k.width, k.height - 8),
      const Color(0xFF8E5D3B), 4);
  c.drawPath(roof, _p(const Color(0xFF6E4429)));
  _box(c, Rect.fromLTWH(k.center.dx - 4, k.top - 1, 8, 9),
      const Color(0xFF3F2618), 2);
  c.drawCircle(Offset(k.center.dx, k.top + 19), 9, _p(const Color(0xFFFFF4DC)));
  c.drawCircle(
      Offset(k.center.dx, k.top + 19),
      9,
      Paint()
        ..color = const Color(0xFFC59B3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  final face = Offset(k.center.dx, k.top + 19);
  _line(c, face, face + const Offset(0, -6), _ink, 1.4);
  _line(c, face, face + const Offset(4, 2), _ink, 1.4);
  _box(c, Rect.fromLTWH(k.left + 6, k.top + 26, k.width - 12, k.height - 30),
      const Color(0xFF5B3A26), 3);
  _box(c, Rect.fromLTWH(k.left + 4, k.bottom - 4, k.width - 8, 4),
      const Color(0xFF6E4429), 1);
}

void _coffeeTable(Canvas c, Rect t) {
  _shadow(c, t);
  c.drawOval(t, _p(const Color(0xFF9C6A43)));
  c.drawOval(t.deflate(3), _p(const Color(0xFFBF8A5B)));
  final mid = t.center;
  _box(
      c,
      Rect.fromCenter(
          center: mid + const Offset(-6, -2), width: 14, height: 10),
      const Color(0xFFF7F0E2),
      4);
  c.drawCircle(mid + const Offset(-6, -7), 2, _p(const Color(0xFFF7F0E2)));
  c.drawOval(
      Rect.fromCenter(center: mid + const Offset(10, 4), width: 12, height: 7),
      _p(const Color(0xFFF7F0E2)));
  c.drawOval(
      Rect.fromCenter(center: mid + const Offset(10, 3), width: 7, height: 3),
      _p(const Color(0xFFB0703F)));
}

void _wardrobe(Canvas c, Rect w) {
  _shadow(c, w);
  _box(c, w, const Color(0xFF9A643F), 3);
  _box(c, Rect.fromLTWH(w.left - 3, w.top - 4, w.width + 6, 7),
      const Color(0xFF7D4D2F), 2);
  final half = w.width / 2;
  for (var i = 0; i < 2; i++) {
    final door = Rect.fromLTWH(
        w.left + 3 + i * half, w.top + 6, half - 5, w.height - 10);
    _box(c, door, const Color(0xFFB5794D), 2);
    _stroke(
        c,
        RRect.fromRectAndRadius(door.deflate(3), const Radius.circular(2)),
        const Color(0xFF8A5634),
        1);
  }
  for (final dx in [-3.0, 3.0]) {
    c.drawCircle(Offset(w.center.dx + dx, w.center.dy), 1.8,
        _p(const Color(0xFFF3CB65)));
  }
  // A hat box on top.
  _box(c, Rect.fromLTWH(w.left + 8, w.top - 14, 26, 11),
      const Color(0xFFE9A6B4), 3);
}

void _bed(Canvas c, Rect b) {
  _shadow(c, b);
  _box(c, b, const Color(0xFF8A5E3E), 5);
  _box(c, Rect.fromLTWH(b.left + 3, b.top + 6, b.width - 6, b.height - 9),
      const Color(0xFFFFF8EE), 4);
  _box(c, Rect.fromLTWH(b.left + 8, b.top + 9, b.width - 16, 12),
      const Color(0xFFFFFFFF), 5);
  final quilt =
      Rect.fromLTWH(b.left + 3, b.top + 26, b.width - 6, b.height - 29);
  _box(c, quilt, const Color(0xFFE79A8E), 4);
  c.save();
  c.clipRect(quilt);
  for (var y = quilt.top; y < quilt.bottom; y += 12) {
    for (var x = quilt.left; x < quilt.right; x += 12) {
      if (((x - quilt.left) ~/ 12 + (y - quilt.top) ~/ 12).isEven) {
        _box(c, Rect.fromLTWH(x, y, 12, 12), const Color(0xFFF4C1A1));
      }
    }
  }
  c.restore();
  _box(c, Rect.fromLTWH(b.left, b.top, b.width, 7), const Color(0xFF6E4429), 3);
}

void _kitchenTable(Canvas c, Rect t) {
  _shadow(c, t);
  _box(c, t, const Color(0xFFFFFFFF), 4);
  c.save();
  c.clipRRect(RRect.fromRectAndRadius(t, const Radius.circular(4)));
  for (var x = t.left; x < t.right; x += 8) {
    _line(c, Offset(x, t.top), Offset(x, t.bottom), const Color(0x55D9483B), 3);
  }
  for (var y = t.top; y < t.bottom; y += 8) {
    _line(c, Offset(t.left, y), Offset(t.right, y), const Color(0x55D9483B), 3);
  }
  c.restore();
  c.drawCircle(t.center + const Offset(0, -4), 5, _p(const Color(0xFF8CB0D8)));
  c.drawCircle(t.center + const Offset(0, -10), 4, _p(const Color(0xFFF2A3B3)));
  c.drawCircle(t.center + const Offset(-5, -8), 3, _p(const Color(0xFFFFE07A)));
}

void _fridge(Canvas c, Rect f) {
  _shadow(c, f);
  _box(c, f, const Color(0xFFF4F7F8), 4);
  _line(c, Offset(f.left, f.top + f.height * .38),
      Offset(f.right, f.top + f.height * .38), const Color(0xFFC7D0D6), 1.5);
  _line(c, Offset(f.left + 5, f.top + 8), Offset(f.left + 5, f.top + 18),
      const Color(0xFF9AA6AE), 2.5);
  _line(
      c,
      Offset(f.left + 5, f.top + f.height * .45),
      Offset(f.left + 5, f.top + f.height * .45 + 14),
      const Color(0xFF9AA6AE),
      2.5);
  c.drawCircle(Offset(f.right - 9, f.top + 30), 3, _p(const Color(0xFFE48A87)));
  c.drawCircle(
      Offset(f.right - 14, f.top + 40), 2.5, _p(const Color(0xFF8CB98A)));
}

void _yarn(Canvas c, Offset p) {
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(0, 8), width: 22, height: 7),
      _p(const Color(0x33402A14)));
  c.drawCircle(p, 9, _p(const Color(0xFFE77FA0)));
  final strand = Paint()
    ..color = const Color(0xFFF9B9CC)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  for (var i = 0; i < 3; i++) {
    c.drawArc(Rect.fromCircle(center: p, radius: 6.5 - i * 2), i * 1.2, 3.6,
        false, strand);
  }
  c.drawPath(
      Path()
        ..moveTo(p.dx + 8, p.dy + 4)
        ..cubicTo(
            p.dx + 22, p.dy + 14, p.dx + 10, p.dy + 22, p.dx + 28, p.dy + 18),
      Paint()
        ..color = const Color(0xFFE77FA0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
}

void _fishDish(Canvas c, Offset p) {
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(0, 5), width: 30, height: 12),
      _p(const Color(0x33402A14)));
  c.drawOval(Rect.fromCenter(center: p, width: 28, height: 13),
      _p(const Color(0xFF5F95C8)));
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(0, -1), width: 22, height: 8),
      _p(const Color(0xFFDDEBF5)));
  final fish = Path()
    ..moveTo(p.dx - 8, p.dy - 2)
    ..quadraticBezierTo(p.dx, p.dy - 7, p.dx + 6, p.dy - 2)
    ..quadraticBezierTo(p.dx, p.dy + 3, p.dx - 8, p.dy - 2)
    ..moveTo(p.dx + 5, p.dy - 2)
    ..lineTo(p.dx + 10, p.dy - 6)
    ..lineTo(p.dx + 10, p.dy + 2)
    ..close();
  c.drawPath(fish, _p(const Color(0xFFF2A15B)));
  c.drawCircle(Offset(p.dx - 5, p.dy - 3), .9, _p(const Color(0xFF3A2A20)));
}
