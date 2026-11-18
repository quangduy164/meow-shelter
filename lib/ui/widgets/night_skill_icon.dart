import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Night-shift helper skill art, one per breed. Drawn on a 48x48 grid in the
/// chunky cream-and-ink style of the night card icons, to sit on the
/// coloured skill button.
class NightSkillIcon extends StatelessWidget {
  const NightSkillIcon(this.catType, {super.key, this.size = 32});
  final String catType;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size, child: CustomPaint(painter: _SkillPainter(catType)));
}

const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);
const _gold = Color(0xFFFFC24D);
const _ice = Color(0xFFDFF4FF);
const _sky = Color(0xFF8FCBEA);

Paint _line(double w) => Paint()
  ..color = _ink
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint _fill(Color c) => Paint()..color = c;

class _SkillPainter extends CustomPainter {
  const _SkillPainter(this.type);
  final String type;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    switch (type) {
      case 'orange':
        _stoppedClock(canvas);
      case 'black':
        _sleepyMoon(canvas);
      case 'scottish':
        _snowflake(canvas);
      case 'calico':
        _sureStar(canvas);
      default:
        _callBell(canvas);
    }
  }

  /// Orange: time stands still — a clock with a pause sign.
  void _stoppedClock(Canvas c) {
    const o = Offset(24, 25);
    for (final dx in const [-11.0, 11.0]) {
      c.drawCircle(o + Offset(dx, -15), 4.5, _fill(_gold));
      c.drawCircle(o + Offset(dx, -15), 4.5, _line(2.5));
    }
    for (final dx in const [-9.0, 9.0]) {
      c.drawLine(o + Offset(dx * .8, 13), o + Offset(dx, 19), _line(3));
    }
    c.drawCircle(o, 16, _fill(_cream));
    c.drawCircle(o, 16, _line(3));
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(o + d * 12, o + d * 14, _line(2));
    }
    for (final dx in const [-4.0, 4.0]) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: o + Offset(dx, 0), width: 5, height: 13),
              const Radius.circular(2)),
          _fill(_ink));
    }
  }

  /// Black: calm — a sleepy crescent moon with a little "z".
  void _sleepyMoon(Canvas c) {
    final moon = Path.combine(
        PathOperation.difference,
        Path()
          ..addOval(Rect.fromCircle(center: const Offset(21, 27), radius: 15)),
        Path()
          ..addOval(Rect.fromCircle(center: const Offset(30, 21), radius: 13)));
    c.drawPath(moon, _fill(_gold));
    c.drawPath(moon, _line(3));
    // Closed eye on the crescent.
    c.drawArc(Rect.fromCircle(center: const Offset(13, 28), radius: 3.2), .3,
        math.pi - .6, false, _line(2));
    void z(Offset at, double s) => c.drawPath(
        Path()
          ..moveTo(at.dx, at.dy)
          ..lineTo(at.dx + s, at.dy)
          ..lineTo(at.dx, at.dy + s)
          ..lineTo(at.dx + s, at.dy + s),
        _line(2.6));
    z(const Offset(31, 9), 8);
    z(const Offset(39, 21), 5.5);
  }

  /// Scottish: slow-down frost — a chunky snowflake.
  void _snowflake(Canvas c) {
    const o = Offset(24, 24);
    for (final w in const [7.5, 4.0]) {
      final p = w > 5 ? _line(w) : (_line(w)..color = _ice);
      for (var i = 0; i < 3; i++) {
        final a = i * math.pi / 3 + math.pi / 2;
        final d = Offset(math.cos(a), math.sin(a)) * 17;
        c.drawLine(o - d, o + d, p);
        for (final s in const [1.0, -1.0]) {
          final tip = o + d * (s * .62);
          final n = Offset(math.cos(a + .9), math.sin(a + .9)) * 6;
          final m = Offset(math.cos(a - .9), math.sin(a - .9)) * 6;
          c.drawLine(tip, tip + n * s, p);
          c.drawLine(tip, tip + m * s, p);
        }
      }
    }
    c.drawCircle(o, 4.5, _fill(_sky));
    c.drawCircle(o, 4.5, _line(2));
  }

  /// Calico: a sure thing — a gold star stamped with a check.
  void _sureStar(Canvas c) {
    const o = Offset(24, 25);
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 19.0 : 9.5;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = o + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c.drawPath(star, _fill(_gold));
    c.drawPath(star, _line(3));
    c.drawPath(
        Path()
          ..moveTo(19.5, 25.5)
          ..lineTo(23, 29)
          ..lineTo(28.5, 22),
        _line(3));
    c.drawCircle(const Offset(39, 9), 2.4, _fill(_cream));
    c.drawCircle(const Offset(8, 13), 1.8, _fill(_cream));
  }

  /// Himalaya: calls cats over — a bell ringing.
  void _callBell(Canvas c) {
    final bell = Path()
      ..moveTo(12, 34)
      ..quadraticBezierTo(15, 31, 15, 22)
      ..quadraticBezierTo(15, 11, 24, 11)
      ..quadraticBezierTo(33, 11, 33, 22)
      ..quadraticBezierTo(33, 31, 36, 34)
      ..close();
    c.drawCircle(const Offset(24, 9), 3, _fill(_cream));
    c.drawCircle(const Offset(24, 9), 3, _line(2.2));
    c.drawPath(bell, _fill(_gold));
    c.drawPath(bell, _line(3));
    c.drawCircle(const Offset(24, 37.5), 3.6, _fill(_cream));
    c.drawCircle(const Offset(24, 37.5), 3.6, _line(2.2));
    c.drawLine(const Offset(19, 18), const Offset(18.5, 25),
        _line(2.4)..color = _cream);
    for (final s in const [-1.0, 1.0]) {
      for (final r in const [6.0, 11.0]) {
        c.drawArc(
            Rect.fromCircle(center: Offset(24 + s * 14, 21), radius: r * .55),
            s > 0 ? -.8 : math.pi - .8 + 0,
            1.6,
            false,
            _line(2.3));
      }
    }
  }

  @override
  bool shouldRepaint(_SkillPainter old) => old.type != type;
}
