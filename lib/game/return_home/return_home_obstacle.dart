import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'return_home_hazard_art.dart';
import 'return_home_road.dart';
import 'return_home_skills.dart';

enum ReturnHomeObstacleKind { spikes, rock, log, bird, spring, crab }

/// How long a crab rests at a lane edge, snapping its claws, before turning.
const double crabPause = .55;

/// A log spans [logLength] across the lane and only stands upright when at least
/// [logMinGap] of lane stays free, so a blocked lane is never a wall.
const double logLength = 66.0;
const double logReach = 33.0;
const double logHalfThickness = 11.0;
const double logMinGap = 34.0;

/// Clearance hazards keep from the lane edge, and the altitude/sweep numbers a
/// diving bird flies by.
const double laneHazardClearance = 14.0;
const double rockSpawnClearance = 20.0;
const double birdCruiseHeight = .16;
const double birdDiveDuration = .9;

/// A bird ahead of the cat by less than [birdAimRange] stops to aim: it hovers
/// and its shadow trails the cat for a random [birdAimMin]..+[birdAimJitter]
/// seconds, then the target freezes and it dives onto that spot. The aim delay
/// plus half the dive is the player's window to step out of the shadow.
const double birdAimRange = 260.0;
const double birdAimMin = .4;
const double birdAimJitter = .35;
const double birdAimSlowdown = .25;
const double birdShadowFollow = 6.0;

final Random _birdRandom = Random();

enum _BirdPhase { cruise, aim, dive, leave }

/// Rock physics: the road slopes gently toward the start, so rocks keep rolling
/// left; collisions lose some energy; spin follows the rolling speed.
/// A spring hides in the grass; how long it stays popped up after firing.
const double springShowTime = 1.2;

const double rockRadius = 18.0;
const double rockSlope = 70.0;
const double rockMaxSpeed = 280.0;
const double rockRestitution = .75;
const double wallRestitution = .55;

/// One hazard on the road: how it moves, what its visible shape is and which
/// rect counts as a hit. Placement is the spawner's business.
class ReturnHomeObstacle extends PositionComponent {
  ReturnHomeObstacle({
    required this.kind,
    required this.road,
    required Vector2 position,
  }) : super(position: position, size: Vector2.all(54), anchor: Anchor.center);

  final ReturnHomeObstacleKind kind;
  final ReturnHomeRoad road;
  Vector2 velocity = Vector2.zero();
  double angularVelocity = 0;
  bool vertical = false;

  /// Fireball hits taken; a log breaks on the second one.
  int damage = 0;

  /// A bird scared off by a roar flies away and can no longer hit.
  bool harmless = false;

  /// Seconds left encased in ice: a frozen hazard stands still and cannot
  /// hurt the cat (a frozen log is still a wall). The game counts it down.
  double frozen = 0;

  /// Roar shockwave from [from]: rocks are blown away, crabs scuttle off,
  /// birds abort their dive. Spikes, logs and springs are fixed in the ground.
  void scare(Vector2 from, double push) {
    switch (kind) {
      case ReturnHomeObstacleKind.rock:
        final away = position - from;
        if (away.length2 == 0) away.setValues(1, 0);
        velocity = away.normalized() * push;
      case ReturnHomeObstacleKind.crab:
        final side = position.y >= from.y ? 1.0 : -1.0;
        velocity.y = side * velocity.y.abs();
        springT = 0;
        position.y += side * 28;
      case ReturnHomeObstacleKind.bird:
        _phase = _BirdPhase.leave;
        harmless = true;
      case ReturnHomeObstacleKind.spikes:
      case ReturnHomeObstacleKind.log:
      case ReturnHomeObstacleKind.spring:
        break;
    }
  }

  /// Seconds left in the popped-up pose; 0 means armed and hidden.
  double springT = 0;

  double _flap = 0;
  double _tilt = 0;
  double _shadowDx = 0;
  double _shadowDy = 0;
  double _shadowDepth = 0;

  _BirdPhase _phase = _BirdPhase.cruise;
  double _phaseT = 0;
  double _aimTime = 0;
  final Vector2 _target = Vector2.zero();
  final Vector2 _diveStart = Vector2.zero();
  double _diveVx = 0;

  /// [cat] is the center of the cat's hitbox in world space.
  void updatePhysics(double dt, Offset cat) {
    if (frozen > 0 || dt <= 0) return;
    if (kind == ReturnHomeObstacleKind.spring) {
      springT = max(0, springT - dt);
      return;
    }
    if (kind == ReturnHomeObstacleKind.bird) {
      _updateBird(dt, cat);
      return;
    }
    if (kind == ReturnHomeObstacleKind.crab) {
      _updateCrab(dt);
      return;
    }
    if (kind != ReturnHomeObstacleKind.rock) return;
    velocity.x -= rockSlope * dt;
    if (velocity.length > rockMaxSpeed) velocity.scaleTo(rockMaxSpeed);
    position += velocity * dt;
    angularVelocity = velocity.x / rockRadius;
    angle += angularVelocity * dt;
    // Rolling rocks bounce off the curving lane edges instead of fixed bands.
    final reach = road.halfWidth(position.x) - laneHazardClearance;
    final center = road.centerY(position.x);
    final top = center - reach;
    final bottom = center + reach;
    if (position.y < top) {
      position.y = top;
      velocity.y = velocity.y.abs();
    } else if (position.y > bottom) {
      position.y = bottom;
      velocity.y = -velocity.y.abs();
    }
  }

  /// Cruises high, then aims at the cat: it hovers while its shadow chases
  /// the player with a little lag, locks the spot after a random delay and
  /// swoops onto it. Dodging means leaving the shadow before the strike lands.
  void _updateBird(double dt, Offset cat) {
    final cruise = road.viewportHeight * birdCruiseHeight;
    _phaseT += dt;
    switch (_phase) {
      case _BirdPhase.cruise:
      case _BirdPhase.leave:
        _flap += dt * 13;
        position += velocity * dt;
        // Eases back up after a dive or a scare instead of snapping.
        position.y += (cruise - position.y) * min(1.0, dt * 8);
        _tilt = 0;
        _shadowDepth = 0;
        _shadowDx = 0;
        _shadowDy = road.centerY(position.x) +
            road.halfWidth(position.x) * .55 -
            cruise;
        final ahead = position.x - cat.dx;
        if (_phase == _BirdPhase.cruise && ahead > 0 && ahead < birdAimRange) {
          _phase = _BirdPhase.aim;
          _phaseT = 0;
          _aimTime = birdAimMin + _birdRandom.nextDouble() * birdAimJitter;
          // The shadow starts under the bird and slides toward the cat.
          _target.setValues(position.x, position.y + _shadowDy);
        }
      case _BirdPhase.aim:
        // Hover in place, flapping hard, shadow homing in on the cat.
        _flap += dt * 22;
        position.x += velocity.x * birdAimSlowdown * dt;
        position.y = cruise - sin(_phaseT * 14) * 3;
        final k = 1 - exp(-birdShadowFollow * dt);
        _target.x += (cat.dx - _target.x) * k;
        _target.y += (cat.dy - _target.y) * k;
        final progress = min(1.0, _phaseT / _aimTime);
        _tilt = -.25 * progress;
        _shadowDepth = .3 + .4 * progress;
        _setShadowToTarget();
        if (_phaseT >= _aimTime) {
          // Lock: from here the strike point no longer follows the cat.
          _phase = _BirdPhase.dive;
          _phaseT = 0;
          _diveStart.setFrom(position);
          _diveVx = (_target.x - position.x) / (birdDiveDuration / 2);
        }
      case _BirdPhase.dive:
        _flap += dt * 8;
        final t = min(1.0, _phaseT / birdDiveDuration);
        final dip = sin(pi * t);
        position.x = _diveStart.x + _diveVx * _phaseT;
        position.y = cruise + (_target.y - cruise) * dip;
        _tilt = (t < .5 ? -.55 : .42) * min(1, dip * 2.5);
        _shadowDepth = .7 + .3 * dip;
        _setShadowToTarget();
        if (t >= 1) {
          _phase = _BirdPhase.leave;
          _phaseT = 0;
        }
    }
  }

  /// Sideways shuffle from one lane edge to the other, resting at each edge.
  void _updateCrab(double dt) {
    _flap += dt * (springT > 0 ? 18 : 12);
    if (springT > 0) {
      springT = max(0, springT - dt);
      return;
    }
    position.y += velocity.y * dt;
    final reach = road.halfWidth(position.x) - laneHazardClearance;
    final center = road.centerY(position.x);
    if (position.y < center - reach || position.y > center + reach) {
      position.y = position.y.clamp(center - reach, center + reach);
      velocity.y = -velocity.y;
      springT = crabPause;
    }
  }

  void _setShadowToTarget() {
    _shadowDx = _target.x - position.x;
    _shadowDy = _target.y + 10 - position.y;
  }

  /// Solid footprint used when hazards collide with each other.
  Rect get solidRect => kind == ReturnHomeObstacleKind.log
      ? (vertical
          ? Rect.fromCenter(
              center: Offset(position.x - 1, position.y - 3),
              width: 22,
              height: logLength)
          : Rect.fromCenter(
              center: Offset(position.x - 3, position.y + 1),
              width: logLength,
              height: 22))
      : Rect.fromCenter(
          center: Offset(position.x + 1, position.y + 1),
          width: 34,
          height: 20);

  bool hits(Rect catBox) {
    if (kind == ReturnHomeObstacleKind.spring) {
      return catBox.overlaps(Rect.fromCenter(
          center: Offset(position.x, position.y), width: 26, height: 14));
    }
    if (kind == ReturnHomeObstacleKind.spikes) {
      return catBox.overlaps(Rect.fromCenter(
          center: Offset(position.x + 1, position.y + 1),
          width: 34,
          height: 20));
    }
    if (kind == ReturnHomeObstacleKind.log) {
      // Trunk plus its rounded end cap, in whichever orientation it is drawn.
      return catBox.overlaps(vertical
          ? Rect.fromCenter(
              center: Offset(position.x - 1, position.y - 3),
              width: 22,
              height: logLength)
          : Rect.fromCenter(
              center: Offset(position.x - 3, position.y + 1),
              width: logLength,
              height: 22));
    }
    if (kind == ReturnHomeObstacleKind.crab) {
      return catBox.overlaps(Rect.fromCenter(
          center: Offset(position.x, position.y + 1), width: 34, height: 16));
    }
    if (kind == ReturnHomeObstacleKind.bird) {
      if (harmless) return false;
      // Body and head only; grazing a flapping wingtip stays a near miss.
      return catBox.overlaps(Rect.fromCenter(
          center: Offset(position.x, position.y), width: 28, height: 16));
    }
    final closestX =
        catBox.center.dx.clamp(position.x - 18, position.x + 18).toDouble();
    final closestY =
        catBox.center.dy.clamp(position.y - 18, position.y + 18).toDouble();
    return (Offset(closestX, closestY) - Offset(position.x, position.y))
            .distance <
        18;
  }

  @override
  void render(Canvas canvas) {
    // The painters below draw around their own center, but Flame puts the
    // canvas origin at the top-left of the bounding box when anchor is center.
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    switch (kind) {
      case ReturnHomeObstacleKind.spikes:
        paintSpikes(canvas);
      case ReturnHomeObstacleKind.rock:
        paintRock(canvas, angle);
      case ReturnHomeObstacleKind.bird:
        paintBird(canvas,
            flap: _flap,
            tilt: _tilt,
            shadowDx: _shadowDx,
            shadowDy: _shadowDy,
            shadowDepth: _shadowDepth);
      case ReturnHomeObstacleKind.log:
        paintLog(canvas, vertical: vertical);
        if (damage > 0) _paintScorch(canvas);
      case ReturnHomeObstacleKind.spring:
        _paintSpring(canvas);
      case ReturnHomeObstacleKind.crab:
        paintCrab(canvas, walk: _flap, resting: springT > 0);
    }
    if (frozen > 0) {
      switch (kind) {
        case ReturnHomeObstacleKind.log:
          paintIceBlock(canvas, frozen,
              width: vertical ? 34 : 78, height: vertical ? 78 : 34);
        case ReturnHomeObstacleKind.spring:
          if (springT > 0) paintIceBlock(canvas, frozen, height: 46);
        default:
          paintIceBlock(canvas, frozen);
      }
    }
    canvas.restore();
  }
}

extension on ReturnHomeObstacle {
  /// Charred patch and embers on a log that has taken a fireball.
  void _paintScorch(Canvas canvas) {
    final rect = vertical
        ? Rect.fromCenter(center: const Offset(-1, -3), width: 22, height: 40)
        : Rect.fromCenter(center: const Offset(-3, 1), width: 40, height: 22);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = const Color(0x88201008));
    final ember = Paint()..color = const Color(0xFFFF8A3A);
    canvas.drawCircle(rect.center + const Offset(-5, -3), 2.2, ember);
    canvas.drawCircle(rect.center + const Offset(6, 2), 1.8, ember);
    canvas.drawCircle(rect.center + const Offset(0, 5), 1.5, ember);
  }

  /// Hidden: only a slightly different grass tuft gives it away.
  /// Fired: a hinged launch pad whose coil snaps out toward the back (left,
  /// the way the cat is flung), wobbles, then folds back into the grass.
  void _paintSpring(Canvas canvas) {
    if (springT <= 0) {
      final tuft = Paint()
        ..color = const Color(0x5546703C)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = -2; i <= 2; i++) {
        canvas.drawLine(
            Offset(i * 4.0, 5), Offset(i * 5.0, -3 - (i % 2) * 2.0), tuft);
      }
      return;
    }

    // Snap out fast, overshoot and wobble, hold, then retract at the end.
    final e = springShowTime - springT;
    const snap = .07;
    final ext = e < snap
        ? e / snap
        : 1 + .22 * exp(-(e - snap) * 7) * sin((e - snap) * 32);
    final retract = min(1.0, springT / (springShowTime * .35));
    final out = ext * retract;
    final length = 6 + 24 * out;
    // Leans back (counter-clockwise = toward the left) as it extends.
    final lean = -.85 * min(1.0, out);

    const ink = Color(0xFF3A3F44);
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    // Dust kicked up on the back side right after firing.
    if (e < .4) {
      final puff = 1 - e / .4;
      final dust = Paint()
        ..color = Color.fromARGB((120 * puff).round(), 0xD8, 0xC8, 0xA4);
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
            Offset(-14 - i * 7 - e * 40, 6 - i * 2.0), 3 + i + e * 10, dust);
      }
    }

    // Ground plate with hinge.
    final base = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, 4, 28, 6), const Radius.circular(2));
    canvas.drawRRect(base, Paint()..color = const Color(0xFF5C6166));
    canvas.drawRRect(base, outline);

    canvas.save();
    canvas.translate(4, 5);
    canvas.rotate(lean);

    // Back strut of the hinge: a rigid arm from the hinge to the pad.
    final arm = Paint()
      ..color = const Color(0xFF6E767C)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(8, 0), Offset(8, -length + 2), arm);

    // Coil zig-zag along the launch axis.
    final coil = Paint()
      ..color = const Color(0xFFB7C0C6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final coilPath = Path()..moveTo(0, 0);
    const turns = 6;
    for (var i = 1; i <= turns; i++) {
      coilPath.lineTo(
          i == turns ? 0 : (i.isEven ? -6 : 6), -(length - 4) * i / turns);
    }
    canvas.drawPath(
        coilPath,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(coilPath, coil);

    // Pad: faces up-and-back, the surface that bats the cat away.
    final pad = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -length), width: 30, height: 8),
        const Radius.circular(3));
    canvas.drawRRect(pad, Paint()..color = const Color(0xFFC94F45));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-13, -length - 3, 26, 2.5), const Radius.circular(1)),
        Paint()..color = const Color(0xFFEF7D6E));
    canvas.drawRRect(pad, outline);
    // Arrow chevrons on the pad pointing back.
    final chevron = Paint()
      ..color = const Color(0xFFFFF4DA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final x in const [-4.0, 4.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(x + 2, -length - 2)
            ..lineTo(x - 1, -length)
            ..lineTo(x + 2, -length + 2),
          chevron);
    }
    canvas.restore();

    // Speed streaks flying backwards during the snap.
    if (e < .3) {
      final k = 1 - e / .3;
      final streak = Paint()
        ..color = Color.fromARGB((200 * k).round(), 0xFF, 0xFF, 0xFF)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = -22.0 + i * 8;
        final x = -20.0 - e * 60;
        canvas.drawLine(Offset(x, y), Offset(x - 12 * k - 4, y + 3), streak);
      }
    }
  }
}

/// Hazard-vs-hazard physics. Rocks are moving circles; logs and spikes are
/// fixed bodies. Overlaps are pushed apart so nothing passes through, and the
/// velocity along the contact normal is reflected with energy loss.
void resolveObstacleCollisions(List<ReturnHomeObstacle> obstacles) {
  final rocks = obstacles
      .where((o) => o.kind == ReturnHomeObstacleKind.rock)
      .toList(growable: false);
  final solids = obstacles
      .where((o) =>
          o.kind == ReturnHomeObstacleKind.log ||
          o.kind == ReturnHomeObstacleKind.spikes)
      .toList(growable: false);

  for (var i = 0; i < rocks.length; i++) {
    final a = rocks[i];
    for (var j = i + 1; j < rocks.length; j++) {
      final b = rocks[j];
      final delta = b.position - a.position;
      final distance = delta.length;
      if (distance == 0 || distance >= rockRadius * 2) continue;
      final normal = delta / distance;
      final push = normal * ((rockRadius * 2 - distance) / 2);
      a.position -= push;
      b.position += push;
      final approach = (b.velocity - a.velocity).dot(normal);
      if (approach >= 0) continue;
      // Equal masses: each rock takes half of the normal impulse.
      final impulse = normal * (-(1 + rockRestitution) * approach / 2);
      a.velocity -= impulse;
      b.velocity += impulse;
    }
  }

  for (final rock in rocks) {
    for (final solid in solids) {
      final box = solid.solidRect;
      final closest = Vector2(
          rock.position.x.clamp(box.left, box.right).toDouble(),
          rock.position.y.clamp(box.top, box.bottom).toDouble());
      var normal = rock.position - closest;
      var distance = normal.length;
      if (distance >= rockRadius) continue;
      if (distance == 0) {
        // Center already inside: push out the shortest way.
        final left = rock.position.x - box.left;
        final right = box.right - rock.position.x;
        final top = rock.position.y - box.top;
        final bottom = box.bottom - rock.position.y;
        final least = [left, right, top, bottom].reduce(min);
        normal = least == left
            ? Vector2(-1, 0)
            : least == right
                ? Vector2(1, 0)
                : least == top
                    ? Vector2(0, -1)
                    : Vector2(0, 1);
        distance = -least;
      } else {
        normal /= distance;
      }
      rock.position += normal * (rockRadius - distance);
      final into = rock.velocity.dot(normal);
      if (into < 0) rock.velocity -= normal * ((1 + wallRestitution) * into);
    }
  }
}
