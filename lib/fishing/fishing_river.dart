import 'fishing_fight.dart';
import 'river_props.dart';
import 'river_navigation.dart';
import 'river_sea_land.dart';
import 'fishing_island.dart';
import 'fishing_cabin.dart';
import 'fishing_market.dart';
import 'fishing_shrine.dart';
import 'fishing_bait_house.dart';
import 'fishing_cave.dart';
import 'fishing_exploration.dart';
import 'fishing_region.dart';
import 'fishing_weather.dart';
import 'fishing_boat.dart';
import 'fishing_crew.dart';
export 'fishing_region.dart';
import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../collection/fish_species.dart';

/// Continuous world coordinates, independent of the screen and camera.
class FishingRiver {
  static const height = 3600.0;
  static const viewHeight = 600.0;
  static const sectionLength = 1800.0;
  static const sectionCount = 7;
  static const seaStart = 5400.0;
  static const length = sectionLength * sectionCount;
  static const mangroveStart = 3600.0, rockyBayStart = 7200.0;
  static const openSeaStart = 9000.0, caveStart = 8100.0;
  static double _blend(double x, double start, double width) {
    final t = ((x - start) / width).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static double rockyBlend(double x) =>
      _blend(x, rockyBayStart - 300, 600) *
      (1 - _blend(x, openSeaStart - 300, 600));
  static double mangroveBlend(double x) =>
      _blend(x, mangroveStart - 300, 600) *
      (1 - _blend(x, seaStart - 300, 600));

  /// The Sea Cave is a round chamber north of the bay, reached through one
  /// short neck from the bay at [caveStart].
  static const caveRadius = 430.0, caveHalfWidth = caveRadius;
  static const caveNeckHalf = 85.0;
  static double get caveCenterY => bayTop(caveStart) - 560;

  /// Uneven ceiling and floor so the chamber reads as eroded rock: half
  /// height above / below [caveCenterY] at x, grown by [widen].
  static double caveCeilingChord(double x, {double widen = 0}) {
    final dx = x - caveStart, r = caveRadius + widen;
    if (dx.abs() >= r) return 0;
    final wobble = 1 +
        .13 * math.sin(dx / 70 + .7) +
        .07 * math.sin(dx / 31 + 2.1) +
        .1 * math.exp(-math.pow((dx + 200) / 90, 2).toDouble());
    return math.sqrt(r * r - dx * dx) * wobble;
  }

  static double caveFloorChord(double x, {double widen = 0}) {
    final dx = x - caveStart, r = caveRadius + widen;
    if (dx.abs() >= r) return 0;
    final wobble = .82 +
        .1 * math.sin(dx / 55 + 1.3) +
        .06 * math.sin(dx / 23 + .4) +
        .08 * math.exp(-math.pow((dx - 230) / 80, 2).toDouble());
    return math.sqrt(r * r - dx * dx) * wobble;
  }

  static double caveDepth(double x) {
    final chord = caveCeilingChord(x);
    return chord <= 0 ? 0 : bayTop(x) - (caveCenterY - chord);
  }

  static double caveBlend(double x, {double? y}) => y == null
      ? 0
      : _blend(bayTop(x) - y, 15, 100) * _blend(caveDepth(x), 20, 100);

  static bool inCave(Offset p) => caveBlend(p.dx, y: p.dy) > .1;

  static const caveGapX = caveStart;

  /// Land between the chamber floor and the bay, except the neck.
  static bool inCaveLip(Offset p, {double margin = 0}) {
    final chord = caveFloorChord(p.dx);
    if (chord <= 0) return false;
    if ((p.dx - caveStart).abs() < caveNeckHalf - margin) return false;
    return p.dy >= caveCenterY + chord - margin &&
        p.dy <= bayTop(p.dx) + margin;
  }

  /// Nearest water point outside that land (bay, chamber or neck).
  static Offset _outOfLip(Offset p) {
    const m = boatMargin + .5;
    final x = p.dx, chord = caveFloorChord(x);
    final options = <Offset>[
      constrainBanks(Offset(x, bayTop(x) + m)),
      if (chord > m) Offset(x, caveCenterY + chord - m),
      if ((x - caveStart).abs() < caveNeckHalf + m)
        Offset(caveStart + (x < caveStart ? -1 : 1) * (caveNeckHalf - m), p.dy),
    ]..removeWhere((o) => inCaveLip(o, margin: boatMargin - .01));
    options.sort((a, b) => (a - p).distance.compareTo((b - p).distance));
    return options.isEmpty ? p : options.first;
  }

  static double coastBlend(double x) {
    final t = ((x - (seaStart - 240)) / 720).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static const boatMargin = 30.0;
  static const startDockX = 230.0;
  static Offset get startBoat => Offset(startDockX, bottom(startDockX) - 42);

  /// Area the point belongs to, including the cave inlet.
  static FishingRegion regionAt(double x, {double? y}) =>
      caveBlend(x, y: y) > .1 ? FishingRegion.cave : FishingRegion.alongX(x);

  /// Fish pools layered from upstream to the cave; each later pool blends
  /// over everything before it by its own border weight.
  static List<(Map<FishSpecies, double>, double)> fishLayers(double x,
          {double? y}) =>
      [
        (FishingRegion.village.fish, 1),
        (FishingRegion.bamboo.fish, ((x - 1560) / 480).clamp(0.0, 1.0)),
        (
          FishingRegion.coast.fish,
          ((x - (seaStart - 240)) / 480).clamp(0.0, 1.0)
        ),
        (FishingRegion.mangrove.fish, mangroveBlend(x)),
        (FishingRegion.rockyBay.fish, rockyBlend(x)),
        (FishingRegion.cave.fish, caveBlend(x, y: y)),
        (
          FishingRegion.openSea.fish,
          ((x - (openSeaStart - 240)) / 480).clamp(0.0, 1.0)
        ),
      ];

  static double _poolWeight(
      FishSpecies fish, List<(Map<FishSpecies, double>, double)> layers) {
    var weight = 0.0;
    for (final (pool, blend) in layers) {
      weight = weight * (1 - blend) + (pool[fish] ?? 0) * blend;
    }
    return weight;
  }

  /// Regional pools cross-fade around each join; weights are relative.
  static FishSpecies rollFish(int roll, double x, double hour,
      {bool activeWater = false,
      double? y,
      double Function(FishSpecies)? weatherBoost,
      bool legendaryBait = false,
      double legendaryBoost = 1,
      bool nightLure = false}) {
    final weights = catchWeights(x, hour,
        nightLure: nightLure,
        activeWater: activeWater,
        y: y,
        weatherBoost: weatherBoost,
        legendaryBait: legendaryBait,
        legendaryBoost: legendaryBoost);
    final total = weights.values.fold(0.0, (sum, weight) => sum + weight);
    var ticket = (roll % 10000) / 10000 * total;
    for (final entry in weights.entries) {
      ticket -= entry.value;
      if (ticket < 0) return entry.key;
    }
    return FishSpecies.tinCan;
  }

  /// Relative catch weight of every species at a spot.
  ///
  /// - Legendary fish bite only in their home area (no leaking over borders).
  /// - Night doubles night fish (x3 with the lantern rod, [nightLure]);
  ///   lanternfish and moonfish bite only at night.
  /// - Active water favours the rarer tiers and scares off junk.
  /// - Legendary bait is x6; [legendaryBoost] is the bad-luck protection.
  static Map<FishSpecies, double> catchWeights(double x, double hour,
      {bool activeWater = false,
      double? y,
      double Function(FishSpecies)? weatherBoost,
      bool legendaryBait = false,
      double legendaryBoost = 1,
      bool nightLure = false}) {
    final night = hour < 6 || hour >= 18;
    final layers = fishLayers(x, y: y);
    final home = regionAt(x, y: y).fish;
    return {
      for (final fish in FishSpecies.values)
        fish: _poolWeight(fish, layers) *
            (weatherBoost?.call(fish) ?? 1) *
            (fish.isLegendary
                ? (home.containsKey(fish) ? 1 : 0) *
                    (legendaryBait ? 6 : 1) *
                    legendaryBoost
                : 1) *
            (fish.nightOnly && !night
                ? 0
                : night && fish.nightActive
                    ? (nightLure ? 3 : 2)
                    : 1) *
            (activeWater ? fish.activeWaterBoost : 1),
    };
  }

  /// True when a legendary fish can bite at this spot right now.
  static bool legendaryHere(double x, double hour, {double? y}) =>
      FishSpecies.legendary
          .any((f) => (catchWeights(x, hour, y: y)[f] ?? 0) > 0);

  // Smooth bank inlets stay part of the same navigable channel and route rules.
  static const coves = [
    (x: 950.0, radius: 300.0, depth: 330.0, north: true),
    (x: 2650.0, radius: 340.0, depth: 310.0, north: false),
    (x: 6350.0, radius: 380.0, depth: 60.0, north: true),
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

  static double _mainCenter(double x) {
    final river =
        1100 + 150 * math.sin(x / 620 - .4) + 65 * math.sin(x / 290 + .5);
    final sea = 1750 + math.sin(x / 1000) * 70;
    final base = river + (sea - river) * coastBlend(x);
    final creek = 1400 +
        185 * math.sin((x - mangroveStart) / 360) +
        60 * math.sin((x - mangroveStart) / 155);
    final forest = base + (creek - base) * mangroveBlend(x);
    final bay = 1750 + 110 * math.sin((x - rockyBayStart) / 390);
    return forest + (bay - forest) * rockyBlend(x);
  }

  static double _mainWidth(double x) {
    final river = 410 + 85 * math.sin(x / 500 + .4) + 45 * math.cos(x / 260);
    final sea = 1350 + math.sin(x / 850) * 65;
    final base = river + (sea - river) * coastBlend(x);
    final creek = 220 + 35 * math.sin(x / 240) + 18 * math.cos(x / 110);
    final forest = base + (creek - base) * mangroveBlend(x);
    final bay = 520 + 60 * math.sin(x / 280);
    return forest + (bay - forest) * rockyBlend(x);
  }

  static double bayTop(double x) => _mainCenter(x) - _mainWidth(x);
  static double top(double x) => bayTop(x) - _inlet(x, true) - caveDepth(x);
  static double bottom(double x) =>
      _mainCenter(x) + _mainWidth(x) + _inlet(x, false);
  static double center(double x) => (top(x) + bottom(x)) / 2;

  /// Middle of the open channel, ignoring the Sea Cave chamber.
  static double bayCenter(double x) =>
      (bayTop(x) - _inlet(x, true) + bottom(x)) / 2;
  static double halfWidth(double x) => (bottom(x) - top(x)) / 2;
  static bool contains(Offset p) =>
      p.dx >= 0 &&
      p.dx <= length &&
      p.dy >= top(p.dx) &&
      p.dy <= bottom(p.dx) &&
      !inCaveLip(p) &&
      !fishingSeaIsland.contains(p) &&
      (p - FishingCabin.ship).distance > FishingCabin.radius &&
      (p - FishingMarket.center).distance > FishingMarket.radius &&
      (p - FishingShrine.center).distance > FishingShrine.radius &&
      (p - FishingBaitHouse.center).distance > FishingBaitHouse.radius;

  static Offset constrain(Offset p) {
    var safe = constrainBanks(p);
    if (inCaveLip(safe, margin: boatMargin)) safe = _outOfLip(safe);
    final delta = safe - fishingSeaIsland.center;
    final clearance = fishingSeaIsland.radiusTowards(safe) + boatMargin;
    if (delta.distance < clearance) {
      final direction =
          delta.distance > .001 ? delta / delta.distance : const Offset(0, 1);
      safe = fishingSeaIsland.center + direction * clearance;
    }
    // Moored structures: the pirate ship and the floating market.
    for (final (at, reach) in [
      (FishingCabin.ship, FishingCabin.radius),
      (FishingMarket.center, FishingMarket.radius),
      (FishingShrine.center, FishingShrine.radius),
      (FishingBaitHouse.center, FishingBaitHouse.radius),
    ]) {
      final d = safe - at;
      if (d.distance < reach + boatMargin) {
        safe = at +
            (d.distance > .001 ? d / d.distance : const Offset(0, 1)) *
                (reach + boatMargin);
      }
    }
    return safe;
  }

  static Offset constrainBanks(Offset p) {
    final x = p.dx.clamp(55.0, length - 55);
    return Offset(x, p.dy.clamp(top(x) + boatMargin, bottom(x) - boatMargin));
  }

  static String sectionName(double x, {double? y}) => regionAt(x, y: y).label;
}

/// Click-to-row movement and a smoothly following two-axis camera.
class FishingRiverRound {
  final props = RiverProps();
  final island = FishingIslandVisit();
  final cabin = FishingCabin();
  final cave = FishingCave();
  Offset get cameraFocus => island.ashore ? island.cat : boat;
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
  bool _caveFight = false;
  Offset _fightAnchor = Offset.zero;
  final _route = <Offset>[];

  /// Minimap fog, revealed around [cameraFocus] every update.
  final exploration = FishingExploration();

  /// Applies a saved trip; invalid parts keep their defaults.
  void restore({Offset? boat, double? heading, List<bool>? explored}) {
    if (boat != null && boat.isFinite) {
      this.boat = _lastBoat = props.resolve(FishingRiver.constrain(boat));
    }
    if (heading != null && heading.isFinite) {
      this.heading = Offset.fromDirection(heading);
    }
    if (explored != null) exploration.load(explored);
    exploration
      ..reveal(cameraFocus)
      ..changed = false;
    if (viewport != Size.zero) {
      cameraLeft = (cameraFocus.dx - visibleWidth * .42).clamp(0.0, maxCamera);
      cameraTop =
          (cameraFocus.dy - visibleHeight * .5).clamp(0.0, maxCameraTop);
    }
  }

  bool get moving => destination != null;
  bool get rowing => moving || chasing;

  /// Camera zoom: 1 normally, eases out to [lookoutZoom] on the lighthouse.
  double zoom = 1;

  /// In-game hour (0..24) driving day/night (40-minute day); set by the screen.
  double hour = 12;

  /// World point of the lantern rod's lantern while fishing, for its night
  /// glow; null when the lantern rod is not out.
  Offset? rodLantern;

  /// Which way the cat faces (toward the float while fishing); boats with a
  /// head turn with it. Null falls back to the rowing heading.
  bool? catFacingRight;

  /// Boat drawn under the cat; picked at the village boathouse. Changing it
  /// refits [crew] to the new boat's seats.
  FishingBoat get boatStyle => _boatStyle;
  FishingBoat _boatStyle = FishingBoat.basket;
  set boatStyle(FishingBoat boat) {
    _boatStyle = boat;
    crew.refit(boat);
  }

  /// Who rides the boat; only the driver (seat 0) rows and steers.
  final crew = FishingCrew();
  bool get localDrives => crew.canSteer(FishingCrew.localId);

  /// Current weather from the real clock; set by the screen.
  FishingWeather weather = FishingWeather.clear;
  static const lookoutZoom = .25;
  double get scale =>
      (viewport.height > 0 ? viewport.height / FishingRiver.viewHeight : 1) *
      zoom;
  double get visibleWidth => viewport.width / scale;
  double get visibleHeight => viewport.height / scale;
  double get maxCameraTop => math.max(0, FishingRiver.height - visibleHeight);
  double get maxCamera => math.max(0, FishingRiver.length - visibleWidth);

  void resize(Size size) {
    if (viewport == size) return;
    viewport = size;
    cameraLeft = (cameraFocus.dx - visibleWidth * .42).clamp(0.0, maxCamera);
    cameraTop = (cameraFocus.dy - visibleHeight * .5).clamp(0.0, maxCameraTop);
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
    island.dockRequested = false;
    cabin.pending = false;
    destination = null;
    speed = 0;
  }

  void beginFight(Offset fish) {
    stop();
    chasing = true;
    steering = Offset.zero;
    hitTime = 0;
    _chaseDirection = fish.dx < boat.dx ? -1 : 1;
    _caveFight = FishingRiver.inCave(boat);
    _fightAnchor = boat;
  }

  void steer(Offset delta) {
    if (!localDrives) return;
    steering = Offset((steering.dx + delta.dx).clamp(-1.0, 1.0),
        (steering.dy + delta.dy).clamp(-1.0, 1.0));
  }

  bool chase(double dt, FishSpecies fish, double elapsed, double surge,
      {required bool pulling, required bool beginner, double weightPull = 1}) {
    final weave = switch (fish) {
      FishSpecies.perch => math.sin(elapsed * 3) * .9,
      FishSpecies.sardine => math.sin(elapsed * 2.5) * .55,
      FishSpecies.mackerel ||
      FishSpecies.seaDragon =>
        math.sin(elapsed * .8) * .45,
      FishSpecies.clownfish => math.sin(elapsed * 2.2) * 1.05,
      FishSpecies.pufferfish => math.sin(elapsed * .7) * .3,
      FishSpecies.carp => math.sin(elapsed * .5) * .25,
      FishSpecies.catfish => math.sin(elapsed * 1.3) * .6,
      FishSpecies.koi ||
      FishSpecies.lanternfish ||
      FishSpecies.moonfish =>
        FishingFight.at(fish, elapsed).lateral,
      FishSpecies.goby => math.sin(elapsed * 3) * .55,
      FishSpecies.mudskipper => math.sin(elapsed * 3.5) * 1.1,
      FishSpecies.grouper => math.sin(elapsed * .6) * .3,
      FishSpecies.butterflyfish => math.sin(elapsed * 2.3),
      FishSpecies.cavefish => math.sin(elapsed * 1.1) * .5,
      FishSpecies.goldfish => math.sin(elapsed * 2) * .75,
      FishSpecies.catMew => math.sin(elapsed * 2.4) * .8,
      _ => math.sin(elapsed) * .4,
    };
    final move = FishingFight.at(fish, elapsed).move;
    final reverse = fish == FishSpecies.catMew && move == FishFightMove.dash;
    final forward = _chaseDirection * (reverse ? -1 : 1);
    final slope = (FishingRiver.bayCenter(boat.dx + 5) -
            FishingRiver.bayCenter(boat.dx - 5)) /
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
    var velocity = Offset(
        forward * pullSpeed + steering.dx * 160,
        slope * forward * pullSpeed +
            weave * (beginner ? 25 : 42) +
            steering.dy * 140);
    if (_caveFight) {
      // Cave fish circle the casting area instead of following the main bay
      // slope, which points straight out of this narrow north-side inlet.
      final orbit = _fightAnchor +
          Offset(math.sin(elapsed * .7) * 100, math.sin(elapsed * .5) * 60);
      final target = FishingRiver.inCave(orbit) ? orbit : _fightAnchor;
      var tug = (target - boat) * .9;
      if (tug.distance > pullSpeed) tug = tug / tug.distance * pullSpeed;
      final auto = props.slide(boat, tug * dt * props.dragAt(boat));
      final safeAuto = FishingRiver.inCave(auto) ? auto : boat;
      velocity = (safeAuto - boat) / math.max(dt, .001) +
          Offset(steering.dx * 160, steering.dy * 140);
    }
    heading = velocity / math.max(.001, velocity.distance);
    final intended = boat + velocity * dt;
    boat = props.slide(boat, velocity * dt * props.dragAt(boat));
    if (_caveFight && !FishingRiver.inCave(boat)) _caveFight = false;
    steering *= math.max(0, 1 - dt * 2.8);
    if ((FishingRiver.constrainBanks(intended) - intended).distance > .1 &&
        hitTime <= 0) {
      hitTime = 1.4;
      return true;
    }
    return false;
  }

  bool _castLineClear(Offset from, Offset to, bool caveOnly) {
    if (!props.clearLine(from, to)) return false;
    if (!caveOnly) return true;
    final steps = math.max(1, ((to - from).distance / 16).ceil());
    for (var i = 1; i <= steps; i++) {
      if (!FishingRiver.inCave(Offset.lerp(from, to, i / steps)!)) return false;
    }
    return true;
  }

  /// Stop the line at the first obstruction, never project it through a wall.
  Offset clipCast(Offset from, Offset to, {bool caveOnly = false}) {
    if (_castLineClear(from, to, caveOnly)) return to;
    var lo = 0.0, hi = 1.0;
    for (var i = 0; i < 9; i++) {
      final mid = (lo + hi) / 2;
      if (_castLineClear(from, Offset.lerp(from, to, mid)!, caveOnly)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return Offset.lerp(from, to, lo)!;
  }

  /// Prefer the facing direction, then try other angles in the same cave.
  /// The longest clear ray wins, so narrow water naturally shortens the cast.
  Offset castPoint(Offset from, double facing) {
    final caveOnly = FishingRiver.inCave(from);
    var best = from, distance = 0.0;
    for (var i = 0; i < 16; i++) {
      final angle = -math.atan2(25, 280) +
          (i == 0 ? 0 : (i.isOdd ? 1 : -1) * ((i + 1) ~/ 2) * math.pi / 8);
      final ray = Offset(math.cos(angle) * facing, math.sin(angle));
      final point = clipCast(from, from + ray * 280, caveOnly: caveOnly);
      final reach = (point - from).distance;
      if (reach > distance) {
        best = point;
        distance = reach;
      }
      if (reach >= 279.9) break;
    }
    return best;
  }

  void sailTo(Offset world) {
    if (!localDrives) return;
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
    // Shortest first: open water goes straight to the target.
    if (props.clearLine(start, target)) {
      _route.add(target);
      return;
    }
    // Otherwise follow the channel's bends (a straight line would cut a
    // bank), then pull the path tight so it only bends where it must.
    // Lanes follow the bay itself (cave inlet excluded); trips into or out
    // of the cave fall back to the A* detour through the mouth gap.
    double laneCenter(double x) =>
        (FishingRiver.bayTop(x) -
            FishingRiver._inlet(x, true) +
            FishingRiver.bottom(x)) /
        2;
    double laneHalf(double x) =>
        (FishingRiver.bottom(x) -
                FishingRiver.bayTop(x) +
                FishingRiver._inlet(x, true)) /
            2 -
        FishingRiver.boatMargin;
    final startLane = (start.dy - laneCenter(start.dx)) / laneHalf(start.dx);
    final endLane = (target.dy - laneCenter(target.dx)) / laneHalf(target.dx);
    final steps = math.max(1, ((target.dx - start.dx).abs() / 24).ceil());
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final x = start.dx + (target.dx - start.dx) * t;
      final lane = startLane + (endLane - startLane) * t;
      _route.add(FishingRiver.constrain(
          Offset(x, laneCenter(x) + lane * laneHalf(x))));
    }
    _avoidRocks();
    if (_route.isNotEmpty) {
      final tight = pullTight(start, _route, props.clearLine);
      _route
        ..clear()
        ..addAll(tight);
    }
  }

  /// Shortcuts a polyline: from each point jump to the farthest later point
  /// that [clear] still connects in a straight line.
  static List<Offset> pullTight(Offset start, List<Offset> route,
      bool Function(Offset a, Offset b) clear) {
    final result = <Offset>[];
    var anchor = start;
    var i = 0;
    while (i < route.length) {
      var best = i;
      for (var j = route.length - 1; j > i; j--) {
        if (clear(anchor, route[j])) {
          best = j;
          break;
        }
      }
      anchor = route[best];
      result.add(anchor);
      i = best + 1;
    }
    return result;
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
    if (island.dockRequested &&
        !moving &&
        (boat - island.visitMooring).distance < 2) {
      island.beginLanding();
    }
    island.update(dt);
    if (island.caveArrived) {
      island.caveArrived = false;
      cave.enter();
    }
    final wantedZoom = island.lookout ? lookoutZoom : 1.0;
    zoom += (wantedZoom - zoom) * (1 - math.exp(-2.6 * dt));
    if ((zoom - wantedZoom).abs() < .001) zoom = wantedZoom;
    exploration.reveal(cameraFocus, reach: island.lookout ? 11 : 3);
    props.update(
        dt, clock, boat, dt > 0 ? (boat - _lastBoat) / dt : Offset.zero);
    _lastBoat = boat;
    wake += ((rowing ? 1 : 0) - wake) * (1 - math.exp(-4 * dt));
    final ahead = island.lookout ? .5 : .42;
    final targetCamera =
        (cameraFocus.dx - visibleWidth * ahead).clamp(0.0, maxCamera);
    cameraLeft += (targetCamera - cameraLeft) * (1 - math.exp(-5 * dt));
    cameraLeft = cameraLeft.clamp(0.0, maxCamera);
    final targetTop =
        (cameraFocus.dy - visibleHeight * .5).clamp(0.0, maxCameraTop);
    cameraTop += (targetTop - cameraTop) * (1 - math.exp(-5 * dt));
    cameraTop = cameraTop.clamp(0.0, maxCameraTop);
  }
}
