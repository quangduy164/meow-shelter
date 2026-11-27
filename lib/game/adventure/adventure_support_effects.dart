part of 'adventure_skills.dart';

// ===========================================================================
// Cat eye: slow aura that also reveals hidden springs.
// ===========================================================================

class AdventureCatEyeAura extends Component {
  AdventureCatEyeAura({required this.obstacles}) : super(priority: 6);

  final List<AdventureObstacle> obstacles;
  Vector2 center = Vector2.zero();
  double timeLeft = 0;
  double _t = 0;

  double get radius => HomeAttack.catEye.radius;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    if (timeLeft <= 0) return;
    final c = Offset(center.x, center.y);
    final blink = timeLeft < 1 && (timeLeft * 10).floor().isEven;
    if (!blink) {
      canvas.drawCircle(c, radius, Paint()..color = const Color(0x14FFD45C));
      final dash = Paint()
        ..color = const Color(0x99E8B422)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      const segments = 30;
      for (var i = 0; i < segments; i++) {
        final a = i * pi * 2 / segments - _t * .4;
        canvas.drawArc(Rect.fromCircle(center: c, radius: radius), a,
            pi / segments, false, dash);
      }
    }
    // Hidden springs in range get a marker.
    for (final o in obstacles) {
      if (o.kind != AdventureObstacleKind.spring || o.springT > 0) continue;
      final p = Offset(o.position.x, o.position.y);
      if ((p - c).distance > radius) continue;
      final pulse = 1 + sin(_t * 8) * .12;
      canvas.drawOval(
          Rect.fromCenter(center: p, width: 40 * pulse, height: 22 * pulse),
          Paint()
            ..color = const Color(0xDDFFC24D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      final mark = p + const Offset(0, -26);
      canvas.drawCircle(mark, 9, Paint()..color = const Color(0xFFFFC24D));
      canvas.drawLine(
          mark + const Offset(0, -5),
          mark + const Offset(0, 1),
          Paint()
            ..color = const Color(0xFF5A3214)
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(mark + const Offset(0, 5), 1.5,
          Paint()..color = const Color(0xFF5A3214));
    }
    // Small glowing eye above the cat.
    final e = c + const Offset(0, -60);
    final eye = Path()
      ..moveTo(e.dx - 13, e.dy)
      ..quadraticBezierTo(e.dx, e.dy - 11, e.dx + 13, e.dy)
      ..quadraticBezierTo(e.dx, e.dy + 11, e.dx - 13, e.dy)
      ..close();
    canvas.drawPath(eye, Paint()..color = const Color(0xFFFFF4DA));
    canvas.drawCircle(e, 5, Paint()..color = const Color(0xFFE8B422));
    canvas.drawOval(Rect.fromCenter(center: e, width: 2.5, height: 9),
        Paint()..color = const Color(0xFF2A1A0A));
    canvas.drawPath(
        eye,
        Paint()
          ..color = const Color(0xFF5A3214)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
  }
}

/// A lightning strike: warning ring that closes in, then the bolt and a flash.
/// [struck] flips true on the frame the damage lands.
class AdventureBolt extends PositionComponent {
  AdventureBolt({required Vector2 position, required this.seed})
      : super(position: position, anchor: Anchor.center, priority: 8);

  final int seed;
  double _t = 0;
  bool struck = false;
  bool strikeNow = false;

  static const double _show = .35;

  @override
  void update(double dt) {
    super.update(dt);
    final before = _t;
    _t += dt;
    strikeNow = before < boltDelay && _t >= boltDelay;
    if (strikeNow) struck = true;
    if (_t > boltDelay + _show) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final ground = Rect.fromCenter(
        center: Offset.zero, width: boltRadius * 2, height: boltRadius * 1.2);
    if (!struck) {
      // Warning: filled zone + a ring shrinking onto the edge.
      final k = (_t / boltDelay).clamp(0.0, 1.0);
      canvas.drawOval(ground, Paint()..color = const Color(0x334FA8FF));
      canvas.drawOval(
          ground,
          Paint()
            ..color = const Color(0xCC8FD0FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero,
              width: ground.width * (2 - k),
              height: ground.height * (2 - k)),
          Paint()
            ..color = Color.fromARGB((220 * k).round(), 0xFF, 0xFF, 0xFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      return;
    }
    final fade = 1 - ((_t - boltDelay) / _show).clamp(0.0, 1.0);
    // Scorch and shock ring.
    canvas.drawOval(ground.deflate(10),
        Paint()..color = Color.fromARGB((90 * fade).round(), 0x2A, 0x2A, 0x3A));
    canvas.drawOval(
        ground.inflate(12 * (1 - fade)),
        Paint()
          ..color = Color.fromARGB((230 * fade).round(), 0xD8, 0xF0, 0xFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // Jagged bolt from far above.
    final random = Random(seed);
    final bolt = Path()..moveTo(random.nextDouble() * 30 - 15, -420);
    var y = -420.0;
    while (y < 0) {
      y = min(0, y + 36 + random.nextDouble() * 30);
      bolt.lineTo(random.nextDouble() * 34 - 17, y);
    }
    final glow = Paint()
      ..color = Color.fromARGB((150 * fade).round(), 0x7F, 0xC8, 0xFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(bolt, glow);
    canvas.drawPath(
        bolt,
        glow
          ..color = Color.fromARGB((255 * fade).round(), 0xFF, 0xFF, 0xFF)
          ..strokeWidth = 4);
    // Sparks.
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 + seed;
      final r = 20 + (1 - fade) * 50;
      canvas.drawLine(
          Offset(cos(a) * r * .6, sin(a) * r * .35),
          Offset(cos(a) * r, sin(a) * r * .6),
          Paint()
            ..color = Color.fromARGB((255 * fade).round(), 0xFF, 0xF2, 0x9A)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }
  }
}

/// Debris and smoke where a hazard was destroyed.
class AdventureBurst extends PositionComponent {
  AdventureBurst({
    required Vector2 position,
    required this.color,
    this.fiery = false,
  }) : super(position: position, anchor: Anchor.center, priority: 7) {
    final random = Random();
    for (var i = 0; i < 9; i++) {
      final a = random.nextDouble() * pi * 2;
      final s = 60 + random.nextDouble() * 120;
      _bits.add((
        v: Vector2(cos(a) * s, sin(a) * s - 80),
        size: 3 + random.nextDouble() * 4,
      ));
    }
  }

  final Color color;
  final bool fiery;
  final _bits = <({Vector2 v, double size})>[];
  double _t = 0;
  static const double _life = .55;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final fade = 1 - k;
    canvas.drawCircle(
        Offset.zero,
        10 + 26 * k,
        Paint()
          ..color = fiery
              ? Color.fromARGB((200 * fade).round(), 0xFF, 0xA0, 0x3A)
              : Color.fromARGB((140 * fade).round(), 0xE8, 0xE0, 0xD0));
    for (final bit in _bits) {
      final p = bit.v * _t + Vector2(0, 260 * _t * _t);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(p.x, p.y), width: bit.size, height: bit.size),
          Paint()..color = color.withAlpha((255 * fade).round()));
    }
  }
}

/// Expanding sound rings from the cat; the outer ring reaches [roarRadius]
/// at the same moment the push lands, so the shown area is the real one.
class AdventureRoarWave extends PositionComponent {
  AdventureRoarWave({required Vector2 position})
      : super(position: position, anchor: Anchor.center, priority: 7);

  double _t = 0;
  static const double _life = .45;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final ease = 1 - (1 - k) * (1 - k);
    final fade = 1 - k;
    canvas.drawCircle(Offset.zero, roarRadius * ease,
        Paint()..color = Color.fromARGB((60 * fade).round(), 0xFF, 0xE8, 0xA8));
    for (var i = 0; i < 3; i++) {
      final r = roarRadius * ease * (1 - i * .22);
      if (r <= 0) continue;
      canvas.drawCircle(
          Offset.zero,
          r,
          Paint()
            ..color = Color.fromARGB(
                (230 * fade * (1 - i * .25)).round(), 0xFF, 0xF4, 0xDA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 - i * 1.5);
    }
    // Sound arcs flying out sideways.
    final arc = Paint()
      ..color = Color.fromARGB((255 * fade).round(), 0xFF, 0xB3, 0x47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = i * pi / 3;
      final r = 30 + roarRadius * .6 * ease;
      canvas.drawArc(
          Rect.fromCircle(
              center: Offset(cos(a) * r * .5, sin(a) * r * .5), radius: 14),
          a - .6,
          1.2,
          false,
          arc);
    }
  }
}

/// Magnetic aura around the cat while magnet claws are active: the dashed
/// circle is the exact pull radius; it flickers in the last second.
class AdventureMagnetAura extends Component {
  AdventureMagnetAura() : super(priority: 4);

  Vector2 center = Vector2.zero();
  double timeLeft = 0;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    if (timeLeft <= 0) return;
    if (timeLeft < 1 && (timeLeft * 10).floor().isEven) return;
    final c = Offset(center.x, center.y);
    canvas.drawCircle(
        c, magnetRadius, Paint()..color = const Color(0x1A5FB0FF));
    final dash = Paint()
      ..color = const Color(0x995FB0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const segments = 24;
    for (var i = 0; i < segments; i++) {
      final a = i * pi * 2 / segments + _t * .8;
      canvas.drawArc(Rect.fromCircle(center: c, radius: magnetRadius), a,
          pi / segments, false, dash);
    }
    // Field lines pulsing inward.
    final pulse = (_t * 1.6) % 1;
    canvas.drawCircle(
        c,
        magnetRadius * (1 - pulse),
        Paint()
          ..color = Color.fromARGB((120 * pulse).round(), 0x9F, 0xD4, 0xFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // Small horseshoe magnet over the cat's head.
    final m = c + const Offset(0, -46);
    final shoe = Paint()
      ..color = const Color(0xFFE0483F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawArc(Rect.fromCircle(center: m, radius: 8), 0, pi, false, shoe);
    final tip = Paint()..color = const Color(0xFFDDE3E8);
    canvas.drawRect(Rect.fromLTWH(m.dx - 10.5, m.dy - 6, 5, 6), tip);
    canvas.drawRect(Rect.fromLTWH(m.dx + 5.5, m.dy - 6, 5, 6), tip);
  }
}
