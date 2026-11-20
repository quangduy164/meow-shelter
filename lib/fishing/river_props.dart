import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'fishing_river.dart';

enum RiverPropKind { lily, raft, log, rock }

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
  bool get solid => kind == RiverPropKind.rock;
  static Offset waterPoint(Offset p) => Offset(p.dx,
      p.dy.clamp(FishingRiver.top(p.dx) + 55, FishingRiver.bottom(p.dx) - 55));
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
      for (var j = 0; j < 13; j++) {
        props.add(RiverProp(RiverPropKind.lily,
            p + Offset(rng.nextDouble() * 160 - 80, rng.nextDouble() * 65 - 32),
            flower: j % 4 == 0));
      }
      if (i.isOdd) {
        props.add(RiverProp(RiverPropKind.raft, p + const Offset(105, -12),
            radius: 40));
      }
    } else {
      for (var j = 0; j < 5; j++) {
        props.add(RiverProp(
            RiverPropKind.rock, p + Offset(j * 27 - 50, math.sin(j * 2) * 18),
            radius: 14 + rng.nextDouble() * 12));
      }
      props.add(
          RiverProp(RiverPropKind.log, p + const Offset(40, 32), radius: 40));
    }
  }
  for (final cove in FishingRiver.coves.take(2)) {
    final p = Offset(
        cove.x,
        cove.north
            ? FishingRiver.top(cove.x) + 75
            : FishingRiver.bottom(cove.x) - 75);
    if (cove.north) {
      for (var i = 0; i < 18; i++) {
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
  return props;
}

class RiverProps {
  final items = createRiverProps();
  final wildlifeOffsets = List<Offset>.filled(12, Offset.zero);
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
      !rocks.any(
          (r) => (p - r.anchor).distance < r.radius + boatRadius + 4 - 1e-5);

  bool clearLine(Offset a, Offset b) {
    final delta = b - a;
    final length2 = delta.distanceSquared;
    for (final rock in rocks) {
      final relative = rock.anchor - a;
      final t = length2 > 0
          ? ((relative.dx * delta.dx + relative.dy * delta.dy) / length2)
              .clamp(0.0, 1.0)
          : 0.0;
      if ((a + delta * t - rock.anchor).distance <
          rock.radius + boatRadius + 4 - 1e-5) {
        return false;
      }
    }
    final count = math.max(1, (delta.distance / 8).ceil());
    for (var i = 0; i <= count; i++) {
      final p = Offset.lerp(a, b, i / count)!;
      if ((FishingRiver.constrain(p) - p).distance > .001) return false;
    }
    return true;
  }

  Offset resolve(Offset point) {
    var p = FishingRiver.constrain(point);
    for (var pass = 0; pass < 12; pass++) {
      var changed = false;
      for (final rock in rocks) {
        final delta = p - rock.anchor;
        final radius = rock.radius + boatRadius + 4;
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
      p.velocity +=
          ((p.anchor + drift - p.position) * .5 - p.velocity * 1.4) * dt;
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
            .01;
        p.ripple = .8;
      }
      p.spin += (-p.angle * .4 - p.spin * 1.6) * dt;
      p.angle += p.spin * dt;
    }
  }
}
