import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'herd_map.dart';
import 'herd_text_cache.dart';
import 'herd_round.dart';

/// Small train station art. Base uses the 800x375 design space; the train
/// is drawn in pixels so carriages keep their shape on every screen.
Rect _r(Rect f) =>
    Rect.fromLTWH(f.left * 800, f.top * 375, f.width * 800, f.height * 375);
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
void _label(Canvas c, String text, Offset center, double size, Color color) {
  final t = herdLabel(text, size, color);
  t.paint(c, center - Offset(t.width / 2, t.height / 2));
}

const _ink = Color(0xFF5A3214);

void paintStationBase(Canvas c, HerdRound r) {
  final track = _r(HerdStation.track);
  // Sky, distant hills and the platform canopy along the top.
  c.drawRect(
      const Rect.fromLTWH(0, 0, 800, 64),
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFBFE3EE), Color(0xFFE9F5E9)])
            .createShader(const Rect.fromLTWH(0, 0, 800, 64)));
  for (final (x, w, color) in [
    (120.0, 260.0, const Color(0xFFA9CF9B)),
    (420.0, 300.0, const Color(0xFF97C38E)),
    (700.0, 240.0, const Color(0xFFA9CF9B)),
  ]) {
    c.drawOval(Rect.fromCenter(center: Offset(x, 64), width: w, height: 70),
        _p(color));
  }
  // Platforms: warm paving with joints.
  for (final area in [
    Rect.fromLTWH(0, 60, 800, track.top - 60),
    Rect.fromLTWH(0, track.bottom, 800, 375 - track.bottom),
  ]) {
    _box(c, area, const Color(0xFFE8D7B8));
    c.save();
    c.clipRect(area);
    var row = 0;
    for (var y = area.top; y < area.bottom; y += 18, row++) {
      _line(c, Offset(0, y), Offset(800, y), const Color(0xFFD5C09B), 1);
      for (var x = row.isEven ? 0.0 : 18.0; x < 800; x += 36) {
        _line(c, Offset(x, y), Offset(x, y + 18), const Color(0xFFD5C09B), 1);
      }
    }
    c.restore();
  }
  // Canopy roof over the upper platform.
  _box(c, const Rect.fromLTWH(0, 56, 800, 10), const Color(0xFF7A9C6E));
  for (var x = 0.0; x < 800; x += 26) {
    c.drawArc(
        Rect.fromLTWH(x, 58, 26, 14),
        0,
        math.pi,
        true,
        _p(x ~/ 26 % 2 == 0
            ? const Color(0xFFF2EBDD)
            : const Color(0xFFD9675A)));
  }
  // Rails: ballast, sleepers, two shiny rails.
  _box(c, track, const Color(0xFF9C8F84));
  final random = math.Random(4);
  for (var i = 0; i < 260; i++) {
    c.drawCircle(
        Offset(random.nextDouble() * 800,
            track.top + random.nextDouble() * track.height),
        1.3,
        _p(const Color(0xFF857971)));
  }
  for (var x = 4.0; x < 800; x += 16) {
    _box(c, Rect.fromLTWH(x, track.top + 7, 9, track.height - 14),
        const Color(0xFF7B5A43), 1);
  }
  for (final y in [track.top + 16, track.bottom - 16]) {
    _line(c, Offset(0, y), Offset(800, y), const Color(0xFF5E5E66), 4);
    _line(c, Offset(0, y - 1.5), Offset(800, y - 1.5), const Color(0xFFC9CDD6),
        1.4);
  }
  // Yellow safety strips with tactile dots on both platform edges.
  for (final y in [track.top - 8, track.bottom]) {
    _box(c, Rect.fromLTWH(0, y, 800, 8), const Color(0xFFF2C437));
    for (var x = 4.0; x < 800; x += 9) {
      c.drawCircle(Offset(x, y + 4), 1.3, _p(const Color(0xFFD9A825)));
    }
  }
  // Stop markers where the train opens its doors.
  for (final (x, name) in [
    (HerdTrain.westX, 'GA TÂY'),
    (HerdTrain.eastX, 'GA ĐÔNG'),
  ]) {
    final at = Offset(x * 800, track.bottom + 22);
    _box(c, Rect.fromCenter(center: at, width: 64, height: 16),
        const Color(0xFF3F6E8C), 4);
    _label(c, name, at, 9, const Color(0xFFFFFFFF));
  }
  _hall(c, _r(HerdStation.hall));
  for (final b in HerdStation.benches) {
    _bench(c, _r(b));
  }
  _kiosk(c, _r(HerdStation.kiosk));
  _luggage(c, _r(HerdStation.luggage));
  for (final x in [140.0, 330.0, 600.0, 740.0]) {
    _lamp(c, Offset(x, track.top - 14));
  }
  // Flower boxes on the lower platform.
  for (final x in [200.0, 420.0, 640.0]) {
    _box(c, Rect.fromLTWH(x, 352, 34, 12), const Color(0xFFA9714B), 3);
    for (var i = 0; i < 4; i++) {
      c.drawCircle(Offset(x + 5 + i * 8.0, 350), 4,
          _p(i.isEven ? const Color(0xFFF08BB4) : const Color(0xFFFFD36B)));
    }
  }
}

void paintStationMotion(Canvas c, HerdRound r) {
  // Signal lights at both stops: green while doors are open.
  final track = _r(HerdStation.track);
  for (var i = 0; i < 2; i++) {
    final x = (i == 0 ? HerdTrain.westX - .18 : HerdTrain.eastX + .18) * 800;
    final open = HerdTrain.stop(r.time) == i;
    final at = Offset(x, track.top - 30);
    _line(c, at, at + const Offset(0, 22), const Color(0xFF4F5560), 3);
    _box(c, Rect.fromCenter(center: at, width: 12, height: 22),
        const Color(0xFF2E333B), 3);
    c.drawCircle(at + const Offset(0, -5), 3.6,
        _p(open ? const Color(0xFF39434F) : const Color(0xFFF0554A)));
    c.drawCircle(at + const Offset(0, 5), 3.6,
        _p(open ? const Color(0xFF6BE07A) : const Color(0xFF39434F)));
  }
}

/// The train itself, plus a door countdown and the horn blast.
void paintStationTrain(Canvas canvas, HerdRound r) {
  final car = r.trainAt(r.time);
  if (car == null || car.right < -10 || car.left > r.field.x + 10) return;
  final open = HerdTrain.open(r.time);
  final h = car.height;
  final body = Rect.fromLTRB(car.left, car.top + 3, car.right, car.bottom - 3);
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          body.shift(const Offset(0, 5)), const Radius.circular(10)),
      _p(const Color(0x44402A14)));
  // Locomotive nose on the right, two carriages behind it.
  final nose =
      Rect.fromLTRB(body.right - h * .9, body.top, body.right, body.bottom);
  final cars = Rect.fromLTRB(body.left, body.top, nose.left + 4, body.bottom);
  _box(canvas, cars, const Color(0xFFE76F51), 9);
  _box(canvas, Rect.fromLTWH(cars.left, cars.top, cars.width, h * .22),
      const Color(0xFFF6EFE2), 9);
  _box(canvas, Rect.fromLTWH(cars.left, cars.bottom - 7, cars.width, 6),
      const Color(0xFF9E3F2E), 3);
  canvas.drawRRect(RRect.fromRectAndRadius(nose, const Radius.circular(18)),
      _p(const Color(0xFF2F7F9A)));
  _box(
      canvas,
      Rect.fromLTWH(nose.left + 6, nose.top + 6, nose.width - 18, h * .3),
      const Color(0xFFBFE6F0),
      6);
  canvas.drawCircle(Offset(nose.right - 7, nose.center.dy + 4), 4,
      _p(const Color(0xFFFFE9A3)));
  // Carriage joint.
  final joint = cars.left + cars.width / 2;
  _line(canvas, Offset(joint, cars.top + 2), Offset(joint, cars.bottom - 2),
      const Color(0xFF9E3F2E), 3);
  // Doors slide open; inside is a warm lit floor the herd can stand on.
  for (final half in [
    Rect.fromLTRB(cars.left + 10, cars.top, joint - 6, cars.bottom),
    Rect.fromLTRB(joint + 6, cars.top, cars.right - 10, cars.bottom),
  ]) {
    if (open) {
      _box(canvas, half.deflate(2), const Color(0xFFFFE8B8), 6);
      for (var x = half.left + 10; x < half.right - 6; x += 20) {
        _line(canvas, Offset(x, half.top + 6), Offset(x, half.bottom - 6),
            const Color(0x33B07A3C), 2);
      }
    } else {
      for (var x = half.left + 4; x < half.right - 14; x += 22) {
        _box(canvas, Rect.fromLTWH(x, cars.top + 6, 16, h * .36),
            const Color(0xFFBFE6F0), 3);
      }
    }
  }
  // Countdown lights above the doors while they are open.
  if (open) {
    final left = HerdTrain.closingIn(r.time);
    final lit = left.ceil().clamp(0, 4);
    for (var i = 0; i < 4; i++) {
      final on = i < lit;
      final blink = left < 1.2 && (r.time * 8).floor().isEven;
      canvas.drawCircle(
          Offset(cars.center.dx - 21 + i * 14, cars.top - 7),
          4.5,
          _p(on && !blink
              ? (left < 1.5 ? const Color(0xFFF0554A) : const Color(0xFF6BE07A))
              : const Color(0x88444444)));
    }
  }
  // Horn blast lines in front of the locomotive.
  if (HerdTrain.horn(r.time) != null) {
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
          Rect.fromCircle(
              center: Offset(nose.right + 4, nose.center.dy),
              radius: 10.0 + i * 8),
          -.7,
          1.4,
          false,
          Paint()
            ..color = const Color(0xCC5A3214)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }
    _label(canvas, 'TUUU!', Offset(nose.right + 30, nose.top - 10), 13,
        const Color(0xFFB8463E));
  }
}

void _hall(Canvas c, Rect h) {
  _box(c, h.shift(const Offset(4, 5)), const Color(0x33402A14), 6);
  _box(c, h, const Color(0xFFF1E3C8), 5);
  final roof = Path()
    ..moveTo(h.left - 10, h.top + 14)
    ..lineTo(h.center.dx, h.top - 10)
    ..lineTo(h.right + 10, h.top + 14)
    ..close();
  c.drawPath(roof, _p(const Color(0xFFB9574A)));
  // Clock and sign.
  final clock = Offset(h.center.dx, h.top + 22);
  c.drawCircle(clock, 11, _p(const Color(0xFFFFFFFF)));
  c.drawCircle(
      clock,
      11,
      Paint()
        ..color = const Color(0xFF5A3214)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  _line(c, clock, clock + const Offset(0, -7), _ink, 1.6);
  _line(c, clock, clock + const Offset(5, 2), _ink, 1.6);
  _box(
      c,
      Rect.fromCenter(
          center: Offset(h.center.dx, h.top + 46), width: 84, height: 18),
      const Color(0xFF3F6E8C),
      4);
  _label(c, 'GA MÈO', Offset(h.center.dx, h.top + 46), 10,
      const Color(0xFFFFFFFF));
  // Ticket windows.
  for (final dx in [-24.0, 4.0]) {
    _box(c, Rect.fromLTWH(h.center.dx + dx, h.top + 62, 20, 18),
        const Color(0xFFBFE6F0), 3);
    _box(c, Rect.fromLTWH(h.center.dx + dx - 2, h.top + 80, 24, 4),
        const Color(0xFF9A643F), 1);
  }
  _box(c, Rect.fromLTWH(h.center.dx - 12, h.bottom - 22, 24, 22),
      const Color(0xFF8A5634), 3);
}

void _bench(Canvas c, Rect b) {
  _box(c, b.shift(const Offset(2, 4)), const Color(0x33402A14), 3);
  for (final x in [b.left + 5, b.right - 9]) {
    _box(c, Rect.fromLTWH(x, b.top + 4, 4, b.height), const Color(0xFF4F5560),
        1);
  }
  _box(c, Rect.fromLTWH(b.left, b.top, b.width, b.height * .55),
      const Color(0xFFB0794C), 3);
  for (var i = 1; i < 3; i++) {
    _line(
        c,
        Offset(b.left + 2, b.top + i * b.height * .18),
        Offset(b.right - 2, b.top + i * b.height * .18),
        const Color(0xFF8A5634),
        1);
  }
}

void _kiosk(Canvas c, Rect k) {
  _box(c, k.shift(const Offset(3, 4)), const Color(0x33402A14), 4);
  _box(c, k, const Color(0xFF6E9873), 4);
  _box(c, Rect.fromLTWH(k.left - 3, k.top - 6, k.width + 6, 9),
      const Color(0xFFF2C437), 3);
  _box(c, Rect.fromLTWH(k.left + 6, k.top + 8, k.width - 12, 10),
      const Color(0xFFFFF4DA), 2);
  for (var i = 0; i < 3; i++) {
    c.drawCircle(
        Offset(k.left + 12 + i * 12.0, k.top + 13),
        3,
        _p([
          const Color(0xFFF08BB4),
          const Color(0xFF8CB0D8),
          const Color(0xFFFFD36B)
        ][i]));
  }
}

void _luggage(Canvas c, Rect l) {
  _box(c, l.shift(const Offset(3, 4)), const Color(0x33402A14), 4);
  _box(c, Rect.fromLTWH(l.left, l.top + 6, l.width, l.height - 6),
      const Color(0xFF3F6E8C), 4);
  _box(c, Rect.fromLTWH(l.left + 4, l.top - 4, l.width - 8, 12),
      const Color(0xFFE76F51), 3);
  _line(c, Offset(l.center.dx - 5, l.top - 4),
      Offset(l.center.dx - 5, l.top - 10), const Color(0xFF4F5560), 2);
  _line(c, Offset(l.center.dx + 5, l.top - 4),
      Offset(l.center.dx + 5, l.top - 10), const Color(0xFF4F5560), 2);
  _line(c, Offset(l.center.dx - 5, l.top - 10),
      Offset(l.center.dx + 5, l.top - 10), const Color(0xFF4F5560), 2);
}

void _lamp(Canvas c, Offset base) {
  _line(c, base, base - const Offset(0, 40), const Color(0xFF4F5560), 3);
  c.drawCircle(base - const Offset(0, 42), 5, _p(const Color(0xFFFFE9A3)));
  c.drawCircle(base - const Offset(0, 42), 9, _p(const Color(0x33FFE9A3)));
}
