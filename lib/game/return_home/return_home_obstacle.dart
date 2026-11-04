import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'return_home_hazard_art.dart';
import 'return_home_road.dart';

enum ReturnHomeObstacleKind { spikes, rock, log, bird, spring }

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
const double birdDiveDuration = .78;
const double birdDiveRange = 200.0;

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

  /// Seconds left in the popped-up pose; 0 means armed and hidden.
  double springT = 0;

  double _flap = 0;
  double _diveT = -1;
  double _tilt = 0;
  double _shadowDy = 0;
  double _shadowDepth = 0;

  void updatePhysics(double dt, double catX) {
    if (kind == ReturnHomeObstacleKind.spring) {
      springT = max(0, springT - dt);
      return;
    }
    if (kind == ReturnHomeObstacleKind.bird) {
      _updateBird(dt, catX);
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

  /// Cruises high over the road, then swoops onto the lane once. The dive only
  /// arms while the bird is still ahead of the cat, so the shadow warning and
  /// the strike land in front of the player instead of behind them.
  void _updateBird(double dt, double catX) {
    position += velocity * dt;
    _flap += dt * 13;
    final cruise = road.viewportHeight * birdCruiseHeight;
    final strike = road.centerY(position.x);
    final shadowY = strike + road.halfWidth(position.x) * .55;
    if (_diveT < 0) {
      if (position.x > catX && position.x - catX < birdDiveRange) {
        _diveT = 0;
      } else {
        position.y = cruise;
        _tilt = 0;
        _shadowDepth = 0;
        _shadowDy = shadowY - cruise;
        return;
      }
    }
    _diveT += dt;
    final t = min(1.0, _diveT / birdDiveDuration);
    final dip = sin(pi * t);
    position.y = cruise + (strike - cruise) * dip;
    _tilt = (_diveT < birdDiveDuration / 2 ? -.5 : .42) * min(1, dip * 2.5);
    _shadowDepth = dip;
    _shadowDy = shadowY - position.y;
    if (t >= 1) _diveT = -1;
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
    if (kind == ReturnHomeObstacleKind.bird) {
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
            shadowDy: _shadowDy,
            shadowDepth: _shadowDepth);
      case ReturnHomeObstacleKind.log:
        paintLog(canvas, vertical: vertical);
      case ReturnHomeObstacleKind.spring:
        _paintSpring(canvas);
    }
    canvas.restore();
  }
}

extension on ReturnHomeObstacle {
  /// Hidden: only a slightly different grass tuft gives it away. Fired: a
  /// metal plate on a stretched coil that sinks back into the grass.
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
    final lift = 22 * min(1.0, springT / springShowTime * 1.6);
    final coil = Paint()
      ..color = const Color(0xFF8E979C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(-8, 6);
    for (var i = 1; i <= 5; i++) {
      path.lineTo(i.isEven ? -8 : 8, 6 - lift * i / 5);
    }
    canvas.drawPath(path, coil);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-15, 2 - lift - 5, 30, 6), const Radius.circular(3)),
        Paint()..color = const Color(0xFFC94F45));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-12, 5, 24, 5), const Radius.circular(2)),
        Paint()..color = const Color(0xFF5C6166));
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
