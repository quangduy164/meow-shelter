import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'fishing_river.dart';
import 'river_frog.dart';
import 'river_sea_land.dart';
import 'fishing_cabin.dart';
import 'fishing_market.dart';
import 'fishing_shrine.dart';
import 'fishing_bait_house.dart';
import 'river_encounters.dart';

enum RiverPropKind {
  lily,
  raft,
  log,
  rock,
  paperBoat,
  island,
  mangroveRoot,
  cabinShip,
  market,
  shrine,
  baitHouse
}

class RiverProp {
  RiverProp(this.kind, Offset point, {this.radius = 16, this.flower = false})
      : anchor = waterPoint(point),
        position = waterPoint(point);
  final RiverPropKind kind;
  final Offset anchor;
  final double radius;
  final bool flower;
  Offset position, velocity = Offset.zero;
  double angle = 0, spin = 0, ripple = 0;
  bool get solid =>
      kind == RiverPropKind.rock ||
      kind == RiverPropKind.island ||
      kind == RiverPropKind.mangroveRoot ||
      kind == RiverPropKind.cabinShip ||
      kind == RiverPropKind.market ||
      kind == RiverPropKind.shrine ||
      kind == RiverPropKind.baitHouse;

  /// Solid reach toward [p]; the island follows its coastline.
  double reachTowards(Offset p) {
    if (kind == RiverPropKind.island) return fishingSeaIsland.radiusTowards(p);
    final depth = switch (kind) {
      RiverPropKind.market => FishingMarket.waterDepth,
      RiverPropKind.shrine => FishingShrine.waterDepth,
      RiverPropKind.baitHouse => FishingBaitHouse.waterDepth,
      RiverPropKind.cabinShip => FishingCabin.waterDepth,
      _ => radius,
    };
    return FishingRiver.structureReach(p - anchor, radius, depth);
  }

  static Offset waterPoint(Offset p) {
    final x = p.dx.clamp(55.0, FishingRiver.length - 55);
    return Offset(
        x, p.dy.clamp(FishingRiver.top(x) + 55, FishingRiver.bottom(x) - 55));
  }
}

/// One layout feeds cached rocks, moving artwork and boat collision/navigation.
List<RiverProp> createRiverProps() {
  final props = <RiverProp>[];
  for (var i = 0; i < 12; i++) {
    final x = 420.0 + i * 265;
    final p = Offset(
        x, i.isEven ? FishingRiver.top(x) + 95 : FishingRiver.bottom(x) - 100);
    final rng = math.Random(927 + i);
    if (x < 1800) {
      for (var j = 0; j < 6; j++) {
        props.add(RiverProp(RiverPropKind.lily,
            p + Offset(rng.nextDouble() * 160 - 80, rng.nextDouble() * 65 - 32),
            flower: j % 4 == 0));
      }
      if (i == 1) {
        props.add(RiverProp(RiverPropKind.raft, p + const Offset(105, -12),
            radius: 40));
      }
    } else {
      for (var j = 0; j < 5; j++) {
        props.add(RiverProp(
            RiverPropKind.rock, p + Offset(j * 27 - 50, math.sin(j * 2) * 18),
            radius: 14 + rng.nextDouble() * 12));
      }
      if (i.isEven) {
        props.add(
            RiverProp(RiverPropKind.log, p + const Offset(40, 32), radius: 40));
      }
    }
  }
  for (final cove in FishingRiver.coves.take(2)) {
    final p = Offset(
        cove.x,
        cove.north
            ? FishingRiver.top(cove.x) + 75
            : FishingRiver.bottom(cove.x) - 75);
    if (cove.north) {
      for (var i = 0; i < 9; i++) {
        props.add(RiverProp(
            RiverPropKind.lily,
            p +
                Offset(math.cos(i * 2.4) * (45 + i * 3),
                    math.sin(i * 2.4) * (20 + i * 1.5)),
            flower: i % 3 == 0));
      }
    } else {
      props.add(
          RiverProp(RiverPropKind.raft, p + const Offset(-70, 0), radius: 40));
      props.add(
          RiverProp(RiverPropKind.log, p + const Offset(55, 10), radius: 40));
    }
  }
  for (var i = 0; i < 5; i++) {
    final x = 540 + i * 620.0;
    props.add(RiverProp(RiverPropKind.paperBoat,
        Offset(x, FishingRiver.center(x) + (i.isEven ? 130 : -160)),
        radius: 22));
  }
  props.add(RiverProp(RiverPropKind.island, fishingSeaIsland.center,
      radius: fishingSeaIsland.radius));
  for (final rock in fishingSeaRocks) {
    props.add(RiverProp(RiverPropKind.rock, rock.center, radius: rock.radius));
  }
  for (var i = 0; i < 10; i++) {
    final x = 3900 + i * 145.0;
    for (final north in [true, false]) {
      final rx = x + (north ? 0 : 65);
      if (rx > FishingRiver.length - 100) continue;
      props.add(RiverProp(
          RiverPropKind.mangroveRoot,
          Offset(rx,
              north ? FishingRiver.top(rx) + 58 : FishingRiver.bottom(rx) - 58),
          radius: 26));
    }
  }
  for (final point in [
    const Offset(7540, 1480),
    const Offset(7660, 1530),
    const Offset(7920, 2020),
    const Offset(7970, 2070),
  ]) {
    props.add(RiverProp(RiverPropKind.rock, point,
        radius: point.dy < 1400 ? 24 : 38));
  }
  props.add(RiverProp(RiverPropKind.cabinShip, FishingCabin.ship,
      radius: FishingCabin.radius));
  props.add(RiverProp(RiverPropKind.market, FishingMarket.center,
      radius: FishingMarket.radius));
  props.add(RiverProp(RiverPropKind.shrine, FishingShrine.center,
      radius: FishingShrine.radius));
  props.add(RiverProp(RiverPropKind.baitHouse, FishingBaitHouse.center,
      radius: FishingBaitHouse.radius));
  return props;
}

class RiverDuck {
  RiverDuck(this.anchor, this.size, this.phase, this.pace)
      : position = anchor,
        facing = math.cos(phase) < 0 ? -1 : 1;
  final Offset anchor;
  final double size, phase, pace;
  Offset position, velocity = Offset.zero;
  double facing;
}

List<RiverDuck> _createDucks() {
  final rng = math.Random(541);
  final ducks = <RiverDuck>[];
  for (var group = 0; group < 4; group += 2) {
    final home = RiverProps.wildlifeHome(group);
    for (var i = 0; i < 5; i++) {
      var p = home;
      for (var attempt = 0; attempt < 80; attempt++) {
        p = RiverProp.waterPoint(home +
            Offset(rng.nextDouble() * 270 - 135, rng.nextDouble() * 200 - 100));
        if (ducks.every((d) => (d.position - p).distance > 58)) break;
      }
      ducks.add(RiverDuck(p, i == 0 ? 1 : .65 + rng.nextDouble() * .22,
          rng.nextDouble() * math.pi * 2, .18 + rng.nextDouble() * .2));
    }
  }
  return ducks;
}

class RiverProps {
  final items = createRiverProps();
  final ducks = _createDucks();
  late final frogs = _createFrogs();
  late final turtles = _createTurtles();
  List<RiverTurtle> _createTurtles() {
    final result = <RiverTurtle>[];
    for (var i = 0; i < rocks.length; i++) {
      final rock = rocks[i];
      if (rock.kind == RiverPropKind.rock &&
          rock.radius >= 24 &&
          result.every((t) => (t.rock - rock.anchor).distance > 600)) {
        result.add(RiverTurtle(rock.anchor, rock.radius, i));
      }
    }
    return result;
  }

  final jumpingFish = [
    for (var i = 0; 600 + i * 900 < FishingRiver.length; i++)
      RiverJumpFish(600 + i * 900.0, i)
  ];

  List<RiverFrog> _createFrogs() {
    final result = <RiverFrog>[];
    for (var i = 0; i < items.length; i++) {
      final lily = items[i];
      if (lily.kind != RiverPropKind.lily || lily.flower) continue;
      if (result.every(
          (f) => (items[f.lilyIndex].anchor - lily.anchor).distance > 210)) {
        result.add(RiverFrog(i, i, lily.position));
      }
    }
    return result;
  }

  final wildlifeOffsets = List<Offset>.filled(
      ((FishingRiver.length - 480) / 420).ceil(), Offset.zero);
  static Offset wildlifeHome(int group) {
    final x = 480 + group * 420.0;
    return Offset(
        x,
        FishingRiver.center(x) +
            math.sin(group * 2.3) * FishingRiver.halfWidth(x) * .6);
  }

  double dragAt(Offset boat) => items.any((p) =>
          !p.solid && (p.position - boat).distance < boatRadius + p.radius)
      ? .7
      : 1;
  late final rocks = items.where((p) => p.solid).toList(growable: false);
  static const boatRadius = 45.0;

  bool clear(Offset p) =>
      (FishingRiver.constrain(p) - p).distance < .01 &&
      !rocks.any((r) =>
          (p - r.anchor).distance < r.reachTowards(p) + boatRadius + 4 - 1e-5);

  bool clearLine(Offset a, Offset b) {
    final delta = b - a;
    final length2 = delta.distanceSquared;
    final count = math.max(1, (delta.distance / 8).ceil());
    final corridor = Rect.fromPoints(a, b);
    for (final rock in rocks) {
      if (rock.kind != RiverPropKind.island &&
          !corridor
              .inflate(rock.radius + boatRadius + 4)
              .contains(rock.anchor)) {
        continue;
      }
      if (rock.kind == RiverPropKind.island ||
          rock.kind == RiverPropKind.market ||
          rock.kind == RiverPropKind.shrine ||
          rock.kind == RiverPropKind.baitHouse ||
          rock.kind == RiverPropKind.cabinShip) {
        // Directional footprints need a swept check, not a circular closest point.
        for (var i = 0; i <= count; i++) {
          final p = Offset.lerp(a, b, i / count)!;
          if ((p - rock.anchor).distance <
              rock.reachTowards(p) + boatRadius + 4 - 1e-5) {
            return false;
          }
        }
        continue;
      }
      final relative = rock.anchor - a;
      final t = length2 > 0
          ? ((relative.dx * delta.dx + relative.dy * delta.dy) / length2)
              .clamp(0.0, 1.0)
          : 0.0;
      final closest = a + delta * t;
      if ((closest - rock.anchor).distance <
          rock.reachTowards(closest) + boatRadius + 4 - 1e-5) {
        return false;
      }
    }
    for (var i = 0; i <= count; i++) {
      final p = Offset.lerp(a, b, i / count)!;
      if ((FishingRiver.constrain(p) - p).distance > .001) return false;
    }
    return true;
  }

  /// Physical movement stays on the current side of obstacles. `resolve`
  /// projects click targets out of overlapping rocks and can jump too far
  /// to use as a movement step.
  Offset slide(Offset from, Offset delta) {
    if (delta.distanceSquared < 1e-12) return from;
    if (clearLine(from, from + delta)) return from + delta;
    final steps = math.max(1, (delta.distance / 4).ceil());
    final step = delta / steps.toDouble();
    var p = from;
    for (var i = 0; i < steps; i++) {
      if (clearLine(p, p + step)) {
        p += step;
        continue;
      }
      var tangent = step;
      for (final rock in rocks) {
        final target = p + step;
        if ((target - rock.anchor).distance >=
            rock.reachTowards(target) + boatRadius + 4) {
          continue;
        }
        final normal = p - rock.anchor;
        if (normal.distance < .001) continue;
        final n = normal / normal.distance;
        final inward = tangent.dx * n.dx + tangent.dy * n.dy;
        if (inward < 0) tangent -= n * inward;
      }
      var best = p;
      var advance = 0.0;
      // Bank clamping provides a shoreline tangent; all candidates are
      // swept and bounded so none can eject the boat to another shore.
      for (final candidate in [
        FishingRiver.constrainBanks(p + tangent) - p,
        Offset(step.dx, 0),
        Offset(0, step.dy),
        step,
      ]) {
        final motion = candidate.distance > step.distance
            ? candidate / candidate.distance * step.distance
            : candidate;
        var fraction = 1.0;
        if (!clearLine(p, p + motion)) {
          var lo = 0.0, hi = 1.0;
          for (var j = 0; j < 8; j++) {
            final mid = (lo + hi) / 2;
            if (clearLine(p, p + motion * mid)) {
              lo = mid;
            } else {
              hi = mid;
            }
          }
          fraction = lo;
        }
        final moved = motion * fraction;
        final dot = moved.dx * step.dx + moved.dy * step.dy;
        if (dot > advance) {
          advance = dot;
          best = p + moved;
        }
        if (fraction == 1 && dot > 0) break;
      }
      p = best;
    }
    return p;
  }

  Offset resolve(Offset point) {
    var p = FishingRiver.constrain(point);
    for (var pass = 0; pass < 12; pass++) {
      var changed = false;
      for (final rock in rocks) {
        final delta = p - rock.anchor;
        final radius = rock.reachTowards(p) + boatRadius + 4;
        if (delta.distance >= radius) continue;
        var direction = delta.distance > .001
            ? delta / delta.distance
            : const Offset(0, -1);
        // Overlapping shoreline rocks expel a click toward open water.
        if (pass > 3) {
          direction = Offset(0, FishingRiver.center(p.dx) > p.dy ? 1 : -1);
        }
        p = FishingRiver.constrain(rock.anchor + direction * radius);
        changed = true;
      }
      if (!changed) break;
    }
    return p;
  }

  void update(double dt, double time, Offset boat, Offset boatVelocity) {
    // Compute every velocity before moving anyone, so spacing is order independent.
    final velocities = <Offset>[];
    for (final duck in ducks) {
      final desired = RiverProp.waterPoint(duck.anchor +
          Offset(math.sin(time * duck.pace + duck.phase) * 65,
              math.sin(time * duck.pace * .73 + duck.phase * 2) * 45));
      var velocity = (desired - duck.position) * .65;
      final away = duck.position - boat;
      if (away.distance < 190) {
        velocity +=
            (away.distance > .01 ? away / away.distance : const Offset(1, 0)) *
                (190 - away.distance) *
                .8;
      }
      for (final other in ducks) {
        if (identical(duck, other)) continue;
        final delta = duck.position - other.position;
        if (delta.distance < 55) {
          velocity += (delta.distance > .01
                  ? delta / delta.distance
                  : const Offset(0, 1)) *
              (55 - delta.distance) *
              3;
        }
      }
      if (velocity.distance > 65) velocity = velocity / velocity.distance * 65;
      velocities.add(
          duck.velocity + (velocity - duck.velocity) * (1 - math.exp(-dt * 3)));
    }
    for (var i = 0; i < ducks.length; i++) {
      final duck = ducks[i];
      final before = duck.position;
      duck.velocity = velocities[i];
      duck.position = RiverProp.waterPoint(before + duck.velocity * dt);
      if ((duck.position.dx - before.dx).abs() > dt * 2) {
        duck.facing = duck.position.dx > before.dx ? 1 : -1;
      }
    }
    for (var group = 0; group < wildlifeOffsets.length; group++) {
      final home = wildlifeHome(group);
      final delta = home + wildlifeOffsets[group] - boat;
      final distance = delta.distance;
      final flee = distance < 230
          ? (distance > .01 ? delta / distance : const Offset(1, 0)) *
              (230 - distance)
          : Offset.zero;
      final target =
          distance < 230 ? wildlifeOffsets[group] + flee : Offset.zero;
      wildlifeOffsets[group] += (target - wildlifeOffsets[group]) *
          (1 - math.exp(-dt * (distance < 230 ? 2 : .35)));
      final safe = RiverProp.waterPoint(home + wildlifeOffsets[group]);
      wildlifeOffsets[group] = safe - home;
    }
    for (final p in items) {
      if (p.solid) continue;
      p.ripple = math.max(0, p.ripple - dt);
      final drift = Offset(math.sin(time * .35 + p.anchor.dx) * 5,
          math.sin(time * .8 + p.anchor.dx * .01) * 2.5);
      if (p.kind == RiverPropKind.paperBoat) {
        final flow = Offset(p.position.dx > FishingRiver.length - 160 ? -6 : 8,
            math.sin(time * .4 + p.anchor.dx) * 4);
        p.velocity += (flow - p.velocity) * (1 - math.exp(-dt * .7));
      } else {
        p.velocity +=
            ((p.anchor + drift - p.position) * .5 - p.velocity * 1.4) * dt;
      }
      p.position = RiverProp.waterPoint(p.position + p.velocity * dt);
      final delta = p.position - boat;
      final reach = boatRadius + p.radius;
      if (delta.distance < reach) {
        final normal =
            delta.distance > .01 ? delta / delta.distance : const Offset(1, 0);
        final overlap = reach - delta.distance;
        p.position = RiverProp.waterPoint(
            p.position + normal * overlap * (1 - math.exp(-12 * dt)));
        p.velocity += normal *
            (overlap * 10 +
                math.max(
                        0,
                        boatVelocity.dx * normal.dx +
                            boatVelocity.dy * normal.dy) *
                    2) *
            dt;
        p.spin += (normal.dx * boatVelocity.dy - normal.dy * boatVelocity.dx) *
            dt *
            (p.kind == RiverPropKind.paperBoat ? .08 : .01);
        p.ripple = .8;
      }
      if (p.kind == RiverPropKind.paperBoat) {
        for (final rock in rocks) {
          final away = p.position - rock.anchor;
          final clearance = rock.reachTowards(p.position) + p.radius;
          if (away.distance < clearance) {
            final normal =
                away.distance > .01 ? away / away.distance : const Offset(0, 1);
            p.position = RiverProp.waterPoint(rock.anchor + normal * clearance);
            p.velocity += normal * 12;
          }
        }
      }
      p.spin += (-p.angle * .4 - p.spin * 1.6) * dt;
      p.angle += p.spin * dt;
    }
    for (final turtle in turtles) {
      turtle.update(dt, boat, clear);
    }
    for (final fish in jumpingFish) {
      fish.update(dt, boat, clear);
    }
    for (final frog in frogs) {
      frog.update(dt, items[frog.lilyIndex].position, boat);
    }
  }
}
