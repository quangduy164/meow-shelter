part of 'adventure_skills.dart';

// ===========================================================================
// Fire: breath cone and fire bomb.
// ===========================================================================

class _Spark {
  _Spark(this.p, this.v, this.life, this.size);
  final Vector2 p, v;
  final double life, size;
  double age = 0;
}

/// A cone of fire pouring from the cat's mouth for [HomeAttack.flameBreath]
/// duration. The game moves [position] with the cat each frame; the direction
/// is fixed at cast. [tickNow] is true on the frames the flames hurt.
class AdventureFlameBreath extends PositionComponent {
  AdventureFlameBreath({required Vector2 position, required this.direction})
      : super(position: position, anchor: Anchor.center, priority: 7);

  final Vector2 direction;
  static final _random = Random();
  final _particles = <_Spark>[];
  double _t = 0;
  double _emit = 0;
  bool tickNow = false;

  double get range => HomeAttack.flameBreath.range;
  double get halfAngle => HomeAttack.flameBreath.radius;
  double get duration => HomeAttack.flameBreath.duration;
  bool get blowing => _t < duration;

  /// Inside the cone (from the current mouth position).
  bool covers(Vector2 p) {
    final d = p - position;
    final distance = d.length;
    if (distance > range + 12) return false;
    if (distance < 18) return true;
    final cosA = d.dot(direction) / distance;
    return cosA >= cos(halfAngle + .12);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final before = _t;
    _t += dt;
    tickNow = blowing && (before / fireTick).floor() != (_t / fireTick).floor();
    if (before == 0) tickNow = true;
    if (blowing) {
      _emit += dt * 150;
      final base = atan2(direction.y, direction.x);
      while (_emit >= 1) {
        _emit -= 1;
        final a = base + (_random.nextDouble() * 2 - 1) * halfAngle * .92;
        const life = .42;
        final speed = range / life * (.85 + _random.nextDouble() * .2);
        _particles.add(_Spark(
            position.clone() + direction * 6,
            Vector2(cos(a), sin(a)) * speed,
            life,
            3.5 + _random.nextDouble() * 3.5));
      }
    }
    for (var i = _particles.length - 1; i >= 0; i--) {
      final q = _particles[i];
      q.age += dt;
      if (q.age >= q.life) {
        _particles.removeAt(i);
        continue;
      }
      q.p.add(q.v * dt);
      // Fire slows and rises a little as it burns out.
      q.v.scale(1 - dt * .5);
      q.v.y -= 30 * dt;
    }
    if (!blowing && _particles.isEmpty) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (blowing) {
      // Heat haze over the exact damage cone.
      final base = atan2(direction.y, direction.x);
      final rect = Rect.fromCircle(center: Offset.zero, radius: range);
      final k = 1 - (_t / duration);
      canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..arcTo(rect, base - halfAngle, halfAngle * 2, false)
            ..close(),
          Paint()
            ..color = Color.fromARGB((50 * k + 20).round(), 0xFF, 0x8A, 0x2A));
    }
    for (final q in _particles) {
      final k = q.age / q.life;
      final p = q.p - position;
      // White-hot at the mouth, through yellow and orange to a thin smoke.
      final color = k < .15
          ? const Color(0xFFFFF6D0)
          : k < .4
              ? Color.lerp(const Color(0xFFFFD45C), const Color(0xFFFF9A3A),
                  (k - .15) / .25)!
              : k < .78
                  ? Color.lerp(const Color(0xFFFF8A3A), const Color(0xFFE0402A),
                      (k - .4) / .38)!
                  : const Color(0xFF8A7A72);
      final alpha = k < .78 ? .92 : (1 - k) * 1.6;
      final size = q.size * (1 + k * 1.3);
      canvas.drawCircle(
          Offset(p.x, p.y), size, Paint()..color = _a(color, alpha));
    }
  }
}

/// A bomb lobbed onto [target]: it flies [bombFlight] s, explodes (destroying
/// everything in its ellipse, [explodeNow]) and leaves a fire patch for
/// [HomeAttack.fireBomb] duration that burns whatever walks in ([tickNow]).
class AdventureFireBomb extends PositionComponent {
  AdventureFireBomb({required Vector2 from, required this.target})
      : _from = from.clone(),
        super(position: target.clone(), anchor: Anchor.center, priority: 7);

  final Vector2 _from;
  final Vector2 target;
  double _t = 0;
  bool explodeNow = false;
  bool tickNow = false;
  bool empowered = false;

  double get radius => HomeAttack.fireBomb.radius;
  double get _burn => HomeAttack.fireBomb.duration;
  bool get landed => _t >= bombFlight;
  bool covers(Vector2 p) => inGroundEllipse(p, target, radius);

  /// A burning patch can be reignited by a fireball once per bomb.
  bool ignite() {
    if (!landed || empowered || _t >= bombFlight + _burn) return false;
    empowered = true;
    _t = bombFlight;
    explodeNow = true;
    tickNow = false;
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final before = _t;
    _t += dt;
    explodeNow = before < bombFlight && _t >= bombFlight;
    tickNow = landed &&
        !explodeNow &&
        _t < bombFlight + _burn &&
        ((before - bombFlight) / .25).floor() !=
            ((_t - bombFlight) / .25).floor();
    if (_t > bombFlight + _burn) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final zone = groundEllipse(Vector2.zero(), radius);
    if (!landed) {
      final k = _t / bombFlight;
      // Landing marker grows while the bomb is in the air.
      canvas.drawOval(zone,
          Paint()..color = Color.fromARGB((60 * k).round(), 0xFF, 0x5A, 0x2A));
      canvas.drawOval(
          zone,
          Paint()
            ..color = const Color(0xAAFF8A3A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      final ground = (_from + (target - _from) * k) - target;
      final lift = sin(pi * k) * 70;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ground.x, ground.y + 6), width: 18, height: 7),
          Paint()..color = const Color(0x55000000));
      final b = Offset(ground.x, ground.y - lift);
      canvas.drawCircle(b, 10, Paint()..color = const Color(0xFF2E2A2C));
      canvas.drawCircle(b + const Offset(-3, -3), 3,
          Paint()..color = const Color(0xFF8A8285));
      canvas.drawLine(
          b + const Offset(5, -8),
          b + const Offset(9, -13),
          Paint()
            ..color = const Color(0xFF8A6A40)
            ..strokeWidth = 2);
      final spark = 3 + sin(_t * 60) * 1.5;
      canvas.drawCircle(b + const Offset(9, -14), spark,
          Paint()..color = const Color(0xFFFFD45C));
      return;
    }
    final e = _t - bombFlight;
    final fade = min(1.0, (_burn - e) / .4);
    // Scorched ground with a glowing rim.
    canvas.drawOval(
        zone, Paint()..color = _a(const Color(0xFF3A2218), .55 * fade));
    canvas.drawOval(
        zone,
        Paint()
          ..color = _a(const Color(0xFFFF7A2A), .8 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // Flames dancing over the patch.
    for (var i = 0; i < 11; i++) {
      final a = i * 2.4;
      final r = i == 0 ? 0.0 : (.35 + (i % 3) * .2);
      final c = Offset(cos(a) * radius * r, sin(a) * radius * groundSquash * r);
      final h = (14 + 6 * sin(e * 13 + i)) * fade;
      _flame(canvas, c, h);
    }
    if (e < .35) {
      final k = e / .35;
      canvas.drawOval(
          zone.inflate(18 * k),
          Paint()
            ..color =
                Color.fromARGB((220 * (1 - k)).round(), 0xFF, 0xE0, 0x90));
      canvas.drawOval(
          zone.inflate(30 * k),
          Paint()
            ..color = Color.fromARGB((255 * (1 - k)).round(), 0xFF, 0xF4, 0xDA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
    }
  }

  static void _flame(Canvas canvas, Offset base, double h) {
    if (h <= 1) return;
    Path tongue(double w, double hh) => Path()
      ..moveTo(base.dx - w, base.dy)
      ..quadraticBezierTo(base.dx - w, base.dy - hh * .6, base.dx, base.dy - hh)
      ..quadraticBezierTo(base.dx + w, base.dy - hh * .6, base.dx + w, base.dy)
      ..close();
    canvas.drawPath(tongue(7, h), Paint()..color = const Color(0xDDF0582A));
    canvas.drawPath(
        tongue(4.5, h * .7), Paint()..color = const Color(0xEEFFB13A));
    canvas.drawPath(
        tongue(2.2, h * .4), Paint()..color = const Color(0xFFFFF2B0));
  }
}
