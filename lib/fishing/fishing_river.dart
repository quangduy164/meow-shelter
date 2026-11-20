import 'fishing_fight.dart';
import 'river_props.dart';
import 'river_navigation.dart';
import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../collection/fish_species.dart';

/// Continuous world coordinates, independent of the screen and camera.
class FishingRiver {
  static const height = 2200.0;
  static const viewHeight = 600.0;
  static const sectionLength = 1800.0;
  static const sectionCount = 3;
  static const seaStart = sectionLength * 2;
  static const length = sectionLength * sectionCount;
  static double coastBlend(double x) {
    final t = ((x - (seaStart - 240)) / 720).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static const boatMargin = 30.0;
  static const startDockX = 230.0;
  static Offset get startBoat => Offset(startDockX, bottom(startDockX) - 42);

  /// Exclusive regional pools cross-fade around the join; weights are relative.
  static FishSpecies rollFish(int roll, double x, double hour,
      {bool activeWater = false}) {
    const village = {
      FishSpecies.perch: 32.0,
      FishSpecies.tilapia: 32.0,
      FishSpecies.carp: 28.0,
      FishSpecies.goldfish: 3.0,
      FishSpecies.flipFlop: 3.0,
      FishSpecies.tinCan: 2.0
    };
    const bamboo = {
      FishSpecies.catfish: 49.0,
      FishSpecies.koi: 43.0,
      FishSpecies.catMew: 1.0,
      FishSpecies.oldBoot: 4.0,
      FishSpecies.tinCan: 3.0
    };
    const sea = {
      FishSpecies.sardine: 54.0,
      FishSpecies.mackerel: 29.0,
      FishSpecies.clownfish: 12.0,
      FishSpecies.pufferfish: 3.0,
      FishSpecies.flipFlop: 1.0,
      FishSpecies.tinCan: 1.0,
    };
    final mix = ((x - 1560) / 480).clamp(0.0, 1.0);
    final marineMix = ((x - (seaStart - 240)) / 480).clamp(0.0, 1.0);
    final night = hour < 6 || hour >= 18;
    final weights = <FishSpecies, double>{
      for (final fish in FishSpecies.values)
        fish: (((village[fish] ?? 0) * (1 - mix) + (bamboo[fish] ?? 0) * mix) *
                    (1 - marineMix) +
                (sea[fish] ?? 0) * marineMix) *
            (night && fish.nightActive ? 1.35 : 1) *
            (activeWater
                ? (fish.isJunk
                    ? .3
                    : fish.rarity == 'Phổ biến'
                        ? 1
                        : 3)
                : 1),
    };
    final total = weights.values.fold(0.0, (sum, weight) => sum + weight);
    var ticket = (roll % 10000) / 10000 * total;
    for (final entry in weights.entries) {
      ticket -= entry.value;
      if (ticket < 0) return entry.key;
    }
    return FishSpecies.tinCan;
  }

  // Smooth bank inlets stay part of the same navigable channel and route rules.
  static const coves = [
    (x: 950.0, radius: 300.0, depth: 330.0, north: true),
    (x: 2650.0, radius: 340.0, depth: 310.0, north: false),
    (x: 4550.0, radius: 380.0, depth: 60.0, north: true),
  ];

  static double _inlet(double x, bool north) {
    var depth = 0.0;
    for (final cove in coves) {
      final t = (x - cove.x).abs() / cove.radius;
      if (cove.north == north && t < 1) {
        final bell = (1 + math.cos(t * math.pi)) / 2;
        depth += cove.depth * bell * bell;
      }
    }
    return depth;
  }

  static double center(double x) {
    final river =
        1100 + 150 * math.sin(x / 620 - .4) + 65 * math.sin(x / 290 + .5);
    final sea = 1050 + math.sin(x / 780) * 70;
    return river +
        (sea - river) * coastBlend(x) +
        (_inlet(x, false) - _inlet(x, true)) / 2;
  }

  static double halfWidth(double x) {
    final river = 410 + 85 * math.sin(x / 500 + .4) + 45 * math.cos(x / 260);
    final sea = 740 + math.sin(x / 580) * 60;
    return river +
        (sea - river) * coastBlend(x) +
        (_inlet(x, false) + _inlet(x, true)) / 2;
  }

  static double top(double x) => center(x) - halfWidth(x);
  static double bottom(double x) => center(x) + halfWidth(x);
  static bool contains(Offset p) =>
      p.dx >= 0 && p.dx <= length && p.dy >= top(p.dx) && p.dy <= bottom(p.dx);

  static Offset constrain(Offset p) {
    final x = p.dx.clamp(55.0, length - 55);
    return Offset(x, p.dy.clamp(top(x) + boatMargin, bottom(x) - boatMargin));
  }

  static String sectionName(double x) => x < sectionLength
      ? 'Làng ven sông'
      : x < seaStart
          ? 'Khúc sông tre'
          : 'Cửa biển nắng vàng';
}

/// Click-to-row movement and a smoothly following two-axis camera.
class FishingRiverRound {
  final props = RiverProps();
  Offset boat = FishingRiver.startBoat;
  Offset _lastBoat = FishingRiver.startBoat;
  Offset heading = const Offset(1, 0);
  Offset? destination;
  Size viewport = Size.zero;
  double cameraLeft = 0, cameraTop = 0, clock = 0, speed = 0, wake = 0;
  Offset steering = Offset.zero;
  bool chasing = false;
  double hitTime = 0;
  double _chaseDirection = 1;
  final _route = <Offset>[];
  bool get moving => destination != null;
  bool get rowing => moving || chasing;
  double get scale =>
      viewport.height > 0 ? viewport.height / FishingRiver.viewHeight : 1;
  double get visibleWidth => viewport.width / scale;
  double get visibleHeight => viewport.height / scale;
  double get maxCameraTop => math.max(0, FishingRiver.height - visibleHeight);
  double get maxCamera => math.max(0, FishingRiver.length - visibleWidth);
  int get section => (boat.dx / FishingRiver.sectionLength).floor() + 1;

  void resize(Size size) {
    if (viewport == size) return;
    viewport = size;
    cameraLeft = (boat.dx - visibleWidth * .42).clamp(0.0, maxCamera);
    cameraTop = (boat.dy - visibleHeight * .5).clamp(0.0, maxCameraTop);
  }

  Offset toWorld(Offset screen) =>
      Offset(screen.dx / scale + cameraLeft, screen.dy / scale + cameraTop);
  Offset toScreen(Offset world) =>
      Offset((world.dx - cameraLeft) * scale, (world.dy - cameraTop) * scale);

  bool tap(Offset screen) {
    final world = toWorld(screen);
    if (!FishingRiver.contains(world)) return false;
    sailTo(world);
    return true;
  }

  void stop() {
    _route.clear();
    destination = null;
    speed = 0;
  }

  void beginFight(Offset fish) {
    stop();
    chasing = true;
    steering = Offset.zero;
    hitTime = 0;
    _chaseDirection = fish.dx < boat.dx ? -1 : 1;
  }

  void steer(Offset delta) {
    steering = Offset((steering.dx + delta.dx).clamp(-1.0, 1.0),
        (steering.dy + delta.dy).clamp(-1.0, 1.0));
  }

  bool chase(double dt, FishSpecies fish, double elapsed, double surge,
      {required bool pulling, required bool beginner, double weightPull = 1}) {
    final weave = switch (fish) {
      FishSpecies.perch => math.sin(elapsed * 3) * .9,
      FishSpecies.sardine => math.sin(elapsed * 2.5) * .55,
      FishSpecies.mackerel => math.sin(elapsed * .8) * .45,
      FishSpecies.clownfish => math.sin(elapsed * 2.2) * 1.05,
      FishSpecies.pufferfish => math.sin(elapsed * .7) * .3,
      FishSpecies.carp => math.sin(elapsed * .5) * .25,
      FishSpecies.catfish => math.sin(elapsed * 1.3) * .6,
      FishSpecies.koi => FishingFight.at(fish, elapsed).lateral,
      FishSpecies.goldfish => math.sin(elapsed * 2) * .75,
      FishSpecies.catMew => math.sin(elapsed * 2.4) * .8,
      _ => math.sin(elapsed) * .4,
    };
    final move = FishingFight.at(fish, elapsed).move;
    final reverse = fish == FishSpecies.catMew && move == FishFightMove.dash;
    final forward = _chaseDirection * (reverse ? -1 : 1);
    final slope =
        (FishingRiver.center(boat.dx + 5) - FishingRiver.center(boat.dx - 5)) /
            10;
    final speedFactor = switch (move) {
      FishFightMove.inflate => .12,
      FishFightMove.dash => 1.6,
      FishFightMove.rest => .45,
      _ => 1.0,
    };
    final pullSpeed = (beginner ? 50 : 85) *
        (.65 + surge * .65) *
        (pulling ? .7 : 1) *
        speedFactor *
        weightPull;
    final velocity = Offset(
        forward * pullSpeed + steering.dx * 160,
        slope * forward * pullSpeed +
            weave * (beginner ? 25 : 42) +
            steering.dy * 140);
    heading = velocity / math.max(.001, velocity.distance);
    final intended = boat + velocity * dt;
    boat = props.resolve(boat + velocity * dt * props.dragAt(boat));
    steering *= math.max(0, 1 - dt * 2.8);
    if ((FishingRiver.constrain(intended) - intended).distance > .1 &&
        hitTime <= 0) {
      hitTime = 1.4;
      return true;
    }
    return false;
  }

  void sailTo(Offset world) {
    final target = props.resolve(world);
    destination = target;
    _route.clear();
    if ((target - boat).distance < .5) {
      boat = target;
      destination = null;
      speed = 0;
      return;
    }
    final start = boat;
    // Interpolate across the channel while following its bends. A straight
    // line between two distant clicks would cut through the riverbanks.
    final startLane = (start.dy - FishingRiver.center(start.dx)) /
        (FishingRiver.halfWidth(start.dx) - FishingRiver.boatMargin);
    final endLane = (target.dy - FishingRiver.center(target.dx)) /
        (FishingRiver.halfWidth(target.dx) - FishingRiver.boatMargin);
    final steps = math.max(1, ((target.dx - start.dx).abs() / 24).ceil());
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final x = start.dx + (target.dx - start.dx) * t;
      final lane = startLane + (endLane - startLane) * t;
      _route.add(FishingRiver.constrain(Offset(
          x,
          FishingRiver.center(x) +
              lane * (FishingRiver.halfWidth(x) - FishingRiver.boatMargin))));
    }
    _avoidRocks();
  }

  void _avoidRocks() {
    var from = boat;
    for (final point in _route) {
      if (!props.clearLine(from, point)) {
        final detour = riverDetour(props, boat, destination!);
        _route
          ..clear()
          ..addAll(detour);
        if (_route.isEmpty) stop();
        return;
      }
      from = point;
    }
  }

  void update(double dt) {
    assert(dt >= 0 && dt <= .05);
    clock += dt;
    hitTime = math.max(0, hitTime - dt);
    if (_route.isNotEmpty) {
      var remaining = 0.0;
      var previous = boat;
      for (final point in _route) {
        remaining += (point - previous).distance;
        previous = point;
      }
      final wantedSpeed =
          math.min(185.0, math.sqrt(2 * 210 * remaining)) * props.dragAt(boat);
      speed += (wantedSpeed - speed) * (1 - math.exp(-7 * dt));
      var travel = speed * dt;
      while (_route.isNotEmpty && travel > 0) {
        final difference = _route.first - boat;
        final distance = difference.distance;
        if (distance > .001) {
          heading = difference / distance;
          final step = math.min(travel, distance);
          boat = props.resolve(boat + heading * step);
          travel -= step;
        }
        if (distance < .001 || (boat - _route.first).distance < .01) {
          _route.removeAt(0);
        } else {
          break;
        }
      }
      if (_route.isEmpty) {
        boat = destination!;
        destination = null;
        speed = 0;
      }
    }
    props.update(
        dt, clock, boat, dt > 0 ? (boat - _lastBoat) / dt : Offset.zero);
    _lastBoat = boat;
    wake += ((rowing ? 1 : 0) - wake) * (1 - math.exp(-4 * dt));
    final targetCamera = (boat.dx - visibleWidth * .42).clamp(0.0, maxCamera);
    cameraLeft += (targetCamera - cameraLeft) * (1 - math.exp(-5 * dt));
    cameraLeft = cameraLeft.clamp(0.0, maxCamera);
    final targetTop = (boat.dy - visibleHeight * .5).clamp(0.0, maxCameraTop);
    cameraTop += (targetTop - cameraTop) * (1 - math.exp(-5 * dt));
    cameraTop = cameraTop.clamp(0.0, maxCameraTop);
  }
}
