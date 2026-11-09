import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/skill_glyph.dart';

/// Hand-drawn skill icon: a white shape with a dark outline and a soft drop
/// shadow, readable on any coloured skill button.
class SkillGlyphView extends StatelessWidget {
  const SkillGlyphView(this.glyph, {super.key, this.size = 36});
  final SkillGlyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _SkillGlyphPainter(glyph)),
      );
}

class _SkillGlyphPainter extends CustomPainter {
  const _SkillGlyphPainter(this.glyph);
  final SkillGlyph glyph;

  static const _white = Color(0xFFFFFFFF);
  static const _ink = Color(0xB3402010);

  @override
  void paint(Canvas canvas, Size size) {
    // Every glyph is drawn on a 100x100 grid.
    canvas.save();
    canvas.scale(size.width / 100);
    switch (glyph) {
      case SkillGlyph.sprint:
        _sprint(canvas);
      case SkillGlyph.vanish:
        _vanish(canvas);
      case SkillGlyph.roll:
        _roll(canvas);
      case SkillGlyph.shield:
        _shield(canvas);
      case SkillGlyph.heal:
        _heal(canvas);
      case SkillGlyph.fireball:
        _fireball(canvas);
      case SkillGlyph.bolt:
        _bolt(canvas);
      case SkillGlyph.roar:
        _roar(canvas);
      case SkillGlyph.magnet:
        _magnet(canvas);
      case SkillGlyph.flameBreath:
        _flameBreath(canvas);
      case SkillGlyph.fireBomb:
        _fireBomb(canvas);
      case SkillGlyph.shadowStep:
        _shadowStep(canvas);
      case SkillGlyph.decoy:
        _decoy(canvas);
      case SkillGlyph.timeStop:
        _timeStop(canvas);
      case SkillGlyph.iceShard:
        _iceShard(canvas);
      case SkillGlyph.frostNova:
        _frostNova(canvas);
      case SkillGlyph.iceBridge:
        _iceBridge(canvas);
      case SkillGlyph.stoneWall:
        _stoneWall(canvas);
      case SkillGlyph.reflect:
        _reflect(canvas);
      case SkillGlyph.catEye:
        _catEye(canvas);
    }
    canvas.restore();
  }

  // ---- helpers -----------------------------------------------------------

  void _fill(Canvas canvas, Path path, {Color color = _white}) {
    canvas.drawPath(path.shift(const Offset(0, 4)),
        Paint()..color = const Color(0x40000000));
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round);
  }

  void _line(Canvas canvas, Offset a, Offset b, {double width = 8}) {
    final shadow = Paint()
      ..color = const Color(0x40000000)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a + const Offset(0, 4), b + const Offset(0, 4), shadow);
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = _ink
          ..strokeWidth = width + 4
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = _white
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);
  }

  void _arc(Canvas canvas, Rect rect, double start, double sweep,
      {double width = 8}) {
    Paint p(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.shift(const Offset(0, 4)), start, sweep, false,
        p(const Color(0x40000000), width));
    canvas.drawArc(rect, start, sweep, false, p(_ink, width + 4));
    canvas.drawArc(rect, start, sweep, false, p(_white, width));
  }

  Path _star(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2;
      final rr = i.isEven ? r : r * .38;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  Path _pawPath(Offset c, double r) {
    final path = Path()
      ..addOval(Rect.fromCenter(
          center: c + Offset(0, r * .35), width: r * 1.5, height: r * 1.2));
    for (final d in [
      Offset(-r * .85, -r * .3),
      Offset(-r * .3, -r * .8),
      Offset(r * .3, -r * .8),
      Offset(r * .85, -r * .3),
    ]) {
      path.addOval(Rect.fromCircle(center: c + d, radius: r * .3));
    }
    return path;
  }

  // ---- glyphs ------------------------------------------------------------

  /// Chạy nhanh: double chevron with speed streaks behind.
  void _sprint(Canvas canvas) {
    Path chevron(double x) => Path()
      ..moveTo(x, 22)
      ..lineTo(x + 26, 50)
      ..lineTo(x, 78)
      ..lineTo(x + 14, 78)
      ..lineTo(x + 40, 50)
      ..lineTo(x + 14, 22)
      ..close();
    _line(canvas, const Offset(8, 36), const Offset(24, 36), width: 6);
    _line(canvas, const Offset(4, 50), const Offset(22, 50), width: 6);
    _line(canvas, const Offset(8, 64), const Offset(24, 64), width: 6);
    _fill(canvas, chevron(30));
    _fill(canvas, chevron(54));
  }

  /// Biến mất: a puff of smoke with a cat head fading out and sparkles.
  void _vanish(Canvas canvas) {
    final puff = Path.combine(
        PathOperation.union,
        Path.combine(
            PathOperation.union,
            Path()..addOval(const Rect.fromLTWH(14, 46, 40, 34)),
            Path()..addOval(const Rect.fromLTWH(34, 36, 40, 40))),
        Path()..addOval(const Rect.fromLTWH(56, 50, 32, 30)));
    // Ears poking out of the smoke (drawn first, smoke covers their base).
    final ears = Path()
      ..moveTo(36, 44)
      ..lineTo(40, 26)
      ..lineTo(50, 38)
      ..close()
      ..moveTo(58, 38)
      ..lineTo(68, 26)
      ..lineTo(72, 44)
      ..close();
    _fill(canvas, ears);
    _fill(canvas, puff);
    _fill(canvas, _star(const Offset(20, 26), 12));
    _fill(canvas, _star(const Offset(84, 30), 9));
  }

  /// Lăn né: a curled-up ball with a spiral and motion arcs.
  void _roll(Canvas canvas) {
    _arc(canvas, const Rect.fromLTWH(6, 22, 56, 56), math.pi * .6, math.pi * .8,
        width: 6);
    _fill(canvas, Path()..addOval(const Rect.fromLTWH(30, 22, 56, 56)));
    final spiral = Path()..moveTo(58, 50);
    for (var i = 1; i <= 40; i++) {
      final a = i * .32;
      final r = i * .55;
      spiral.lineTo(58 + math.cos(a) * r, 50 + math.sin(a) * r);
    }
    canvas.drawPath(
        spiral,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round);
  }

  /// Lá chắn: shield with a paw print.
  void _shield(Canvas canvas) {
    final shield = Path()
      ..moveTo(50, 10)
      ..quadraticBezierTo(68, 20, 86, 20)
      ..quadraticBezierTo(88, 66, 50, 90)
      ..quadraticBezierTo(12, 66, 14, 20)
      ..quadraticBezierTo(32, 20, 50, 10)
      ..close();
    _fill(canvas, shield);
    canvas.drawPath(_pawPath(const Offset(50, 50), 15),
        Paint()..color = const Color(0xCC6B9E4E));
  }

  /// Hồi máu: heart with a plus.
  void _heal(Canvas canvas) {
    final heart = Path()
      ..moveTo(50, 86)
      ..cubicTo(8, 58, 8, 22, 32, 18)
      ..cubicTo(42, 16, 48, 24, 50, 30)
      ..cubicTo(52, 24, 58, 16, 68, 18)
      ..cubicTo(92, 22, 92, 58, 50, 86)
      ..close();
    _fill(canvas, heart);
    final plus = Paint()
      ..color = const Color(0xFFD9657B)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(50, 36), const Offset(50, 62), plus);
    canvas.drawLine(const Offset(37, 49), const Offset(63, 49), plus);
  }

  /// Cầu lửa: a round fireball flying right, three flame tongues behind it.
  void _fireball(Canvas canvas) {
    final tail = Path()
      ..moveTo(62, 28)
      ..quadraticBezierTo(36, 22, 10, 18)
      ..quadraticBezierTo(28, 32, 30, 38)
      ..quadraticBezierTo(16, 44, 4, 52)
      ..quadraticBezierTo(22, 56, 28, 62)
      ..quadraticBezierTo(18, 74, 12, 86)
      ..quadraticBezierTo(40, 78, 62, 80)
      ..close();
    final ball = Path()
      ..addOval(Rect.fromCircle(center: const Offset(62, 54), radius: 27));
    _fill(canvas, Path.combine(PathOperation.union, tail, ball));
    canvas.drawCircle(
        const Offset(64, 54), 16, Paint()..color = const Color(0xFFFFC24D));
    canvas.drawCircle(
        const Offset(68, 49), 7, Paint()..color = const Color(0xFFFFF4DA));
  }

  /// Sấm sét: lightning bolt.
  void _bolt(Canvas canvas) {
    final bolt = Path()
      ..moveTo(58, 6)
      ..lineTo(20, 56)
      ..lineTo(46, 56)
      ..lineTo(36, 94)
      ..lineTo(80, 40)
      ..lineTo(54, 40)
      ..lineTo(66, 6)
      ..close();
    _fill(canvas, bolt);
  }

  /// Tiếng gầm: open-mouthed cat head in profile with sound waves.
  void _roar(Canvas canvas) {
    final head = Path()
      ..moveTo(12, 70)
      ..lineTo(12, 34)
      ..lineTo(18, 14)
      ..lineTo(30, 28)
      ..lineTo(40, 28)
      ..lineTo(50, 14)
      ..lineTo(54, 36)
      ..lineTo(56, 46)
      // Open jaw.
      ..lineTo(40, 54)
      ..lineTo(54, 64)
      ..quadraticBezierTo(40, 82, 12, 70)
      ..close();
    _fill(canvas, head);
    canvas.drawCircle(
        const Offset(36, 40), 4, Paint()..color = const Color(0xCC402010));
    _arc(canvas, Rect.fromCircle(center: const Offset(48, 54), radius: 22),
        -.75, 1.5,
        width: 6);
    _arc(canvas, Rect.fromCircle(center: const Offset(48, 54), radius: 36), -.7,
        1.4,
        width: 6);
  }

  /// Móng nam châm: horseshoe magnet with a claw slash and attraction sparks.
  void _magnet(Canvas canvas) {
    final shoe = Path()
      ..moveTo(18, 14)
      ..lineTo(40, 14)
      ..lineTo(40, 52)
      ..arcToPoint(const Offset(60, 52),
          radius: const Radius.circular(10), clockwise: false)
      ..lineTo(60, 14)
      ..lineTo(82, 14)
      ..lineTo(82, 52)
      ..arcToPoint(const Offset(18, 52),
          radius: const Radius.circular(32), clockwise: true)
      ..close();
    _fill(canvas, shoe);
    // Silver pole tips.
    final tip = Paint()..color = const Color(0xFFB8C2CA);
    canvas.drawRect(const Rect.fromLTWH(20, 16, 18, 12), tip);
    canvas.drawRect(const Rect.fromLTWH(62, 16, 18, 12), tip);
    // Attraction sparks between the poles.
    _line(canvas, const Offset(50, 6), const Offset(50, 0), width: 4);
    _line(canvas, const Offset(10, 4), const Offset(14, 0), width: 4);
    _line(canvas, const Offset(90, 4), const Offset(86, 0), width: 4);
  }

  Paint _inkStroke(double width) => Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Front-facing cat head: round face with two pointed ears.
  Path _catHead(Offset c, double r) => Path.combine(
      PathOperation.union,
      Path()
        ..addOval(Rect.fromCenter(center: c, width: r * 2.1, height: r * 1.8)),
      Path()
        ..moveTo(c.dx - r * .95, c.dy - r * .2)
        ..lineTo(c.dx - r * .8, c.dy - r * 1.35)
        ..lineTo(c.dx - r * .15, c.dy - r * .8)
        ..close()
        ..moveTo(c.dx + r * .95, c.dy - r * .2)
        ..lineTo(c.dx + r * .8, c.dy - r * 1.35)
        ..lineTo(c.dx + r * .15, c.dy - r * .8)
        ..close());

  /// Phun lửa: cat head in profile breathing a widening cone of flame.
  void _flameBreath(Canvas canvas) {
    // Cone of fire widening from the mouth, ending in three round tongues.
    final flame = Path()
      ..moveTo(38, 52)
      ..quadraticBezierTo(56, 34, 72, 18)
      ..quadraticBezierTo(92, 14, 90, 32)
      ..quadraticBezierTo(102, 42, 94, 56)
      ..quadraticBezierTo(102, 70, 90, 80)
      ..quadraticBezierTo(90, 96, 70, 90)
      ..quadraticBezierTo(54, 74, 38, 62)
      ..close();
    _fill(canvas, flame);
    final mid = Path()
      ..moveTo(42, 54)
      ..quadraticBezierTo(58, 40, 70, 32)
      ..quadraticBezierTo(84, 32, 80, 44)
      ..quadraticBezierTo(90, 56, 80, 66)
      ..quadraticBezierTo(84, 80, 68, 78)
      ..quadraticBezierTo(56, 68, 42, 60)
      ..close();
    canvas.drawPath(mid, Paint()..color = const Color(0xFFFF8A3A));
    final core = Path()
      ..moveTo(44, 56)
      ..quadraticBezierTo(58, 48, 66, 46)
      ..quadraticBezierTo(76, 50, 72, 58)
      ..quadraticBezierTo(74, 66, 64, 66)
      ..quadraticBezierTo(56, 62, 44, 58)
      ..close();
    canvas.drawPath(core, Paint()..color = const Color(0xFFFFD45C));
    // Cat head in profile facing right, mouth open toward the flame.
    final head = Path()
      ..moveTo(6, 74)
      ..lineTo(6, 40)
      ..lineTo(10, 20)
      ..lineTo(20, 32)
      ..lineTo(28, 32)
      ..lineTo(36, 20)
      ..lineTo(40, 40)
      ..lineTo(42, 50)
      ..lineTo(32, 56)
      ..lineTo(42, 64)
      ..quadraticBezierTo(30, 80, 6, 74)
      ..close();
    _fill(canvas, head);
    canvas.drawCircle(
        const Offset(26, 43), 3.5, Paint()..color = const Color(0xCC402010));
  }

  /// Bom lửa: round bomb with a lit fuse.
  void _fireBomb(Canvas canvas) {
    _fill(
        canvas,
        Path()
          ..addOval(Rect.fromCircle(center: const Offset(44, 60), radius: 30)));
    // Neck the fuse comes out of.
    final neck = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(64, 34), width: 18, height: 14),
          const Radius.circular(3)));
    canvas.save();
    canvas.translate(64, 34);
    canvas.rotate(math.pi / 4);
    canvas.translate(-64, -34);
    _fill(canvas, neck);
    canvas.restore();
    // Shine on the bomb.
    _arc(canvas, Rect.fromCircle(center: const Offset(44, 60), radius: 19),
        math.pi * 1.05, math.pi * .4,
        width: 4);
    // Fuse.
    final fuse = Path()
      ..moveTo(68, 30)
      ..quadraticBezierTo(74, 14, 84, 18);
    canvas.drawPath(fuse, _inkStroke(5));
    // Spark.
    _fill(canvas, _star(const Offset(86, 16), 13),
        color: const Color(0xFFFFC24D));
    canvas.drawCircle(
        const Offset(86, 16), 3.5, Paint()..color = const Color(0xFFFFF4DA));
  }

  /// Dịch chuyển bóng: the cat leaves one shadow portal and pops out of
  /// another, a dotted jump arc between them.
  void _shadowStep(Canvas canvas) {
    void portal(Offset c, double w) {
      canvas.drawOval(
          Rect.fromCenter(
              center: c + const Offset(0, 3), width: w, height: w * .36),
          Paint()..color = const Color(0x40000000));
      _fill(
          canvas,
          Path()
            ..addOval(Rect.fromCenter(center: c, width: w, height: w * .36)));
      canvas.drawOval(
          Rect.fromCenter(center: c, width: w * .66, height: w * .2),
          Paint()..color = const Color(0xFF3A2A6A));
    }

    portal(const Offset(22, 82), 36);
    portal(const Offset(76, 84), 40);
    // Dotted jump arc.
    for (var i = 1; i < 7; i++) {
      final t = i / 7;
      final x = 22 + (76 - 22) * t;
      final y = 78 - math.sin(t * math.pi) * 58;
      canvas.drawCircle(
          Offset(x, y + 3), 4.5, Paint()..color = const Color(0x40000000));
      canvas.drawCircle(Offset(x, y), 5.5, Paint()..color = _ink);
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = _white);
    }
    // Cat head rising out of the far portal.
    _fill(canvas, _catHead(const Offset(76, 62), 15));
    final eye = Paint()..color = const Color(0xFF3A2A6A);
    canvas.drawCircle(const Offset(70, 62), 3, eye);
    canvas.drawCircle(const Offset(82, 62), 3, eye);
  }

  /// Phân thân: a solid cat head with a translucent copy beside it.
  void _decoy(Canvas canvas) {
    final ghost = _catHead(const Offset(34, 46), 24);
    canvas.drawPath(ghost, Paint()..color = const Color(0x80FFFFFF));
    canvas.drawPath(
        ghost,
        Paint()
          ..color = const Color(0x99402010)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeJoin = StrokeJoin.round);
    _fill(canvas, _catHead(const Offset(64, 60), 25));
    final eye = Paint()..color = const Color(0xFF3A2A6A);
    canvas.drawCircle(const Offset(55, 60), 4, eye);
    canvas.drawCircle(const Offset(73, 60), 4, eye);
    canvas.drawCircle(
        const Offset(26, 46), 3.5, Paint()..color = const Color(0x803A2A6A));
    canvas.drawCircle(
        const Offset(42, 46), 3.5, Paint()..color = const Color(0x803A2A6A));
    _fill(canvas, _star(const Offset(16, 80), 10));
  }

  /// Ngưng thời gian: clock face with a pause badge.
  void _timeStop(Canvas canvas) {
    const c = Offset(46, 48);
    _fill(canvas, Path()..addOval(Rect.fromCircle(center: c, radius: 38)));
    // Alarm-clock bells.
    for (final x in [-1.0, 1.0]) {
      canvas.drawArc(
          Rect.fromCircle(center: c + Offset(x * 30, -32), radius: 9),
          x < 0 ? math.pi * .9 : math.pi * 1.2,
          math.pi * .9,
          false,
          _inkStroke(6));
    }
    final tick = _inkStroke(4);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final r1 = i % 3 == 0 ? 25.0 : 29.0;
      canvas.drawLine(c + Offset(math.cos(a) * r1, math.sin(a) * r1),
          c + Offset(math.cos(a) * 32, math.sin(a) * 32), tick);
    }
    canvas.drawLine(c, c + const Offset(0, -22), _inkStroke(6));
    canvas.drawLine(c, c + const Offset(16, 6), _inkStroke(6));
    canvas.drawCircle(c, 5, Paint()..color = _ink);
    // Pause badge.
    const b = Offset(76, 78);
    canvas.drawCircle(
        b + const Offset(0, 3), 18, Paint()..color = const Color(0x40000000));
    canvas.drawCircle(b, 18, Paint()..color = const Color(0xFF3D6FA8));
    canvas.drawCircle(b, 18, _inkStroke(4));
    final bar = Paint()..color = _white;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: b - const Offset(5.5, 0), width: 6, height: 18),
            const Radius.circular(2)),
        bar);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: b + const Offset(5.5, 0), width: 6, height: 18),
            const Radius.circular(2)),
        bar);
  }

  /// Mũi băng: a long ice crystal flying up-right, frost sparkles behind.
  void _iceShard(Canvas canvas) {
    canvas.save();
    canvas.translate(54, 46);
    canvas.rotate(-math.pi / 4);
    final shard = Path()
      ..moveTo(44, 0)
      ..lineTo(14, -14)
      ..lineTo(-34, -8)
      ..lineTo(-44, 0)
      ..lineTo(-34, 8)
      ..lineTo(14, 14)
      ..close();
    _fill(canvas, shard);
    final facet = Paint()
      ..color = const Color(0xFF8FD0F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-38, 0), const Offset(40, 0), facet);
    canvas.drawLine(const Offset(14, -12), const Offset(14, 12), facet);
    canvas.drawPath(
        Path()
          ..moveTo(14, -14)
          ..lineTo(44, 0)
          ..lineTo(14, 0)
          ..close(),
        Paint()..color = const Color(0x668FD0F0));
    canvas.restore();
    _fill(canvas, _star(const Offset(16, 86), 10));
    _fill(canvas, _star(const Offset(12, 60), 6));
    _fill(canvas, _star(const Offset(38, 90), 6));
  }

  /// Vùng băng giá: a snowflake bursting out of a frost ring.
  void _frostNova(Canvas canvas) {
    const c = Offset(50, 50);
    _arc(canvas, Rect.fromCircle(center: c, radius: 42), -math.pi * .35,
        math.pi * .5,
        width: 5);
    _arc(canvas, Rect.fromCircle(center: c, radius: 42), math.pi * .65,
        math.pi * .5,
        width: 5);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      _line(canvas, c, c + dir * 32, width: 7);
    }
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      final mid = c + dir * 20;
      for (final s in [-1.0, 1.0]) {
        final b = a + s * .75;
        _line(canvas, mid, mid + Offset(math.cos(b), math.sin(b)) * 11,
            width: 5);
      }
    }
    canvas.drawCircle(c, 8, Paint()..color = _ink);
    canvas.drawCircle(c, 5, Paint()..color = const Color(0xFF8FD0F0));
  }

  /// Cầu băng: an arched slab of ice blocks over waves.
  void _iceBridge(Canvas canvas) {
    final wave = _inkStroke(5);
    final waveFill = Paint()
      ..color = _white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final y in [80.0, 92.0]) {
      final path = Path()..moveTo(8, y);
      for (var x = 8.0; x < 92; x += 14) {
        path.quadraticBezierTo(x + 3.5, y - 6, x + 7, y);
        path.quadraticBezierTo(x + 10.5, y + 6, x + 14, y);
      }
      canvas.drawPath(path, wave);
      canvas.drawPath(path, waveFill);
    }
    final bridge = Path()
      ..moveTo(4, 72)
      ..quadraticBezierTo(50, 8, 96, 72)
      ..lineTo(82, 72)
      ..quadraticBezierTo(50, 32, 18, 72)
      ..close();
    _fill(canvas, bridge);
    // Block joints along the arch.
    final joint = Paint()
      ..color = const Color(0xFF6FB8DC)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (final t in [.2, .4, .6, .8]) {
      double qx(double a, double b, double c, double t) =>
          (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c;
      final outer = Offset(qx(4, 50, 96, t), qx(72, 8, 72, t));
      final inner = Offset(qx(18, 50, 82, t), qx(72, 32, 72, t));
      canvas.drawLine(outer, inner, joint);
    }
    _fill(canvas, _star(const Offset(50, 22), 8));
  }

  /// Tường đá: a short wall of stacked stones.
  void _stoneWall(Canvas canvas) {
    // Three courses of staggered stones, each course a little offset.
    const courses = [
      (y: 66.0, xs: [6.0, 37.0, 68.0], w: 27.0),
      (y: 44.0, xs: [6.0, 22.0, 53.0, 84.0], w: 27.0),
      (y: 22.0, xs: [6.0, 37.0, 68.0], w: 27.0),
    ];
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 98, 100));
    for (final row in courses) {
      for (final x in row.xs) {
        // Half stones at the ends of the middle course.
        final w = row.xs.length == 4 && (x == 6 || x == 84) ? 12.0 : row.w;
        final stone = Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromLTWH(x, row.y, w, 20), const Radius.circular(6)));
        _fill(canvas, stone, color: const Color(0xFFF2EBDD));
        if (w > 20) {
          canvas.drawLine(
              Offset(x + 5, row.y + 6),
              Offset(x + 13, row.y + 5),
              Paint()
                ..color = const Color(0xFFB8A890)
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round);
        }
      }
    }
    canvas.restore();
    _line(canvas, const Offset(4, 93), const Offset(96, 93), width: 5);
  }

  /// Phản đòn: an incoming arrow bouncing off a mirror shield.
  void _reflect(Canvas canvas) {
    final mirror = Path()
      ..moveTo(72, 8)
      ..lineTo(90, 18)
      ..lineTo(90, 82)
      ..lineTo(72, 92)
      ..close();
    _fill(canvas, mirror);
    final shine = Paint()
      ..color = const Color(0xFF8FD8CC)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(78, 24), const Offset(78, 44), shine);
    canvas.drawLine(const Offset(84, 34), const Offset(84, 50), shine);
    // Arrow in and out, bending on the mirror.
    final path = Path()
      ..moveTo(10, 16)
      ..lineTo(66, 50)
      ..lineTo(18, 82);
    canvas.drawPath(
        path.shift(const Offset(0, 4)),
        Paint()
          ..color = const Color(0x40000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(path, _inkStroke(12));
    canvas.drawPath(
        path,
        Paint()
          ..color = _white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
    final head = Path()
      ..moveTo(6, 90)
      ..lineTo(14, 68)
      ..lineTo(28, 84)
      ..close();
    _fill(canvas, head);
    _fill(canvas, _star(const Offset(62, 50), 9),
        color: const Color(0xFFFFE680));
  }

  /// Mắt mèo: a glowing cat eye with a slit pupil.
  void _catEye(Canvas canvas) {
    const c = Offset(50, 52);
    final ray = _inkStroke(4);
    final rayFill = Paint()
      ..color = _white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final a in [-math.pi / 2, -math.pi * .25, -math.pi * .75]) {
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * 34, c + d * 46, ray..strokeWidth = 8);
      canvas.drawLine(c + d * 34, c + d * 46, rayFill);
    }
    final eye = Path()
      ..moveTo(6, 58)
      ..quadraticBezierTo(50, 10, 94, 58)
      ..quadraticBezierTo(50, 106, 6, 58)
      ..close();
    _fill(canvas, eye);
    canvas.drawCircle(
        const Offset(50, 58), 19, Paint()..color = const Color(0xFFE8B422));
    canvas.drawCircle(const Offset(50, 58), 19, _inkStroke(3));
    canvas.drawPath(
        Path()
          ..moveTo(50, 40)
          ..quadraticBezierTo(58, 58, 50, 76)
          ..quadraticBezierTo(42, 58, 50, 40)
          ..close(),
        Paint()..color = const Color(0xFF2A1A0A));
    canvas.drawCircle(const Offset(57, 50), 4, Paint()..color = _white);
  }

  @override
  bool shouldRepaint(covariant _SkillGlyphPainter old) => glyph != old.glyph;
}
