import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../cats/home_attack.dart';
import '../cats/cat_state.dart';
import '../constants.dart';
import 'return_home_obstacle.dart';

/// World-side effects of the Return Home secondary skills (see
/// [HomeAttack]). Every effect only knows how to move and how to look; the
/// game decides what it hits. Shapes drawn here use the same numbers the game
/// hits with, so what the player sees is what lands.

final double fireballRange = HomeAttack.fireball.range;
final double fireballRadius = HomeAttack.fireball.radius;
const double fireballSpeed = 520;
const double iceShardSpeed = 660;

final double boltRange = HomeAttack.bolt.range;
final double boltRadius = HomeAttack.bolt.radius;
const double boltDelay = .45;

final double roarRadius = HomeAttack.roar.radius;
const double roarPush = 400;

final double magnetRadius = HomeAttack.magnet.radius;
final double magnetDuration = HomeAttack.magnet.duration;
const double magnetPull = 380;

/// Fire breath and burning zones hurt in pulses this far apart.
const double fireTick = .2;

/// How long the fire bomb flies before it lands.
const double bombFlight = .45;

/// Speed of hazards inside the cat-eye aura.
const double catEyeSlow = .45;

/// Ground ellipses are flattened like the lane (2.5D view).
const double groundSquash = .6;

/// Ground-zone test shared by every flattened area effect.
bool inGroundEllipse(Vector2 p, Vector2 center, double radius,
    {double margin = 14}) {
  final dx = (p.x - center.x) / (radius + margin);
  final dy = (p.y - center.y) / (radius * groundSquash + margin);
  return dx * dx + dy * dy <= 1;
}

Rect groundEllipse(Vector2 center, double radius) => Rect.fromCenter(
    center: Offset(center.x, center.y),
    width: radius * 2,
    height: radius * 2 * groundSquash);

Color _a(Color c, double alpha) =>
    c.withAlpha((255 * alpha.clamp(0.0, 1.0)).round());

// ===========================================================================
// Projectiles: fireball and ice shard.
// ===========================================================================

/// A flying skill shot. The fireball bursts on the first hazard; the ice shard
/// pierces and freezes everything along its lane.
class ReturnHomeProjectile extends PositionComponent {
  ReturnHomeProjectile({
    required Vector2 position,
    required this.direction,
    required this.attack,
  }) : super(position: position, anchor: Anchor.center, priority: 7);

  final Vector2 direction;
  final HomeAttack attack;
  double travelled = 0;
  double _t = 0;
  final _trail = <Vector2>[];

  /// Hazards already hit; a piercing shard hits each one once.
  final hit = <ReturnHomeObstacle>{};

  bool get icy => attack == HomeAttack.iceShard;
  double get radius => attack.radius;
  bool get spent => travelled >= attack.range;

  Rect get hitRect =>
      Rect.fromCircle(center: Offset(position.x, position.y), radius: radius);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _trail.insert(0, position.clone());
    if (_trail.length > (icy ? 9 : 7)) _trail.removeLast();
    final step = (icy ? iceShardSpeed : fireballSpeed) * dt;
    position += direction * step;
    travelled += step;
  }

  @override
  void render(Canvas canvas) => icy ? _renderIce(canvas) : _renderFire(canvas);

  void _renderFire(Canvas canvas) {
    for (var i = 0; i < _trail.length; i++) {
      final p = _trail[i] - position;
      final k = 1 - i / _trail.length;
      canvas.drawCircle(Offset(p.x, p.y), radius * (.4 + .6 * k),
          Paint()..color = Color.fromARGB((120 * k).round(), 0xFF, 0x8A, 0x2A));
    }
    final flicker = 1 + sin(_t * 40) * .08;
    canvas.drawCircle(
        Offset.zero,
        radius * 1.7 * flicker,
        Paint()
          ..shader = const RadialGradient(colors: [
            Color(0x88FFB347),
            Color(0x00FF6A00),
          ]).createShader(
              Rect.fromCircle(center: Offset.zero, radius: radius * 1.7)));
    canvas.drawCircle(Offset.zero, radius * flicker,
        Paint()..color = const Color(0xFFFF6A2A));
    canvas.drawCircle(Offset(direction.x * 2, direction.y * 2 - 2), radius * .6,
        Paint()..color = const Color(0xFFFFD45C));
    canvas.drawCircle(Offset(direction.x * 3, direction.y * 3 - 3),
        radius * .28, Paint()..color = const Color(0xFFFFF6D8));
  }

  void _renderIce(Canvas canvas) {
    // Frost sparkles left behind.
    for (var i = 1; i < _trail.length; i++) {
      final p = _trail[i] - position;
      final k = 1 - i / _trail.length;
      final side = (i.isEven ? 1 : -1) * 5.0;
      final o = Offset(p.x - direction.y * side, p.y + direction.x * side);
      canvas.drawCircle(o, 2.5 * k + 1,
          Paint()..color = Color.fromARGB((200 * k).round(), 0xD8, 0xF4, 0xFF));
    }
    canvas.save();
    canvas.rotate(atan2(direction.y, direction.x));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 56, height: 26),
        Paint()..color = const Color(0x445FC8F0));
    final shard = Path()
      ..moveTo(22, 0)
      ..lineTo(6, -8)
      ..lineTo(-18, -5)
      ..lineTo(-24, 0)
      ..lineTo(-18, 5)
      ..lineTo(6, 8)
      ..close();
    canvas.drawPath(shard, Paint()..color = const Color(0xFFE8FAFF));
    canvas.drawPath(
        Path()
          ..moveTo(22, 0)
          ..lineTo(6, -8)
          ..lineTo(-18, -5)
          ..lineTo(-24, 0)
          ..close(),
        Paint()..color = const Color(0xFF9EDCF5));
    canvas.drawPath(
        shard,
        Paint()
          ..color = const Color(0xFF2E7FA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round);
    canvas.drawLine(
        const Offset(6, -7),
        const Offset(6, 7),
        Paint()
          ..color = const Color(0xAA2E7FA8)
          ..strokeWidth = 1.2);
    canvas.restore();
  }
}

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
class ReturnHomeFlameBreath extends PositionComponent {
  ReturnHomeFlameBreath({required Vector2 position, required this.direction})
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
class ReturnHomeFireBomb extends PositionComponent {
  ReturnHomeFireBomb({required Vector2 from, required this.target})
      : _from = from.clone(),
        super(position: target.clone(), anchor: Anchor.center, priority: 7);

  final Vector2 _from;
  final Vector2 target;
  double _t = 0;
  bool explodeNow = false;
  bool tickNow = false;

  double get radius => HomeAttack.fireBomb.radius;
  double get _burn => HomeAttack.fireBomb.duration;
  bool get landed => _t >= bombFlight;
  bool covers(Vector2 p) => inGroundEllipse(p, target, radius);

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

// ===========================================================================
// Shadow: blink, decoy, time stop.
// ===========================================================================

/// Smoke where the cat left and where it arrived, joined by a fading trail.
class ReturnHomeShadowStep extends PositionComponent {
  ReturnHomeShadowStep({required Vector2 from, required Vector2 to})
      : _to = to - from,
        super(position: from.clone(), anchor: Anchor.center, priority: 7);

  final Vector2 _to;
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
    final trail = Paint()
      ..color = _a(const Color(0xFF7B5FC4), .55 * fade)
      ..strokeWidth = 10 * fade + 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(_to.x, _to.y), trail);
    for (final end in [Offset.zero, Offset(_to.x, _to.y)]) {
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3 + k * 2;
        final r = 8 + 22 * k;
        canvas.drawCircle(
            end + Offset(cos(a) * r, sin(a) * r * .6 - 12),
            9 * fade + 3,
            Paint()..color = _a(const Color(0xFF3A2A6A), .7 * fade));
      }
      canvas.drawOval(
          Rect.fromCenter(
              center: end + const Offset(0, 6),
              width: 46 * (1 - k * .5),
              height: 14),
          Paint()..color = _a(const Color(0xFF1E1438), .6 * fade));
    }
  }
}

/// A ghostly copy of the cat that lures birds. When it fades it bursts and
/// shoves nearby hazards away ([HomeAttack.decoy] radius).
class ReturnHomeDecoy extends SpriteAnimationGroupComponent<CatState> {
  ReturnHomeDecoy({
    required Map<CatState, SpriteAnimation> animations,
    required Vector2 center,
    required this.flip,
  }) : super(
          animations: animations,
          current: CatState.idle,
          size: Vector2(catWidth, catHeight),
          position: center - Vector2(catWidth / 2, 52),
          priority: 5,
        ) {
    paint = Paint()
      ..colorFilter =
          const ColorFilter.mode(Color(0x887B5FC4), BlendMode.srcATop)
      ..color = const Color(0xBBFFFFFF);
  }

  final bool flip;
  double timeLeft = HomeAttack.decoy.duration;
  double _t = 0;

  /// Where birds aim: the middle of its paws, like the real cat's hitbox.
  Vector2 get lureCenter => position + Vector2(catWidth / 2, 52);
  bool get expired => timeLeft <= 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    timeLeft -= dt;
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, 56);
    // Lure rings pulsing out of the ground.
    for (var i = 0; i < 2; i++) {
      final k = ((_t * .9 + i * .5) % 1);
      canvas.drawOval(
          Rect.fromCenter(
              center: c,
              width: 30 + 90 * k,
              height: (30 + 90 * k) * groundSquash),
          Paint()
            ..color = _a(const Color(0xFFB9A2FF), .7 * (1 - k))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    canvas.drawOval(Rect.fromCenter(center: c, width: 40, height: 12),
        Paint()..color = const Color(0x553A2A6A));
    if (timeLeft < 1 && (timeLeft * 10).floor().isEven) return;
    canvas.save();
    if (flip) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    super.render(canvas);
    canvas.restore();
    // Wisps of shadow rising off it.
    for (var i = 0; i < 3; i++) {
      final k = (_t * .8 + i / 3) % 1;
      canvas.drawCircle(
          Offset(size.x / 2 + sin(_t * 3 + i * 2) * 14, 60 - 50 * k),
          5 * (1 - k) + 1,
          Paint()..color = _a(const Color(0xFF5B4A9E), .6 * (1 - k)));
    }
  }
}

/// The clock ring that sweeps out from the cat when time stops, then a small
/// clock above its head counting down while hazards stand still.
class ReturnHomeTimeStopAura extends Component {
  ReturnHomeTimeStopAura() : super(priority: 8);

  Vector2 center = Vector2.zero();
  double timeLeft = 0;
  double _since = 99;

  void start() => _since = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _since += dt;
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(center.x, center.y);
    if (_since < .6) {
      final k = _since / .6;
      final r = 40 + 700 * (1 - (1 - k) * (1 - k));
      final ring = Paint()
        ..color = _a(const Color(0xFFCFE6FF), 1 - k)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawCircle(c, r, ring);
      for (var i = 0; i < 12; i++) {
        final a = i * pi / 6;
        canvas.drawLine(c + Offset(cos(a), sin(a)) * (r - 14),
            c + Offset(cos(a), sin(a)) * r, ring..strokeWidth = 3);
      }
    }
    if (timeLeft <= 0) return;
    if (timeLeft < .8 && (timeLeft * 10).floor().isEven) return;
    final m = c + const Offset(0, -62);
    canvas.drawCircle(m, 13, Paint()..color = const Color(0xFFF2F7FF));
    canvas.drawCircle(
        m,
        13,
        Paint()
          ..color = const Color(0xFF3D6FA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final share = timeLeft / HomeAttack.timeStop.duration;
    canvas.drawArc(Rect.fromCircle(center: m, radius: 9), -pi / 2,
        pi * 2 * share, true, Paint()..color = const Color(0x993D6FA8));
    canvas.drawLine(
        m,
        m + const Offset(0, -8),
        Paint()
          ..color = const Color(0xFF1F3A5C)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }
}

/// Screen tint while time is stopped; drawn by the game over the world.
void paintTimeStopTint(Canvas canvas, Size size, double timeLeft) {
  if (timeLeft <= 0) return;
  final fadeIn = min(1.0, (HomeAttack.timeStop.duration - timeLeft) / .2);
  final fadeOut = min(1.0, timeLeft / .3);
  final k = min(fadeIn, fadeOut);
  final rect = Offset.zero & size;
  canvas.drawRect(rect, Paint()..color = _a(const Color(0xFF6C8FC0), .22 * k));
  canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0x00000000),
          _a(const Color(0xFF1F3A5C), .45 * k),
        ], stops: const [
          .55,
          1
        ]).createShader(rect));
}

// ===========================================================================
// Ice: frozen hazards, frost nova, ice bridge.
// ===========================================================================

/// Ice block drawn over a frozen hazard (call with the canvas at its center).
void paintIceBlock(Canvas canvas, double timeLeft,
    {double width = 46, double height = 40}) {
  if (timeLeft < .6 && (timeLeft * 12).floor().isEven) return;
  final block = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: const Offset(0, -2), width: width, height: height),
      const Radius.circular(8));
  canvas.drawRRect(block, Paint()..color = const Color(0xA6C4ECFF));
  canvas.drawRRect(
      block,
      Paint()
        ..color = const Color(0xFF4E9CC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5);
  canvas.drawRRect(
      block.deflate(2),
      Paint()
        ..color = const Color(0xFFF0FBFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  final shine = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(-width / 2 + 7, -height / 2 + 8),
      Offset(-width / 2 + 15, -height / 2 + 4), shine);
  canvas.drawLine(Offset(width / 2 - 9, height / 2 - 10),
      Offset(width / 2 - 5, height / 2 - 16), shine..strokeWidth = 1.8);
}

/// Ring of ice spikes bursting out to [HomeAttack.frostNova] radius.
class ReturnHomeFrostWave extends PositionComponent {
  ReturnHomeFrostWave({required Vector2 position})
      : super(position: position, anchor: Anchor.center, priority: 3);

  double _t = 0;
  static const double _life = .8;
  double get radius => HomeAttack.frostNova.radius;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final grow = min(1.0, _t / .3);
    final ease = 1 - (1 - grow) * (1 - grow);
    final fade = 1 - (_t / _life);
    final r = radius * ease;
    final ground = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawOval(
        ground, Paint()..color = _a(const Color(0xFFCFF0FF), .35 * fade));
    canvas.drawOval(
        ground,
        Paint()
          ..color = _a(const Color(0xFFFFFFFF), .9 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // Crystals around the ring.
    for (var i = 0; i < 14; i++) {
      final a = i * pi * 2 / 14;
      final p = Offset(cos(a) * r, sin(a) * r);
      final h = (16 + (i % 3) * 6) * ease;
      final spike = Path()
        ..moveTo(p.dx - 5, p.dy)
        ..lineTo(p.dx, p.dy - h)
        ..lineTo(p.dx + 5, p.dy)
        ..close();
      canvas.drawPath(
          spike, Paint()..color = _a(const Color(0xFFE8FAFF), fade));
      canvas.drawPath(
          spike,
          Paint()
            ..color = _a(const Color(0xFF3FA6D6), fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
    // Snowflake flash in the middle.
    if (_t < .35) {
      final k = 1 - _t / .35;
      final flake = Paint()
        ..color = _a(const Color(0xFFFFFFFF), k)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3;
        canvas.drawLine(Offset.zero, Offset(cos(a), sin(a)) * 30, flake);
      }
    }
  }
}

/// A strip of ice laid from the cat along the aim: water under it is dry
/// ground until it melts.
class ReturnHomeIceBridge extends PositionComponent {
  ReturnHomeIceBridge({required Vector2 origin, required Vector2 direction})
      : _dir = direction.normalized(),
        super(position: origin.clone(), priority: 2);

  final Vector2 _dir;
  double _t = 0;

  /// The game freezes hazards under the ice once, when it is fully laid.
  bool frozeHazards = false;
  bool get built => _t >= .25;

  double get length => HomeAttack.iceBridge.range;
  double get halfWidth => HomeAttack.iceBridge.radius;
  double get _life => HomeAttack.iceBridge.duration;
  double get _built => length * min(1.0, _t / .25);

  /// Whether [p] stands on the ice.
  bool covers(Offset p) {
    final d = Vector2(p.dx, p.dy) - position;
    final along = d.dot(_dir);
    final across = d.x * -_dir.y + d.y * _dir.x;
    return along >= -halfWidth * .5 &&
        along <= _built + halfWidth * .5 &&
        across.abs() <= halfWidth;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final left = _life - _t;
    if (left < 1 && (left * 10).floor().isEven) return;
    canvas.save();
    canvas.rotate(atan2(_dir.y, _dir.x));
    final slab = RRect.fromRectAndRadius(
        Rect.fromLTRB(
            -halfWidth * .5, -halfWidth, _built + halfWidth * .5, halfWidth),
        Radius.circular(halfWidth * .6));
    canvas.drawRRect(slab.shift(const Offset(0, 4)),
        Paint()..color = const Color(0x33204050));
    canvas.drawRRect(slab, Paint()..color = const Color(0xE0D4F2FF));
    canvas.drawRRect(
        slab,
        Paint()
          ..color = const Color(0xFF7CC6EA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    // Plank joints and frosty highlights.
    final joint = Paint()
      ..color = const Color(0xAA8FCDEB)
      ..strokeWidth = 2;
    for (var x = 26.0; x < _built; x += 30) {
      canvas.drawLine(
          Offset(x, -halfWidth + 4), Offset(x - 4, halfWidth - 4), joint);
    }
    final shine = Paint()
      ..color = const Color(0xDDFFFFFF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var x = 8.0; x < _built - 10; x += 60) {
      canvas.drawLine(
          Offset(x, -halfWidth + 7), Offset(x + 16, -halfWidth + 7), shine);
    }
    // Cracks spread as it starts melting.
    if (left < 2) {
      final crack = Paint()
        ..color = const Color(0xCC4E9CC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final k = 1 - left / 2;
      for (var x = 40.0; x < _built; x += 70) {
        canvas.drawPath(
            Path()
              ..moveTo(x, -halfWidth * k)
              ..lineTo(x + 8, -4)
              ..lineTo(x - 4, 6)
              ..lineTo(x + 6, halfWidth * k),
            crack);
      }
    }
    canvas.restore();
  }
}

// ===========================================================================
// Earth: stone wall and reflect aura.
// ===========================================================================

/// A short wall of boulders standing across the aim direction for
/// [HomeAttack.stoneWall] duration. Rocks bounce off it, crabs turn back and
/// diving birds are scared away. The cat is not blocked by its own wall.
class ReturnHomeStoneWall extends PositionComponent {
  ReturnHomeStoneWall({required Vector2 center, required Vector2 facing})
      : _n = facing.normalized(),
        super(position: center.clone(), priority: 4);

  /// Aim direction (wall normal) and the wall's own axis.
  final Vector2 _n;
  Vector2 get _u => Vector2(-_n.y, _n.x);
  double _t = 0;

  double get length => HomeAttack.stoneWall.radius;
  static const double thickness = 22;
  bool get standing => _t < HomeAttack.stoneWall.duration;

  /// Closest point of the wall footprint to [p].
  Vector2 closest(Vector2 p) {
    final d = p - position;
    final along = d.dot(_u).clamp(-length / 2, length / 2).toDouble();
    final across = d.dot(_n).clamp(-thickness / 2, thickness / 2).toDouble();
    return position + _u * along + _n * across;
  }

  /// Footprint corners, for the aim preview and the drawing.
  static List<Offset> footprint(Vector2 c, Vector2 n, double length) {
    final u = Vector2(-n.y, n.x);
    final a = u * (length / 2), b = n * (thickness / 2);
    return [c + a + b, c + a - b, c - a - b, c - a + b]
        .map((v) => Offset(v.x, v.y))
        .toList();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > HomeAttack.stoneWall.duration + .3) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final life = HomeAttack.stoneWall.duration;
    // Rises out of the ground, sinks back at the end.
    final rise = _t < .2
        ? _t / .2
        : _t > life
            ? max(0.0, 1 - (_t - life) / .3)
            : 1.0;
    final u = _u;
    const count = 5;
    final blocks = [
      for (var i = 0; i < count; i++)
        u * ((i - (count - 1) / 2) * length / count),
    ]..sort((a, b) => a.y.compareTo(b.y));
    final height = 26 * rise;
    for (final b in blocks) {
      final base = Offset(b.x, b.y);
      canvas.drawOval(
          Rect.fromCenter(
              center: base + const Offset(0, 4), width: 30, height: 12),
          Paint()..color = const Color(0x44000000));
    }
    for (var i = 0; i < blocks.length; i++) {
      final base = Offset(blocks[i].x, blocks[i].y);
      final w = 26.0 + (i % 2) * 4;
      final body = RRect.fromRectAndRadius(
          Rect.fromLTRB(base.dx - w / 2, base.dy - height - 8, base.dx + w / 2,
              base.dy + 4),
          const Radius.circular(9));
      canvas.drawRRect(body, Paint()..color = const Color(0xFF8E7C68));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(
                  body.left + 3, body.top + 2, body.right - 3, body.top + 12),
              const Radius.circular(6)),
          Paint()..color = const Color(0xFFB4A28C));
      canvas.drawRRect(
          body,
          Paint()
            ..color = const Color(0xFF4A3C30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawLine(
          Offset(base.dx - 6, base.dy - height * .4),
          Offset(base.dx + 2, base.dy - height * .3),
          Paint()
            ..color = const Color(0xFF6E5E4E)
            ..strokeWidth = 1.6);
    }
    // Dust while rising.
    if (_t < .4) {
      final k = _t / .4;
      for (var i = 0; i < 6; i++) {
        final side = (i - 2.5) / 2.5;
        final p = u * (side * length / 2);
        canvas.drawCircle(Offset(p.x, p.y + 4), 6 + 10 * k,
            Paint()..color = _a(const Color(0xFFD8C8A4), .6 * (1 - k)));
      }
    }
  }
}

/// Mirror shards circling the cat while [HomeAttack.reflect] is up.
class ReturnHomeReflectAura extends Component {
  ReturnHomeReflectAura() : super(priority: 6);

  Vector2 center = Vector2.zero();
  double timeLeft = 0;
  double _t = 0;
  double _flash = 0;

  void flash() => _flash = .25;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _flash = max(0, _flash - dt);
  }

  @override
  void render(Canvas canvas) {
    if (timeLeft <= 0) return;
    if (timeLeft < .8 && (timeLeft * 10).floor().isEven) return;
    final r = HomeAttack.reflect.radius;
    final c = Offset(center.x, center.y - 6);
    final ring = Rect.fromCenter(center: c, width: r * 2, height: r * 2 * .8);
    canvas.drawOval(
        ring, Paint()..color = _a(const Color(0xFF7FE0CF), .12 + _flash * 1.6));
    canvas.drawOval(
        ring,
        Paint()
          ..color = const Color(0x997FE0CF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var i = 0; i < 3; i++) {
      final a = _t * 3 + i * pi * 2 / 3;
      final p = c + Offset(cos(a) * r, sin(a) * r * .8);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + pi / 2);
      final shard = Path()
        ..moveTo(0, -11)
        ..lineTo(6, 0)
        ..lineTo(0, 11)
        ..lineTo(-6, 0)
        ..close();
      canvas.drawPath(shard, Paint()..color = const Color(0xFFE6FFFA));
      canvas.drawPath(
          shard,
          Paint()
            ..color = const Color(0xFF2E8A7C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
      canvas.drawLine(
          const Offset(-1, -6),
          const Offset(2, 2),
          Paint()
            ..color = const Color(0xFF8FD8CC)
            ..strokeWidth = 1.5);
      canvas.restore();
    }
  }
}

// ===========================================================================
// Cat eye: slow aura that also reveals hidden springs.
// ===========================================================================

class ReturnHomeCatEyeAura extends Component {
  ReturnHomeCatEyeAura({required this.obstacles}) : super(priority: 6);

  final List<ReturnHomeObstacle> obstacles;
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
      if (o.kind != ReturnHomeObstacleKind.spring || o.springT > 0) continue;
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
class ReturnHomeBolt extends PositionComponent {
  ReturnHomeBolt({required Vector2 position, required this.seed})
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
class ReturnHomeBurst extends PositionComponent {
  ReturnHomeBurst({
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

// ===========================================================================
// Aim preview.
// ===========================================================================

/// World-space preview while a skill button is held, MOBA style: the big
/// range ring around the cat plus the exact shape the skill will hit. Turns
/// red when the cast would be wasted (e.g. blinking into water).
class ReturnHomeAimIndicator extends Component {
  ReturnHomeAimIndicator() : super(priority: 9);

  HomeAttack? attack;

  /// Cat center (range ring, self skills) and mouth (skill shots).
  Vector2 origin = Vector2.zero();
  Vector2 castFrom = Vector2.zero();
  Vector2 direction = Vector2(1, 0);
  Vector2 target = Vector2.zero();
  bool valid = true;

  /// Visible world rect, for screen-wide skills.
  Rect view = Rect.zero;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final attack = this.attack;
    if (attack == null) return;
    final color = valid ? attack.color : const Color(0xFFE0483F);
    final fill = Paint()..color = _a(color, .3);
    final edge = Paint()
      ..color = _a(Color.lerp(color, const Color(0xFFFFFFFF), .55)!, .95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final o = Offset(origin.x, origin.y);
    if (attack.shape != AimShape.self && attack.shape != AimShape.global) {
      _rangeRing(canvas, o, attack.range);
    }
    switch (attack.shape) {
      case AimShape.line:
        final from = attack == HomeAttack.iceBridge ? origin : castFrom;
        final angle = atan2(direction.y, direction.x);
        canvas.save();
        canvas.translate(from.x, from.y);
        canvas.rotate(angle);
        final w = attack.radius;
        final lane = RRect.fromRectAndRadius(
            Rect.fromLTRB(0, -w, attack.range, w), Radius.circular(min(w, 10)));
        canvas.drawRRect(lane, fill);
        canvas.drawRRect(lane, edge);
        // Chevrons running along the lane.
        final chevron = Paint()
          ..color = _a(const Color(0xFFFFFFFF), .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        const step = 46.0;
        final shift = (_t * 90) % step;
        final h = min(w * .7, 9.0);
        for (var x = shift + 14; x < attack.range - 20; x += step) {
          canvas.drawPath(
              Path()
                ..moveTo(x - h * .7, -h)
                ..lineTo(x, 0)
                ..lineTo(x - h * .7, h),
              chevron);
        }
        // Arrow head at the end.
        final head = Path()
          ..moveTo(attack.range + 10, 0)
          ..lineTo(attack.range - 10, -w - 6)
          ..lineTo(attack.range - 10, w + 6)
          ..close();
        canvas.drawPath(head, Paint()..color = _a(color, .9));
        canvas.restore();
      case AimShape.cone:
        final angle = atan2(direction.y, direction.x);
        final rect = Rect.fromCircle(
            center: Offset(castFrom.x, castFrom.y), radius: attack.range);
        final cone = Path()
          ..moveTo(castFrom.x, castFrom.y)
          ..arcTo(rect, angle - attack.radius, attack.radius * 2, false)
          ..close();
        canvas.drawPath(cone, fill);
        canvas.drawPath(cone, edge);
        // Sweep line showing reach.
        final k = (_t * 1.4) % 1;
        canvas.drawArc(
            Rect.fromCircle(
                center: Offset(castFrom.x, castFrom.y),
                radius: attack.range * k),
            angle - attack.radius,
            attack.radius * 2,
            false,
            Paint()
              ..color = _a(const Color(0xFFFFFFFF), .6 * (1 - k))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case AimShape.area:
        final zone = groundEllipse(target, attack.radius);
        canvas.drawOval(zone, fill);
        canvas.drawOval(zone, edge);
        final pulse = (_t * 1.5) % 1;
        canvas.drawOval(
            groundEllipse(target, attack.radius * pulse),
            Paint()
              ..color = _a(const Color(0xFFFFFFFF), .5 * (1 - pulse))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        _crosshair(canvas, Offset(target.x, target.y), color);
        if (attack == HomeAttack.decoy) {
          // Where the copy will stand.
          final t = Offset(target.x, target.y);
          canvas.drawOval(Rect.fromCenter(center: t, width: 30, height: 12),
              Paint()..color = _a(color, .6));
          canvas.drawCircle(t + const Offset(0, -20), 12, edge);
          canvas.drawPath(
              Path()
                ..moveTo(t.dx - 10, t.dy - 26)
                ..lineTo(t.dx - 8, t.dy - 38)
                ..lineTo(t.dx - 2, t.dy - 31)
                ..moveTo(t.dx + 10, t.dy - 26)
                ..lineTo(t.dx + 8, t.dy - 38)
                ..lineTo(t.dx + 2, t.dy - 31),
              edge);
        }
      case AimShape.wall:
        final corners =
            ReturnHomeStoneWall.footprint(target, direction, attack.radius);
        final wall = Path()..addPolygon(corners, true);
        canvas.drawPath(wall, Paint()..color = _a(color, .55));
        canvas.drawPath(wall, edge);
        // Arrow showing which way the wall faces.
        final t = Offset(target.x, target.y);
        final d = Offset(direction.x, direction.y);
        canvas.drawLine(
            o,
            t - d * 16,
            Paint()
              ..color = _a(const Color(0xFFFFFFFF), .5)
              ..strokeWidth = 2);
      case AimShape.blink:
        final t = Offset(target.x, target.y);
        final dash = Paint()
          ..color = _a(const Color(0xFFFFFFFF), .8)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        final d = t - o;
        final length = d.distance;
        if (length > 1) {
          final dir = d / length;
          for (var x = (_t * 60) % 18; x < length - 18; x += 18) {
            canvas.drawLine(o + dir * x, o + dir * min(x + 8, length), dash);
          }
        }
        canvas.drawOval(
            Rect.fromCenter(
                center: t,
                width: attack.radius * 2.4,
                height: attack.radius * 1.2),
            fill);
        canvas.drawOval(
            Rect.fromCenter(
                center: t,
                width: attack.radius * 2.4,
                height: attack.radius * 1.2),
            edge);
        _crosshair(canvas, t, color);
        if (!valid) {
          final x = Paint()
            ..color = const Color(0xFFFFFFFF)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
              t + const Offset(-8, -30), t + const Offset(8, -14), x);
          canvas.drawLine(
              t + const Offset(8, -30), t + const Offset(-8, -14), x);
        }
      case AimShape.self:
        final pulse = 1 + sin(_t * 6) * .02;
        canvas.drawCircle(o, attack.radius * pulse, fill);
        canvas.drawCircle(o, attack.radius * pulse, edge);
      case AimShape.global:
        canvas.drawRect(view, Paint()..color = _a(color, .16));
        canvas.drawRect(
            view.deflate(4),
            Paint()
              ..color = _a(color, .8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6);
        canvas.drawCircle(o, 46, edge);
        for (var i = 0; i < 12; i++) {
          final a = i * pi / 6;
          canvas.drawLine(o + Offset(cos(a), sin(a)) * 38,
              o + Offset(cos(a), sin(a)) * 46, edge);
        }
        final hand = _t * 2;
        canvas.drawLine(o, o + Offset(cos(hand), sin(hand)) * 32, edge);
    }
  }

  void _rangeRing(Canvas canvas, Offset c, double range) {
    canvas.drawCircle(c, range, Paint()..color = const Color(0x1AFFFFFF));
    canvas.drawCircle(
        c,
        range,
        Paint()
          ..color = const Color(0x99E8F6FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }

  void _crosshair(Canvas canvas, Offset c, Color color) {
    canvas.drawCircle(c, 5, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(
        c,
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
}

/// Expanding sound rings from the cat; the outer ring reaches [roarRadius]
/// at the same moment the push lands, so the shown area is the real one.
class ReturnHomeRoarWave extends PositionComponent {
  ReturnHomeRoarWave({required Vector2 position})
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
class ReturnHomeMagnetAura extends Component {
  ReturnHomeMagnetAura() : super(priority: 4);

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
